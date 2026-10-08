// Path: lib/src/flutter_canvas_png_renderer.dart

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';

import 'package:canvas_renderer_flutter/src/canvas_png_renderer.dart';
import 'package:canvas_renderer_flutter/src/flutter_canvas_renderer.dart';
import 'package:canvas_renderer_flutter/src/flutter_text_pipeline.dart';
import 'package:canvas_renderer_flutter/src/fonts/flutter_font_loader.dart';
import 'package:canvas_renderer_flutter/src/images/flutter_image_pool.dart';

/// Strict PNG failure for required image resources.
///
/// Only failures relevant to [nodeIds] are retained. Original causes and
/// logical references remain available in [failures] but are not formatted
/// into the error message because they can contain credentials or inline data.
final class CanvasImageRenderException extends StateError {
  CanvasImageRenderException(
    String message, {
    required Iterable<ElementId> nodeIds,
    required Iterable<FlutterImageLoadFailure> failures,
  }) : nodeIds = List<ElementId>.unmodifiable(nodeIds),
       failures = List<FlutterImageLoadFailure>.unmodifiable(failures),
       super(
         '$message'
         '${failures.isEmpty ? '' : '\n${failures.join('\n')}'}',
       );

  final List<ElementId> nodeIds;
  final List<FlutterImageLoadFailure> failures;
}

/// Canonical Flutter implementation of [CanvasPngRenderer].
///
/// One render operation owns one [FlutterTextPipeline] and one
/// [FlutterImagePool]. Those operation-scoped resources are always disposed
/// before the render future completes.
///
/// [fonts] is reusable host state because Flutter font registration is
/// process-scoped rather than render-operation-scoped.
final class FlutterCanvasPngRenderer implements CanvasPngRenderer {
  FlutterCanvasPngRenderer({
    required FlutterFontLoader fonts,
    IconResolver? icons,
    CanvasImageAssetResolver? images,
    ScenePreparer? scenePreparer,
  }) : _fonts = fonts,
       _icons = icons,
       _images = images,
       _scenePreparer = scenePreparer;

  final FlutterFontLoader _fonts;
  final IconResolver? _icons;
  final CanvasImageAssetResolver? _images;
  final ScenePreparer? _scenePreparer;

  @override
  Future<Uint8List> renderPng({
    required CanvasSceneDocument scene,
    required CanvasPngSpec spec,
  }) async {
    _validateScene(scene, stage: 'canonical');

    final canonicalIconRefs = _collectIconRefs(scene);

    _ensureIconsResolvable(canonicalIconRefs, _icons, stage: 'canonical');

    final canonicalFontFamilies = collectSceneFontFamilies(
      scene,
      fallbackFontFamilies: _fonts.fallbackFontFamilies,
      icons: _icons,
    );

    final canonicalImageSourceRefs = _collectImageSourceRefs(scene);

    // Fonts must be available before preparation because a ScenePreparer may
    // synchronously measure canonical text through CoreServices.
    await _fonts.ensureLoaded(canonicalFontFamilies);

    final textPipeline = FlutterTextPipeline(
      fallbackFontFamilies: _fonts.fallbackFontFamilies,
    );

    final imagePool = FlutterImagePool(resolver: _images);

    try {
      final services = CoreServices(
        textMeasurer: textPipeline,
        images: imagePool,
        icons: _icons,
      );

      // Canonical metadata is required before preparation because preparation
      // may synchronously inspect image geometry through CoreServices.
      final canonicalFailures = await imagePool.resolveSceneIntrinsics(
        scene,
        includeHidden: true,
      );

      _ensureRequiredIntrinsics(
        scene,
        imagePool,
        stage: 'canonical',
        failures: canonicalFailures,
      );

      // Final output owns preparation. A supplied preparer is invoked exactly
      // once and failures propagate to the caller.
      final prepared = _scenePreparer?.call(scene, services) ?? scene;

      _validateScene(prepared, stage: 'prepared');

      final preparedIconRefs = _collectIconRefs(prepared);

      _ensureIconsResolvable(preparedIconRefs, _icons, stage: 'prepared');

      final preparedFontFamilies = collectSceneFontFamilies(
        prepared,
        fallbackFontFamilies: _fonts.fallbackFontFamilies,
        icons: _icons,
      );

      final preparedImageSourceRefs = _collectImageSourceRefs(prepared);

      // Preparation may remove dependencies or duplicate already-approved
      // logical resources. It must not introduce new external dependencies.
      _ensureResourceSubset(
        prepared: preparedFontFamilies,
        canonical: canonicalFontFamilies,
        resourceLabel: 'font family',
      );

      _ensureResourceSubset(
        prepared: preparedIconRefs,
        canonical: canonicalIconRefs,
        resourceLabel: 'icon reference',
      );

      _ensureResourceSubset(
        prepared: preparedImageSourceRefs,
        canonical: canonicalImageSourceRefs,
        resourceLabel: 'image source reference',
      );

      // This second intrinsic pass is intentional and mandatory. A preparer may
      // create a new ElementId that legally reuses an already-approved logical
      // image sourceRef. Intrinsic metadata must therefore be published for the
      // prepared element IDs after resource conformance has been established.
      final preparedFailures = await imagePool.resolveSceneIntrinsics(
        prepared,
        includeHidden: true,
      );

      _ensureRequiredIntrinsics(
        prepared,
        imagePool,
        stage: 'prepared',
        failures: preparedFailures,
      );

      // Raster decoding is required only for nodes that can actually paint in
      // the final prepared scene.
      //
      // Final output deliberately avoids decode-size hints. targetW/targetH are
      // an interactive/memory optimization that may downsample source rasters
      // before painting. Authoritative PNG rendering keeps the source raster at
      // its native decoded resolution so pixelRatio, crop/cover behavior, and
      // scene transforms cannot magnify an already-downsampled image.
      final rasterFailures = await imagePool.preloadScene(
        prepared,
        includeHidden: false,
      );

      _ensureVisibleImagesDecoded(prepared, imagePool, rasterFailures);

      final built = evaluateScene(
        prepared,
        services,
        contentBounds: spec.cropToContent
            ? ContentBoundsSpec(
                paddingPx: spec.contentPaddingPx,
                policy: spec.contentBoundsPolicy ?? const ContentBoundsPolicy(),
              )
            : null,
      );

      return await _encodePng(
        built: built,
        spec: spec,
        imagePool: imagePool,
        textPipeline: textPipeline,
      );
    } finally {
      imagePool.dispose();
      textPipeline.dispose();
    }
  }
}

