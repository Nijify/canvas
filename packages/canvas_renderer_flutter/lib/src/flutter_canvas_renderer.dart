// Path: lib/src/flutter_canvas_renderer.dart

import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_renderer_flutter/src/flutter_linear_shader.dart';
import 'package:canvas_renderer_flutter/src/flutter_mappers.dart';
import 'package:canvas_renderer_flutter/src/flutter_text_pipeline.dart';
import 'package:canvas_renderer_flutter/src/flutter_source_underlay_renderer.dart';

enum MissingImageBehavior { placeholder, skip }

class CanvasRendererOptions {
  const CanvasRendererOptions({
    this.imageFilterQuality = ui.FilterQuality.none,
    this.missingImageBehavior = MissingImageBehavior.placeholder,
  });

  final ui.FilterQuality imageFilterQuality;
  final MissingImageBehavior missingImageBehavior;
}

class CanvasRenderer {
  final Map<ElementId, ui.Image?> images;

  /// Borrowed from the caller and never disposed by this renderer.
  final FlutterTextPipeline text;

  /// Stable intrinsic metadata provider.
  final ImageIntrinsics? intrinsics;

  final CanvasRendererOptions options;

  CanvasRenderer({
    Map<ElementId, ui.Image?>? images,
    required this.text,
    this.intrinsics,
    this.options = const CanvasRendererOptions(),
  }) : images = images ?? <ElementId, ui.Image?>{};

  ui.Rect _mapSrcToDecoded({
    required ElementId id,
    required ui.Image img,
    required Rect2D srcIntrinsic,
  }) {
    final meta = intrinsics?.intrinsicSize(id);

    // If we don't know intrinsic meta, fall back to using src as-is.
    // (This may be imperfect for resized decodes, but keeps compatibility.)
    if (meta == null || meta.w <= 0 || meta.h <= 0) {
      return srcIntrinsic.toUi;
    }

    final iw = meta.w;
    final ih = meta.h;

    final dw = img.width.toDouble();
    final dh = img.height.toDouble();

    // Guard: if decoded looks invalid, fall back.
    if (dw <= 0 || dh <= 0) return srcIntrinsic.toUi;

    final sx = dw / iw;
    final sy = dh / ih;

    final s = srcIntrinsic.toUi;

    // Scale intrinsic-space rect into decoded pixel-space rect.
    var left = s.left * sx;
    var top = s.top * sy;
    var right = s.right * sx;
    var bottom = s.bottom * sy;

    // Clamp to decoded bounds to avoid backend-specific behavior when out of range.
    if (left.isNaN || top.isNaN || right.isNaN || bottom.isNaN) {
      return srcIntrinsic.toUi;
    }

    left = left.clamp(0.0, dw);
    top = top.clamp(0.0, dh);
    right = right.clamp(0.0, dw);
    bottom = bottom.clamp(0.0, dh);

    // Ensure non-negative extents (defensive).
    if (right < left) right = left;
    if (bottom < top) bottom = top;

    return ui.Rect.fromLTRB(left, top, right, bottom);
  }

