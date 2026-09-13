import 'package:canvas_core/src/adapters/path_compile_scene.dart';
import 'package:canvas_core/src/algorithms/layout/image_fit.dart'
    show ImagePlacement, imageSrcDst;
import 'package:canvas_core/src/foundation/core_types.dart' show Vec2;
import 'package:canvas_core/src/foundation/geometry/geometry.dart';
import 'package:canvas_core/src/foundation/geometry/geometry_ext.dart'
    show Rect2DX;
import 'package:canvas_core/src/foundation/ids.dart' show ElementId;
import 'package:canvas_core/src/path/path_ir.dart';
import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/services/icon_resolver.dart';
import 'package:canvas_core/src/services/services_context.dart';

final class NodeGeometry {
  const NodeGeometry(this.services);

  final CoreServices services;

  /// Layout preserves existing pivot and interaction geometry.
  /// Paint is an estimate; null means no resolved source will be drawn.
  /// Text estimates use layout metrics, not guaranteed glyph-pixel bounds.
  ({Rect2D layout, Rect2D? paint})? leafBounds(
    Node n, {
    Map<ElementId, PathIR>? pathIRById,
    Map<ElementId, ImagePlacement>? imagePlacementById,
    Map<ElementId, ResolvedIconText>? iconTextById,
    Map<ElementId, PathIR>? iconPathIRById,
  }) {
    final s = services;

    switch (n) {
      case TextNode(:final data):
        final m = s.textMeasurer.measure(
          text: data.text,
          fontFamily: data.fontFamily,
          fontWeight: data.fontWeight,
          fontSize: data.fontSize,
          letterSpacing: data.letterSpacing,
        );
        final layout = Rect2D.fromLTWH(-m.w / 2, -m.h / 2, m.w, m.h);
        final basePaint = data.text.isEmpty ? null : layout;
        return (
          layout: layout,
          paint: _withTranslatedShadow(basePaint, data.shadowOffset),
        );

      case IconNode(id: final id, data: final d):
        final size = d.sizePx;
        final layout = Rect2D.fromLTWH(-size / 2, -size / 2, size, size);
        final resolved = s.icons?.resolve(d.iconRef);

        switch (resolved) {
          case ResolvedIconText():
            iconTextById?[id] = resolved;
            if (resolved.glyph.isEmpty) {
              return (layout: layout, paint: null);
            }

            // Match DrawTextOp's glyph metrics and center-origin painting.
            // The stable icon square remains the layout/pivot geometry.
            final m = s.textMeasurer.measure(
              text: resolved.glyph,
              fontFamily: resolved.fontFamily,
              fontWeight: resolved.fontWeight,
              fontSize: size,
              letterSpacing: 0,
            );
            final basePaint = Rect2D.fromLTWH(-m.w / 2, -m.h / 2, m.w, m.h);
            return (
              layout: layout,
              paint: _withTranslatedShadow(basePaint, d.shadowOffset),
            );

          case ResolvedIconPath(:final path):
            final ir = compilePath(path);
            iconPathIRById?[id] = ir;
            // Path icons currently paint their compiled coordinates directly.
            // They do not render shadowOffset; do not expand for it here.
            return (
              layout: layout,
              paint: ir.cmds.isEmpty
                  ? null
                  : ir.localBounds(includeStroke: true),
            );

          default:
            return (layout: layout, paint: null);
        }

      case ImageNode(id: final id, data: final d):
        final intrinsic = s.images?.intrinsicSize(id);
        final size = d.size;
        if (size.w <= 0 || size.h <= 0) return null;

        final placement = imageSrcDst(
          intrinsic: intrinsic ?? size,
          layout: size,
          fit: d.fit,
          align: d.align,
        );
        imagePlacementById?[id] = placement;
        // Preserve contain-fit destination geometry, including its offset.
        return (layout: placement.dst, paint: placement.dst);

      case PathNode(id: final id, data: final d):
        final ir = compilePath(d);
        pathIRById?[id] = ir;
        final layout = ir.localBounds(includeStroke: true);
        // Retain the existing path/stroke estimate in this PR.
        return (layout: layout, paint: ir.cmds.isEmpty ? null : layout);

      default:
        return null;
    }
  }
}

Rect2D? _withTranslatedShadow(Rect2D? basePaint, double offset) {
  if (basePaint == null || offset == 0) return basePaint;
  return Rect2DX.union(basePaint, basePaint.translate(Vec2(offset, offset)));
}