void _validateScene(CanvasSceneDocument scene, {required String stage}) {
  final issues = validateCanvasSceneDocument(scene);

  if (issues.isEmpty) {
    return;
  }

  final details = issues
      .map((issue) => '${issue.code.name} at ${issue.path}: ${issue.message}')
      .join('\n');

  throw StateError('Invalid $stage canvas scene:\n$details');
}

Set<String> _collectIconRefs(CanvasSceneDocument scene) {
  final refs = <String>{};

  visitSceneNodes(
    scene,
    includeHidden: true,
    visit: (node) {
      if (node is IconNode) {
        refs.add(node.data.iconRef);
      }
    },
  );

  return Set<String>.unmodifiable(refs);
}

Set<String> _collectImageSourceRefs(CanvasSceneDocument scene) {
  final refs = <String>{};

  visitSceneNodes(
    scene,
    includeHidden: true,
    visit: (node) {
      if (node is! ImageNode) {
        return;
      }

      final assetId = node.data.assetId;

      // Null assetId is an intentionally unfilled image frame.
      if (assetId == null) {
        return;
      }

      final asset = scene.assets[assetId];

      if (asset == null) {
        // Structural validation should already have rejected this. Keep the
        // guard here so this helper remains locally sound.
        throw StateError(
          'Image node "${node.id}" references missing asset "$assetId".',
        );
      }

      refs.add(asset.sourceRef);
    },
  );

  return Set<String>.unmodifiable(refs);
}

void _ensureIconsResolvable(
  Set<String> iconRefs,
  IconResolver? icons, {
  required String stage,
}) {
  if (iconRefs.isEmpty) {
    return;
  }

  if (icons == null) {
    throw StateError(
      'The $stage scene requires icon resolution but no IconResolver '
      'was provided.',
    );
  }

  final ordered = iconRefs.toList()..sort();

  for (final iconRef in ordered) {
    if (iconRef.trim().isEmpty) {
      throw StateError('The $stage scene contains a blank icon reference.');
    }

    final resolved = icons.resolve(iconRef);

    if (resolved == null) {
      throw StateError(
        'The $stage scene contains unresolved icon reference "$iconRef".',
      );
    }

    if (resolved is ResolvedIconText && resolved.fontFamily.trim().isEmpty) {
      throw StateError(
        'Icon reference "$iconRef" resolved to a blank font family.',
      );
    }
  }
}

void _ensureResourceSubset({
  required Set<String> prepared,
  required Set<String> canonical,
  required String resourceLabel,
}) {
  final introduced = prepared.difference(canonical).toList()..sort();

  if (introduced.isEmpty) {
    return;
  }

  throw StateError(
    'Scene preparation introduced unapproved $resourceLabel dependencies: '
    '${introduced.join(', ')}',
  );
}

