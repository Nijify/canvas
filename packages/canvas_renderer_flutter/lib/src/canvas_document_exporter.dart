// Path: lib/src/canvas_document_exporter.dart

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';

import 'package:canvas_renderer_flutter/src/flutter_canvas_renderer.dart';
import 'package:canvas_renderer_flutter/src/flutter_text_pipeline.dart';

/// Export configuration for [CanvasDocumentExporter].
class CanvasExportSpec {
  const CanvasExportSpec({
    required this.widthPx,
    required this.heightPx,
    this.bleedPx = 0,
    this.pixelRatio = 2.0,
    this.transparent = true,
    this.fit = CanvasFit.contain,

    // Crop-to-content mode
    this.cropToContent = false,
    this.contentPaddingPx = 0,
    this.tight = false,

    // Custom generic content-bounds policy.
    //
    // This keeps the exporter generic and delegates content-selection rules to
    // host applications.
    this.contentBoundsPolicy,
    this.rendererOptions = const CanvasRendererOptions(
      missingImageBehavior: MissingImageBehavior.skip,
    ),
  });

  final int widthPx;
  final int heightPx;
  final int bleedPx;
  final double pixelRatio;
  final bool transparent;
  final CanvasFit fit;

  /// If true: compute content bounds from laid scene graph and export using that
  /// viewport instead of the raw artboard.
  final bool cropToContent;

  /// Extra padding around the content bounds (in document units / px).
  final double contentPaddingPx;

  /// If true (and cropToContent=true): output image size becomes tight to bounds
  /// (scaled up to fit within widthPx/heightPx).
  final bool tight;

  /// Custom policy for runtime content-bounds computation.
  final ContentBoundsPolicy? contentBoundsPolicy;

  /// Renderer behavior used for export/raster output.
  ///
  /// Defaults to output-safe behavior: missing images are skipped rather than
  /// drawn as editor placeholders.
  final CanvasRendererOptions rendererOptions;

  ui.Color? get background => transparent ? null : const ui.Color(0xFFFFFFFF);
}

/// Shared PNG export helper for canvas scenes.
///
/// Collects images (paint-only), resolves stable intrinsics (layout), lays out
/// the scene, replays paint ops onto a Canvas, and encodes the result as PNG.
///
/// Design note:
/// - This exporter is intentionally generic.
/// - It does NOT hardcode application-specific component policies.
/// - Host applications should resolve or preprocess scenes before they reach
///   this exporter.

class CanvasDocumentExporter {
  /// Creates an exporter that borrows [textPipeline].
  ///
  /// The caller must keep the pipeline alive until each export future completes
  /// and remains responsible for disposing it.
  CanvasDocumentExporter({
    required FlutterTextPipeline textPipeline,
    this.icons,
  }) : _textPipeline = textPipeline;

  /// Borrowed from the caller and never disposed by this exporter.
  final FlutterTextPipeline _textPipeline;

  final IconResolver? icons;

