import 'package:canvas_core/src/path/path_compile.dart';
import 'package:canvas_core/src/algorithms/layout/image_fit.dart'
    show ImagePlacement, imageSrcDst;
import 'package:canvas_core/src/algorithms/layout/computed_icon.dart'
    show ComputedIcon;
import 'package:canvas_core/src/foundation/geometry/geometry.dart';
import 'package:canvas_core/src/algorithms/layout/appearance_bounds.dart';
import 'package:canvas_core/src/foundation/ids.dart' show ElementId;
import 'package:canvas_core/src/path/path_ir.dart';
import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/runtime/geometry/scene_math.dart'
    show aabbOfTransformedRect;
import 'package:canvas_core/src/services/services_context.dart';

final class NodeGeometry {
  const NodeGeometry(this.services);

  final CoreServices services;

  /// Layout describes intrinsic geometry independently of appearance.
  /// Paint is an estimate; null means no visible paint is expecten.
  /// Text estimates use layout metrics, not guaranteed glyph-pixel bounds.
  ({Rect2D layout, Rect2D? paint})? leafBounds(
    Node n, {
    Map<ElementId, PathIR>? pathIRById,
    Map<ElementId, ImagePlacement>? imagePlacementById,
    Map<ElementId, ComputedIcon>? iconById,
  }) {
    final s = services;

    switch (n) {
      case TextNode():
        final m = s.textMeasurer.measure(
          text: n.text,
          fontFamily: n.fontFamily,
          fontWeight: n.fontWeight,
          fontSize: n.fontSize,
          letterSpacing: n.letterSpacing,
        );

        final layout = Rect2D.fromLTWH(-m.w / 2, -m.h / 2, m.w, m.h);
        final sourceBounds = n.text.isEmpty ? null : layout;
        final appearance = n.appearance;

        return (
          layout: layout,
          paint: estimateAppearancePaintBounds(
            sourceBounds: sourceBounds,
            foregroundPresent: fillContributesToPaint(appearance.foreground),
            underlays: appearance.underlays,
          ),
        );

      case IconNode(:final id):
        final size = n.sizePx;
        if (!size.isFinite || size <= 0) {
          throw ArgumentError.value(
            size,
            'sizePx',
            'Must be finite and positive.',
          );
        }
        final layout = Rect2D.fromLTWH(-size / 2, -size / 2, size, size);
        final resolved = s.icons?.resolve(n.iconRef);

        if (resolved == null) return (layout: layout, paint: null);
        final icon = ComputedIcon.fit(resolved, size);
        iconById?[id] = icon;
        final sourceBounds = !icon.pathIR.hasSegments
            ? null
            : aabbOfTransformedRect(
                icon.pathIR.localBounds(),
                icon.sourceToLocal,
              );
        final appearance = n.appearance;
        return (
          layout: layout,
          paint: estimateAppearancePaintBounds(
            sourceBounds: sourceBounds,
            foregroundPresent: fillContributesToPaint(appearance.foreground),
            underlays: appearance.underlays,
          ),
        );

      case ImageNode(:final id):
        final intrinsic = s.images?.intrinsicSize(id);
        final size = n.size;
        if (size.w <= 0 || size.h <= 0) return null;

        final placement = imageSrcDst(
          intrinsic: intrinsic ?? size,
          layout: size,
          fit: n.fit,
          align: n.align,
        );
        imagePlacementById?[id] = placement;
        // Preserve contain-fit destination geometry, including its offset.
        return (layout: placement.dst, paint: placement.dst);

      case PathNode(:final id):
        final ir = compilePath(n.geometry);
        pathIRById?[id] = ir;
        final geometryBounds = ir.localBounds();
        return (
          layout: geometryBounds,
          paint: estimatePathPaintBounds(
            sourceBounds: ir.hasSegments ? geometryBounds : null,
            appearance: n.appearance,
          ),
        );

      default:
        return null;
    }
  }
}
