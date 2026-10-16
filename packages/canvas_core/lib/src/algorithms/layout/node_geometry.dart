import 'package:canvas_core/src/adapters/path_compile_scene.dart';
import 'package:canvas_core/src/algorithms/layout/image_fit.dart'
    show ImagePlacement, imageSrcDst;
import 'package:canvas_core/src/algorithms/layout/computed_icon.dart'
    show ComputedIcon;
import 'package:canvas_core/src/foundation/geometry/geometry.dart';
import 'package:canvas_core/src/algorithms/layout/appearance_bounds.dart';
import 'package:canvas_core/src/foundation/paint/canvas_fill.dart';
import 'package:canvas_core/src/foundation/ids.dart' show ElementId;
import 'package:canvas_core/src/path/path_ir.dart';
import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/runtime/geometry/scene_math.dart'
    show aabbOfTransformedRect;
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
    Map<ElementId, ComputedIcon>? iconById,
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
        final sourceBounds = data.text.isEmpty ? null : layout;
        final appearance = data.appearance;

        return (
          layout: layout,
          paint: estimateAppearancePaintBounds(
            sourceBounds: sourceBounds,
            foregroundPresent: appearance.foreground is! CanvasFillNone,
            underlays: appearance.underlays,
          ),
        );

      case IconNode(id: final id, data: final d):
        final size = d.sizePx;
        final layout = Rect2D.fromLTWH(-size / 2, -size / 2, size, size);
        final resolved = s.icons?.resolve(d.iconRef);

        if (resolved == null) return (layout: layout, paint: null);
        final icon = ComputedIcon.fit(resolved, size);
        iconById?[id] = icon;
        final sourceBounds = icon.pathIR.cmds.isEmpty
            ? null
            : aabbOfTransformedRect(
                icon.pathIR.localBounds(),
                icon.sourceToLocal,
              );
        final appearance = d.appearance;
        return (
          layout: layout,
          paint: estimateAppearancePaintBounds(
            sourceBounds: sourceBounds,
            foregroundPresent: appearance.foreground is! CanvasFillNone,
            underlays: appearance.underlays,
          ),
        );

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
        final geometryBounds = ir.localBounds();
        final hasStroke = d.strokeColor != 0 && d.strokeWidth > 0;
        final radius = hasStroke ? d.strokeWidth / 2 : 0.0;
        final layout = ir.cmds.isEmpty || !hasStroke
            ? geometryBounds
            : Rect2D.fromLTRB(
                geometryBounds.left - radius,
                geometryBounds.top - radius,
                geometryBounds.right + radius,
                geometryBounds.bottom + radius,
              );
        // Preserve the existing ordinary-path stroke estimate and pivots.
        return (layout: layout, paint: ir.cmds.isEmpty ? null : layout);

      default:
        return null;
    }
  }
}
