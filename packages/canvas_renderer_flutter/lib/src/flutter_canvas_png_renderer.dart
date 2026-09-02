// Path: lib/src/flutter_canvas_png_renderer.dart

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';

import 'package:canvas_renderer_flutter/src/canvas_png_renderer.dart';
import 'package:canvas_renderer_flutter/src/flutter_canvas_renderer.dart';
import 'package:canvas_renderer_flutter/src/flutter_text_pipeline.dart';
import 'package:canvas_renderer_flutter/src/fonts/flutter_font_loader.dart';
import 'package:canvas_renderer_flutter/src/images/flutter_image_pool.dart';

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
      final renderPipeline = CanvasRenderPipeline(
        textMeasurer: textPipeline,
        images: imagePool,
        icons: _icons,
      );

      // Canonical metadata is required before preparation because preparation
      // may synchronously inspect image geometry through CoreServices.
      await imagePool.resolveSceneIntrinsics(scene, includeHidden: true);

      _ensureRequiredIntrinsics(scene, imagePool, stage: 'canonical');

      // Final output owns preparation. A supplied preparer is invoked exactly
      // once and failures propagate to the caller.
      final prepared =
          _scenePreparer?.call(scene, renderPipeline.services) ?? scene;

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
      await imagePool.resolveSceneIntrinsics(prepared, includeHidden: true);

      _ensureRequiredIntrinsics(prepared, imagePool, stage: 'prepared');

      // Raster decoding is required only for nodes that can actually paint in
      // the final prepared scene.
      await imagePool.preloadScene(
        prepared,
        targetW: spec.widthPx,
        targetH: spec.heightPx,
        includeHidden: false,
      );

      _ensureVisibleImagesDecoded(prepared, imagePool);

      final built = renderPipeline.build(
        prepared,
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
}) {
  final missing = <ElementId>[];

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
      }
    },
  );

  if (missing.isEmpty) {
    return;
  }

  throw StateError(
    'The $stage scene has image nodes without usable intrinsic metadata: '
    '${missing.join(', ')}',
  );
}

void _ensureVisibleImagesDecoded(
  CanvasSceneDocument scene,
  FlutterImagePool imagePool,
) {
  final missing = <ElementId>[];

  visitSceneNodes(
    scene,
    includeHidden: false,
    visit: (node) {
      if (node is! ImageNode || node.data.assetId == null) {
        return;
      }

      if (imagePool.images[node.id] == null) {
        missing.add(node.id);
      }
    },
  );

  if (missing.isEmpty) {
    return;
  }

  throw StateError(
    'Final PNG rendering could not decode required image nodes: '
    '${missing.join(', ')}',
  );
}

Future<Uint8List> _encodePng({
  required RenderSnapshot built,
  required CanvasPngSpec spec,
  required FlutterImagePool imagePool,
  required FlutterTextPipeline textPipeline,
}) async {
  final artboard = built.scene.artboardSize;

  final viewport = CanvasViewportPlanner.plan(
    artboard: artboard,
    targetW: spec.widthPx.toDouble(),
    targetH: spec.heightPx.toDouble(),
    bounds: built.contentBounds,
    bleedPx: spec.bleedPx.toDouble(),
    fit: spec.fit,
    tight: spec.cropToContent && spec.tight,
    snappingEnabled: false,
    pixelRatioForSnapping: spec.pixelRatio,
  );

  final pixelRatio = spec.pixelRatio.clamp(1.0, 4.0).toDouble();

  final recorder = ui.PictureRecorder();

  final canvas = ui.Canvas(
    recorder,
    ui.Rect.fromLTWH(
      0,
      0,
      viewport.recordingW * pixelRatio,
      viewport.recordingH * pixelRatio,
    ),
  );

  canvas.scale(pixelRatio, pixelRatio);

  // Preserve the previous exporter behavior: transparent output has no backing
  // fill; opaque output receives a white backing surface before scene paint
  // operations are replayed.
  if (!spec.transparent) {
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, viewport.recordingW, viewport.recordingH),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
  }

  canvas.save();

  canvas.translate(viewport.translateX, viewport.translateY);

  canvas.scale(viewport.scaleX, viewport.scaleY);

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
  ).replay(canvas, built.ops);

  canvas.restore();

  final picture = recorder.endRecording();

  final ui.Image image;

  try {
    image = await picture.toImage(
      (viewport.recordingW * pixelRatio).round(),
      (viewport.recordingH * pixelRatio).round(),
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
