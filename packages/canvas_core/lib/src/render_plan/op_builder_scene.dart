// Path: lib/src/render_plan/op_builder_scene.dart

import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;
import 'package:canvas_core/src/foundation/math/affine2d.dart' show toABCDExy;
import 'package:canvas_core/src/render_plan/gradient_resolver.dart'
    show resolveLinearGradient;
import 'package:canvas_core/src/render_plan/paint_ops.dart';

import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/runtime/model/scene_document.dart';
import 'package:canvas_core/src/foundation/paint/canvas_fill.dart';
import 'package:canvas_core/src/algorithms/layout/computed_scene.dart'
    show ComputedScene;
import 'package:canvas_core/src/path/path_ir.dart' show PathIR;

Color32 _applyOpacityToArgb(Color32 argb, double opacity) {
  final alpha = (argb >> 24) & 0xFF;
  final mergedAlpha = (alpha * opacity).clamp(0, 255).round();
  return (mergedAlpha << 24) | (argb & 0x00FFFFFF);
}

List<PaintOp> buildPaintOpsFromScene(
  CanvasSceneDocument doc,
  ComputedScene computed,
) {
  final ops = <PaintOp>[];

  // Background
  final backgroundRect = Rect2D.fromLTWH(
    0,
    0,
    doc.artboardSize.w,
    doc.artboardSize.h,
  );

  if (doc.backgroundOpacity > 0) {
    switch (doc.backgroundFill) {
      case CanvasFillNone():
        break;

      case CanvasFillSolid(:final color):
        ops.add(
          FillRectOp(
            backgroundRect,
            _applyOpacityToArgb(color, doc.backgroundOpacity),
          ),
        );
        break;

      case CanvasFillGradient(:final grad):
        ops.add(
          FillRectGradientOp(
            backgroundRect,
            resolveLinearGradient(
              grad,
              doc.artboardSize,
              opacity: doc.backgroundOpacity,
            ),
          ),
        );
        break;
    }
  }

  for (final item in computed.drawList) {
    final leafId = item.leafId;

    final leaf = computed.nodeById[leafId];
    if (leaf == null) continue;

    final world = computed.worldById[leafId];
    if (world == null) continue;

    final (six: s6) = toABCDExy(world);

    ops.add(SaveOp());
    final set = SetTransformOp(s6[0], s6[1], s6[2], s6[3], s6[4], s6[5]);
    if (!set.isIdentity) ops.add(set);

    switch (leaf) {
      case TextNode(data: final d):
        final appearance = d.appearance;

        switch (appearance.foreground) {
          case CanvasFillSolid(:final color):
            ops.add(
              DrawTextOp(
                text: d.text,
                family: d.fontFamily,
                weight: d.fontWeight,
                size: d.fontSize,
                letterSpacing: d.letterSpacing,
                originBaselineCenter: const Vec2(0, 0),
                solid: color,
                underlays: appearance.underlays,
              ),
            );

          case CanvasFillGradient(:final grad):
            ops.add(
              DrawTextOp(
                text: d.text,
                family: d.fontFamily,
                weight: d.fontWeight,
                size: d.fontSize,
                letterSpacing: d.letterSpacing,
                originBaselineCenter: const Vec2(0, 0),
                gradient: resolveLinearGradient(grad, doc.artboardSize),
                underlays: appearance.underlays,
              ),
            );

          case CanvasFillNone():
            if (appearance.underlays.isNotEmpty) {
              ops.add(
                DrawTextOp(
                  text: d.text,
                  family: d.fontFamily,
                  weight: d.fontWeight,
                  size: d.fontSize,
                  letterSpacing: d.letterSpacing,
                  originBaselineCenter: const Vec2(0, 0),
                  underlays: appearance.underlays,
                ),
              );
            }
        }
        break;

      case IconNode(id: final id, data: final d):
        final iconText = computed.iconTextById[id];
        final iconPath = computed.iconPathIRById[id];

        if (iconText != null) {
          final appearance = d.appearance;

          switch (appearance.foreground) {
            case CanvasFillSolid(:final color):
              ops.add(
                DrawTextOp(
                  text: iconText.glyph,
                  family: iconText.fontFamily,
                  weight: iconText.fontWeight,
                  size: d.sizePx,
                  originBaselineCenter: const Vec2(0, 0),
                  solid: color,
                  underlays: appearance.underlays,
                ),
              );

            case CanvasFillGradient(:final grad):
              ops.add(
                DrawTextOp(
                  text: iconText.glyph,
                  family: iconText.fontFamily,
                  weight: iconText.fontWeight,
                  size: d.sizePx,
                  originBaselineCenter: const Vec2(0, 0),
                  gradient: resolveLinearGradient(grad, doc.artboardSize),
                  underlays: appearance.underlays,
                ),
              );

            case CanvasFillNone():
              if (appearance.underlays.isNotEmpty) {
                ops.add(
                  DrawTextOp(
                    text: iconText.glyph,
                    family: iconText.fontFamily,
                    weight: iconText.fontWeight,
                    size: d.sizePx,
                    originBaselineCenter: const Vec2(0, 0),
                    underlays: appearance.underlays,
                  ),
                );
              }
          }
        } else if (iconPath != null) {
          final appearance = d.appearance;

          if (appearance.underlays.isNotEmpty) {
            ops.add(DrawPathUnderlaysOp(iconPath, appearance.underlays));
          }

          switch (appearance.foreground) {
            case CanvasFillNone():
              // Source still exists for underlays, but no foreground path paint.
              break;

            case CanvasFillSolid(:final color):
              final ir = PathIR(
                iconPath.cmds,
                iconPath.style.copyWith(fill: color),
              );
              ops.add(FillPathOp(ir));

            case CanvasFillGradient(:final grad):
              final resolved = resolveLinearGradient(grad, doc.artboardSize);

              final seed = grad.color1;
              final ir = iconPath.style.fill == null
                  ? PathIR(iconPath.cmds, iconPath.style.copyWith(fill: seed))
                  : iconPath;

              ops.add(FillPathGradientOp(ir, resolved));
          }

          // Intrinsic path stroke is part of the icon's authored foreground.
          // CanvasFill.none() suppresses it visually, but it remains part of the
          // source silhouette used by underlays.
          if (appearance.foreground is! CanvasFillNone &&
              iconPath.style.stroke != null &&
              iconPath.style.strokeWidth > 0) {
            ops.add(StrokePathOp(iconPath));
          }
        }

      case ImageNode(id: final id):
        final placement = computed.imagePlacementById[id];
        if (placement != null) {
          ops.add(DrawImageOp(id, placement.src, placement.dst));
        }
        break;

      case PathNode(id: final id, data: final d):
        final ir = computed.pathIRById[id];
        if (ir == null) break;

        switch (d.fill) {
          case CanvasFillNone():
            break;

          case CanvasFillSolid():
            if (ir.style.fill != null) ops.add(FillPathOp(ir));
            break;

          case CanvasFillGradient(:final grad):
            final resolved = resolveLinearGradient(grad, doc.artboardSize);
            ops.add(FillPathGradientOp(ir, resolved));
            break;
        }

        if (ir.style.stroke != null && ir.style.strokeWidth > 0) {
          ops.add(StrokePathOp(ir));
        }
        break;

      default:
        break;
    }

    ops.add(RestoreOp());
  }

  return ops;
}