  /// Paint the evaluated scene in computed paint order.
  void paintScene(ui.Canvas canvas, SceneEvaluation evaluation) {
    final scene = evaluation.scene;
    final computed = evaluation.computed;
    final artboard = ui.Size(scene.artboardSize.w, scene.artboardSize.h);
    final background = ui.Rect.fromLTWH(0, 0, artboard.width, artboard.height);

    if (scene.backgroundOpacity > 0) {
      switch (scene.backgroundFill) {
        case CanvasFillNone():
          break;
        case CanvasFillSolid(:final color):
          final alpha = (color >> 24) & 0xFF;
          final merged = (alpha * scene.backgroundOpacity)
              .clamp(0, 255)
              .round();
          canvas.drawRect(
            background,
            ui.Paint()..color = ui.Color((merged << 24) | (color & 0x00FFFFFF)),
          );
        case CanvasFillGradient(:final grad):
          canvas.drawRect(
            background,
            ui.Paint()
              ..shader = buildLinearShaderFlutter(
                grad,
                opacity: scene.backgroundOpacity,
              ),
          );
      }
    }

    for (final item in computed.drawList) {
      final id = item.leafId;
      final node = computed.nodeById[id];
      final world = computed.worldById[id];
      if (node == null || world == null) continue;

      canvas.save();
      try {
        canvas.transform(world.storage);
        switch (node) {
          case TextNode(data: final data):
            _drawText(
              canvas,
              textValue: data.text,
              family: data.fontFamily,
              weight: data.fontWeight,
              size: data.fontSize,
              letterSpacing: data.letterSpacing,
              appearance: data.appearance,
            );
          case IconNode(data: final data):
            final glyph = computed.iconTextById[id];
            final path = computed.iconPathIRById[id];
            if (glyph != null) {
              _drawText(
                canvas,
                textValue: glyph.glyph,
                family: glyph.fontFamily,
                weight: glyph.fontWeight,
                size: data.sizePx,
                appearance: data.appearance,
              );
            } else if (path != null) {
              _drawPathUnderlays(canvas, path, data.appearance.underlays);
              final foreground = data.appearance.foreground;
              _drawPathFill(
                canvas,
                path,
                foreground,
              );
              if (foreground is! CanvasFillNone) {
                _drawPathStroke(canvas, path);
              }
            }
          case ImageNode(data: final data):
            // A null asset is an intentionally empty frame.
            if (data.assetId == null) break;
            final placement = computed.imagePlacementById[id];
            if (placement != null) {
              _drawImage(canvas, id, placement.src, placement.dst);
            }
          case PathNode(data: final data):
            final path = computed.pathIRById[id];
            if (path != null) {
              _drawPathFill(
                canvas,
                path,
                data.fill,
              );
              _drawPathStroke(canvas, path);
            }
          case GroupNode():
            break;
        }
      } finally {
        canvas.restore();
      }
    }
  }

  void _drawImage(ui.Canvas canvas, ElementId id, Rect2D src, Rect2D dst) {
    final image = images[id];
    final destination = dst.toUi;
    if (image == null) {
      if (options.missingImageBehavior == MissingImageBehavior.placeholder) {
        _drawMissingImagePlaceholder(canvas, destination);
      }
      return;
    }

    canvas.drawImageRect(
      image,
      _mapSrcToDecoded(id: id, img: image, srcIntrinsic: src),
      destination,
      ui.Paint()..filterQuality = options.imageFilterQuality,
    );
  }

  void _drawPathFill(
    ui.Canvas canvas,
    PathIR path,
    CanvasFill fill,
  ) {
    final uiPath = _buildUiPath(path);
    uiPath.fillType = switch (path.style.fillRule) {
      FillRule.evenOdd => ui.PathFillType.evenOdd,
      FillRule.nonZero => ui.PathFillType.nonZero,
    };

    switch (fill) {
      case CanvasFillNone():
        break;
      case CanvasFillSolid(:final color):
        // The scene fill is the paint authority. PathIR supplies only the
        // compiled outline and source stroke/fill-rule metadata.
        canvas.drawPath(
          uiPath,
          ui.Paint()
            ..style = ui.PaintingStyle.fill
            ..color = ui.Color(color),
        );
      case CanvasFillGradient(:final grad):
        canvas.drawPath(
          uiPath,
          ui.Paint()
            ..style = ui.PaintingStyle.fill
            ..shader = buildLinearShaderFlutter(grad),
        );
    }
  }

  void _drawPathStroke(ui.Canvas canvas, PathIR path) {
    final style = path.style;
    if (style.stroke == null || style.strokeWidth <= 0) return;
    canvas.drawPath(
      _buildUiPath(path),
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..color = ui.Color(style.stroke!)
        ..strokeWidth = style.strokeWidth
        ..strokeCap = _mapCap(style.strokeCap)
        ..strokeJoin = _mapJoin(style.strokeJoin)
        ..strokeMiterLimit = style.miterLimit,
    );
  }

  static void _drawMissingImagePlaceholder(ui.Canvas canvas, ui.Rect dstRect) {
    final border = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const ui.Color(0xFF9CA3AF);

    canvas.drawRect(dstRect, border);

    if (dstRect.width <= 20 || dstRect.height <= 20) return;

    final cross = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const ui.Color(0xFFB0B6C2);

    final r = dstRect.deflate(6.0);
    canvas.drawLine(r.topLeft, r.bottomRight, cross);
    canvas.drawLine(r.bottomLeft, r.topRight, cross);
  }