  /// Exports an already-prepared [document] to a PNG byte array.
  ///
  /// This exporter does not resolve source documents or apply domain-specific
  /// scene preparation. Callers must perform those steps before invoking it.
  ///
  /// Hard rules:
  /// - Layout MUST use stable intrinsic metadata (resolveIntrinsicSize).
  /// - Decoded ui.Image sizes MUST NOT influence layout.
  ///
  /// Image ownership:
  /// - Non-null images returned by `resolveImage` are borrowed.
  /// - The caller retains ownership of those image handles.
  /// - Images must remain valid until this future completes.
  /// - This exporter never disposes resolved input images.
  Future<Uint8List> exportPng({
    required CanvasSceneDocument document,
    required Future<ui.Image?> Function(ElementId id) resolveImage,
    required Future<Size2D?> Function(ElementId id) resolveIntrinsicSize,
    required CanvasExportSpec spec,
  }) async {
    // Paint-only images (decoded) + stable layout intrinsics (metadata).
    final images = await _collectImages(document, resolveImage);
    final intrinsicsMap = await _collectIntrinsicSizes(
      document,
      resolveIntrinsicSize,
    );
    final stableIntrinsics = _StableMapIntrinsics(intrinsicsMap);

    final renderPipeline = CanvasRenderPipeline(
      textMeasurer: _textPipeline,
      images: stableIntrinsics,
      icons: icons,
    );

    final built = renderPipeline.build(
      document,
      contentBounds: spec.cropToContent
          ? ContentBoundsSpec(
              paddingPx: spec.contentPaddingPx,
              policy: spec.contentBoundsPolicy ?? const ContentBoundsPolicy(),
            )
          : null,
    );

    final art = built.scene.artboardSize;
    final contentBounds = built.contentBounds;

    // Shared viewport planning
    // Export default: mathematically exact transforms (no pixel snapping).
    // TODO: a future “sharp as possible” export mode can enable snapping.
    final maxW = spec.widthPx.toDouble();
    final maxH = spec.heightPx.toDouble();

    final vp = CanvasViewportPlanner.plan(
      artboard: art,
      targetW: maxW,
      targetH: maxH,
      bounds: contentBounds,
      bleedPx: spec.bleedPx.toDouble(),
      fit: spec.fit,
      tight: spec.cropToContent && spec.tight,
      snappingEnabled: false,
      pixelRatioForSnapping: spec.pixelRatio, // ignored when snapping disabled
    );

    final pr = spec.pixelRatio.clamp(1.0, 4.0).toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, vp.recordingW * pr, vp.recordingH * pr),
    );

    // Apply pixel ratio at the outer canvas level.
    canvas.scale(pr, pr);

    // Optional background fill.
    final bg = spec.background;
    if (bg != null) {
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, vp.recordingW, vp.recordingH),
        ui.Paint()..color = bg,
      );
    }

    canvas.save();
    canvas.translate(vp.translateX, vp.translateY);
    canvas.scale(vp.scaleX, vp.scaleY);

    CanvasRenderer(
      images: images,
      text: _textPipeline,
      intrinsics: stableIntrinsics,
      options: spec.rendererOptions,
    ).replay(canvas, built.ops);

    final picture = recorder.endRecording();

    final ui.Image image;
    try {
      image = await picture.toImage(
        (vp.recordingW * pr).round(),
        (vp.recordingH * pr).round(),
      );
    } finally {
      picture.dispose();
    }

    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);

      if (data == null) {
        throw StateError('PNG encoding failed');
      }

      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }
}

// ----------------------------------------------------------------------------
// Image + intrinsic collection helpers
// ----------------------------------------------------------------------------

List<ImageNode> _collectImageNodes(CanvasSceneDocument doc) {
  final out = <ImageNode>[];

  visitSceneNodes(
    doc,
    includeHidden: true,
    visit: (node) {
      if (node is ImageNode) out.add(node);
    },
  );

  return out;
}

Future<Map<ElementId, ui.Image?>> _collectImages(
  CanvasSceneDocument doc,
  Future<ui.Image?> Function(ElementId id) resolveImage,
) async {
  final imageIds = {for (final node in _collectImageNodes(doc)) node.id};

  final images = <ElementId, ui.Image?>{};
  final futures = <Future<void>>[];

  for (final id in imageIds) {
    futures.add(resolveImage(id).then((img) => images[id] = img));
  }

  if (futures.isNotEmpty) await Future.wait(futures);
  return images;
}

Future<Map<ElementId, Size2D?>> _collectIntrinsicSizes(
  CanvasSceneDocument doc,
  Future<Size2D?> Function(ElementId id) resolveIntrinsic,
) async {
  final imageIds = {for (final node in _collectImageNodes(doc)) node.id};

  final out = <ElementId, Size2D?>{};
  final futures = <Future<void>>[];

  for (final id in imageIds) {
    futures.add(resolveIntrinsic(id).then((s) => out[id] = s));
  }

  if (futures.isNotEmpty) await Future.wait(futures);
  return out;
}

class _StableMapIntrinsics implements ImageIntrinsics {
  _StableMapIntrinsics(this._sizes);

  final Map<ElementId, Size2D?> _sizes;

  @override
  Size2D? intrinsicSize(ElementId id) => _sizes[id];

  @override
  Stream<ElementId> get onIntrinsicUpdated => _emptyStream;
}

// A single reusable empty broadcast stream.
final Stream<ElementId> _emptyStream = Stream<ElementId>.empty()
    .asBroadcastStream();