void _ensureRequiredIntrinsics(
  CanvasSceneDocument scene,
  FlutterImagePool imagePool, {
  required String stage,
  required List<FlutterImageLoadFailure> failures,
}) {
  final missing = <ElementId>[];
  final missingRefs = <String>{};

  visitSceneNodes(
    scene,
    includeHidden: true,
    visit: (node) {
      if (node is! ImageNode || node.data.assetId == null) {
        return;
      }

      final intrinsic = imagePool.intrinsicSize(node.id);

      if (intrinsic == null ||
          !intrinsic.w.isFinite ||
          !intrinsic.h.isFinite ||
          intrinsic.w <= 0 ||
          intrinsic.h <= 0) {
        missing.add(node.id);
        final sourceRef = scene.assets[node.data.assetId]?.sourceRef.trim();
        if (sourceRef != null) missingRefs.add(sourceRef);
      }
    },
  );

  if (missing.isEmpty) {
    return;
  }

  throw CanvasImageRenderException(
    'The $stage scene has image nodes without usable intrinsic metadata: '
    '${missing.join(', ')}',
    nodeIds: missing,
    failures: failures.where(
      (failure) => missingRefs.contains(failure.sourceRef),
    ),
  );
}

void _ensureVisibleImagesDecoded(
  CanvasSceneDocument scene,
  FlutterImagePool imagePool,
  List<FlutterImageLoadFailure> failures,
) {
  final missing = <ElementId>[];
  final missingRefs = <String>{};

  visitSceneNodes(
    scene,
    includeHidden: false,
    visit: (node) {
      if (node is! ImageNode || node.data.assetId == null) {
        return;
      }

      if (imagePool.images[node.id] == null) {
        missing.add(node.id);
        final sourceRef = scene.assets[node.data.assetId]?.sourceRef.trim();
        if (sourceRef != null) missingRefs.add(sourceRef);
      }
    },
  );

  if (missing.isEmpty) {
    return;
  }

  throw CanvasImageRenderException(
    'Final PNG rendering could not decode required image nodes: '
    '${missing.join(', ')}',
    nodeIds: missing,
    failures: failures.where(
      (failure) => missingRefs.contains(failure.sourceRef),
    ),
  );
}

Future<Uint8List> _encodePng({
  required SceneEvaluation built,
  required CanvasPngSpec spec,
  required FlutterImagePool imagePool,
  required FlutterTextPipeline textPipeline,
}) async {
  final artboard = built.scene.artboardSize;

  final requestedW = spec.widthPx.toDouble();
  final requestedH = spec.heightPx.toDouble();

  final contentBounds = built.contentBounds;

  // Content bounds are a usable fit source only when both dimensions are
  // positive. Missing or unusable bounds fall back to the artboard.
  final usableContentBounds =
      contentBounds != null &&
          contentBounds.width > 0 &&
          contentBounds.height > 0
      ? contentBounds
      : null;

  final sourceBounds =
      usableContentBounds ?? Rect2D.fromLTWH(0, 0, artboard.w, artboard.h);

  var outputW = requestedW;
  var outputH = requestedH;

  // Tight output sizing is renderer policy. Keep logical dimensions as doubles
  // until the final raster dimensions are calculated below.
  if (spec.cropToContent && spec.tight && usableContentBounds != null) {
    final tightScale = math.min(
      requestedW / usableContentBounds.width,
      requestedH / usableContentBounds.height,
    );

    outputW = usableContentBounds.width * tightScale;
    outputH = usableContentBounds.height * tightScale;
  }

  final viewport = computeViewport(
    sourceBounds: sourceBounds,
    targetW: outputW,
    targetH: outputH,
  );

  final pixelRatio = spec.pixelRatio.clamp(1.0, 4.0).toDouble();

  final recorder = ui.PictureRecorder();

  final canvas = ui.Canvas(
    recorder,
    ui.Rect.fromLTWH(0, 0, outputW * pixelRatio, outputH * pixelRatio),
  );

  canvas.scale(pixelRatio);

  // Preserve the previous exporter behavior: transparent output has no backing
  // fill; opaque output receives a white backing surface before scene paint
  // scene is painted.
  if (!spec.transparent) {
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, outputW, outputH),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
  }

  canvas.save();

  canvas.translate(viewport.translateX, viewport.translateY);
  canvas.scale(viewport.scale);

  CanvasRenderer(
    images: imagePool.images,
    text: textPipeline,
    intrinsics: imagePool,

    // Required final resources have already been verified. `skip` is only a
    // defensive low-level policy and is intentionally not exposed through
    // CanvasPngSpec.
    options: const CanvasRendererOptions(
      missingImageBehavior: MissingImageBehavior.skip,
    ),
  ).paintScene(canvas, built);

  canvas.restore();

  final picture = recorder.endRecording();

  final ui.Image image;

  try {
    image = await picture.toImage(
      (outputW * pixelRatio).round(),
      (outputH * pixelRatio).round(),
    );
  } finally {
    picture.dispose();
  }

  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);

    if (data == null) {
      throw StateError('PNG encoding failed.');
    }

    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } finally {
    image.dispose();
  }
}