  // --- helpers --------------------------------------------------------------

  static ui.Path _buildUiPath(PathIR ir) {
    final p = ui.Path();
    for (final cmd in ir.cmds) {
      switch (cmd.verb) {
        case PathVerb.moveTo:
          p.moveTo(cmd.p.x, cmd.p.y);
        case PathVerb.lineTo:
          p.lineTo(cmd.p.x, cmd.p.y);
        case PathVerb.quadTo:
          final c = cmd.c1!;
          p.quadraticBezierTo(c.x, c.y, cmd.p.x, cmd.p.y);
        case PathVerb.cubicTo:
          final c1 = cmd.c1!, c2 = cmd.c2!;
          p.cubicTo(c1.x, c1.y, c2.x, c2.y, cmd.p.x, cmd.p.y);
        case PathVerb.close:
          p.close();
      }
    }
    return p;
  }

  static ui.StrokeCap _mapCap(StrokeCap c) => switch (c) {
    StrokeCap.butt => ui.StrokeCap.butt,
    StrokeCap.square => ui.StrokeCap.square,
    StrokeCap.round => ui.StrokeCap.round,
  };

  static ui.StrokeJoin _mapJoin(StrokeJoin j) => switch (j) {
    StrokeJoin.miter => ui.StrokeJoin.miter,
    StrokeJoin.bevel => ui.StrokeJoin.bevel,
    StrokeJoin.round => ui.StrokeJoin.round,
  };

  void _drawPathUnderlays(
    ui.Canvas canvas,
    PathIR ir,
    List<CanvasSourceUnderlay> underlays,
  ) {
    if (ir.cmds.isEmpty) return;

    paintSourceUnderlays(
      canvas,
      underlays: underlays,
      paintSource: (sourceCanvas) {
        final path = _buildUiPath(ir);
        final style = ir.style;

        path.fillType = switch (style.fillRule) {
          FillRule.evenOdd => ui.PathFillType.evenOdd,
          FillRule.nonZero => ui.PathFillType.nonZero,
        };

        // Path-icon source coverage is independent of authored foreground
        // color, alpha, and visibility.
        sourceCanvas.drawPath(
          path,
          ui.Paint()
            ..style = ui.PaintingStyle.fill
            ..color = const ui.Color(0xFF000000),
        );

        if (style.stroke != null && style.strokeWidth > 0) {
          sourceCanvas.drawPath(
            path,
            ui.Paint()
              ..style = ui.PaintingStyle.stroke
              ..color = const ui.Color(0xFF000000)
              ..strokeWidth = style.strokeWidth
              ..strokeCap = _mapCap(style.strokeCap)
              ..strokeJoin = _mapJoin(style.strokeJoin)
              ..strokeMiterLimit = style.miterLimit,
          );
        }
      },
    );
  }

  void _drawText(
    ui.Canvas canvas, {
    required String textValue,
    required String family,
    required FontWeightNum weight,
    required double size,
    double letterSpacing = 0,
    required CanvasAppearance appearance,
  }) {
    if (textValue.isEmpty) return;
    final spec = TextSpec(
      textValue,
      family,
      weight,
      size,
      letterSpacing: letterSpacing,
    );
    const origin = ui.Offset.zero;
    paintSourceUnderlays(
      canvas,
      underlays: appearance.underlays,
      paintSource: (sourceCanvas) {
        text.paint(
          sourceCanvas,
          origin,
          spec,
          originKind: TextOriginKind.center,
        );
      },
    );

    switch (appearance.foreground) {
      case CanvasFillNone():
        break;
      case CanvasFillSolid(:final color):
        text.paint(
          canvas,
          origin,
          spec,
          solid: ui.Color(color),
          originKind: TextOriginKind.center,
        );
      case CanvasFillGradient(:final grad):
        text.paint(
          canvas,
          origin,
          spec,
          shader: buildLinearShaderFlutter(grad),
          originKind: TextOriginKind.center,
        );
    }
  }
}
