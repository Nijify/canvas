// Path: oss_packages/canvas_core/lib/src/render_plan/op_builder_scene.dart

import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;
import 'package:canvas_core/src/foundation/math/affine2d.dart' show toABCDExy;

import 'package:canvas_core/src/services/text_measure.dart' show spacedText;
import 'package:canvas_core/src/render_plan/gradient_resolver.dart'
    show resolveLinearGradient;
import 'package:canvas_core/src/render_plan/paint_ops.dart';

import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/runtime/model/scene_document.dart';
import 'package:canvas_core/src/foundation/paint/canvas_fill.dart';
import 'package:canvas_core/src/algorithms/layout/computed_scene.dart'
    show ComputedScene;
import 'package:canvas_core/src/path/path_ir.dart' show PathIR;

// -----------------------------------------------------------------------------
// Fill helpers (single source of truth)
// -----------------------------------------------------------------------------
//
// Text/Icon have invariant: fill ∈ {solid, gradient} (never none).
// Path may still be none.
//
// Shadow color rule:
// - solid => that color
// - gradient => grad.color1 (deterministic)
Color32 _shadowColorFromFill(CanvasFill fill) => switch (fill) {
  CanvasFillSolid(:final color) => color,
  CanvasFillGradient(:final grad) => grad.color1,
  CanvasFillNone() => 0x00000000, // should not happen for text/icon
};

List<PaintOp> buildPaintOpsFromScene(
  CanvasSceneDocument doc,
  ComputedScene computed,
) {
  final ops = <PaintOp>[];

  // Background
  if (doc.bgOpacity > 0) {
    final grad = resolveLinearGradient(
      doc.bgGradient,
      doc.artboardSize,
      opacity: doc.bgOpacity,
    );
    ops.add(
      FillRectGradientOp(
        Rect2D.fromLTWH(0, 0, doc.artboardSize.w, doc.artboardSize.h),
        grad,
      ),
    );
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
        final txt = spacedText(d.text, d.letterSpacing);

        switch (d.fill) {
          case CanvasFillSolid(:final color):
            ops.add(
              DrawTextOp(
                text: txt,
                family: d.fontFamily,
                weight: d.fontWeight,
                size: d.fontSize,
                originBaselineCenter: const Vec2(0, 0),
                gradient: null,
                solid: color,
                shadowOffset: d.shadowOffset,
              ),
            );
            break;

          case CanvasFillGradient(:final grad):
            final resolved = resolveLinearGradient(grad, doc.artboardSize);
            ops.add(
              DrawTextOp(
                text: txt,
                family: d.fontFamily,
                weight: d.fontWeight,
                size: d.fontSize,
                originBaselineCenter: const Vec2(0, 0),
                gradient: resolved,
                // Provide a deterministic solid fallback for shadow rendering.
                solid: _shadowColorFromFill(d.fill),
                shadowOffset: d.shadowOffset,
              ),
            );
            break;

          case CanvasFillNone():
            // Should be impossible for TextData; skip defensively.
            break;
        }
        break;

      case IconNode(id: final id, data: final d):
        final iconText = computed.iconTextById[id];
        final iconPath = computed.iconPathIRById[id];

        if (iconText != null) {
          switch (d.fill) {
            case CanvasFillSolid(:final color):
              ops.add(
                DrawTextOp(
                  text: iconText.glyph,
                  family: iconText.family,
                  weight: iconText.weight,
                  size: d.sizePx,
                  originBaselineCenter: const Vec2(0, 0),
                  gradient: null,
                  solid: color,
                  shadowOffset: d.shadowOffset,
                ),
              );
              break;

            case CanvasFillGradient(:final grad):
              final resolved = resolveLinearGradient(grad, doc.artboardSize);
              ops.add(
                DrawTextOp(
                  text: iconText.glyph,
                  family: iconText.family,
                  weight: iconText.weight,
                  size: d.sizePx,
                  originBaselineCenter: const Vec2(0, 0),
                  gradient: resolved,
                  // Deterministic shadow color derived from fill.
                  solid: _shadowColorFromFill(d.fill),
                  shadowOffset: d.shadowOffset,
                ),
              );
              break;

            case CanvasFillNone():
              // Should be impossible for icons; skip defensively.
              break;
          }
        } else if (iconPath != null) {
          // Unified mental model: apply CanvasIconData.fill to *path-based* icons too.
          switch (d.fill) {
            case CanvasFillNone():
              // Should be impossible; safe no-op.
              break;

            case CanvasFillSolid():
              // Ensure IR has fill enabled; some renderers treat fill=null as no-op.
              final c = _shadowColorFromFill(d.fill);
              final ir = (iconPath.style.fill == null)
                  ? PathIR(iconPath.cmds, iconPath.style.copyWith(fill: c))
                  : iconPath;
              ops.add(FillPathOp(ir));
              break;

            case CanvasFillGradient(:final grad):
              final resolved = resolveLinearGradient(grad, doc.artboardSize);
              // Ensure IR has fill enabled.
              final seed = grad.color1;
              final ir = (iconPath.style.fill == null)
                  ? PathIR(iconPath.cmds, iconPath.style.copyWith(fill: seed))
                  : iconPath;
              ops.add(FillPathGradientOp(ir, resolved));
              break;
          }

          if (iconPath.style.stroke != null && iconPath.style.strokeWidth > 0) {
            ops.add(StrokePathOp(iconPath));
          }
        }
        break;

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
