// Path: lib/src/algorithms/layout/node_geometry.dart

import 'package:canvas_core/src/algorithms/layout/image_fit.dart'
    show ImagePlacement, imageSrcDst;
import 'package:canvas_core/src/foundation/geometry/geometry.dart';
import 'package:canvas_core/src/foundation/ids.dart' show ElementId;
import 'package:canvas_core/src/path/path_ir.dart';
import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/services/icon_resolver.dart';
import 'package:canvas_core/src/adapters/path_compile_scene.dart';
import 'package:canvas_core/src/services/services_context.dart';

final class NodeGeometry {
  const NodeGeometry(this.services);

  final CoreServices services;

  Rect2D? leafLocalBounds(
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
        return Rect2D.fromLTWH(-m.w / 2, -m.h / 2, m.w, m.h);

      case IconNode(id: final id, data: final d):
        // Icon bounds must remain deterministic across different icon
        // implementations such as font glyphs and vector paths.
        //
        // Glyph metrics and path bounds vary per icon, which would otherwise shift
        // layout and picking geometry. We still resolve the icon for rendering and
        // caching, but layout uses a stable centered square based on sizePx.
        final resolved = s.icons?.resolve(d.iconRef);
        switch (resolved) {
          case ResolvedIconText():
            iconTextById?[id] = resolved;
            // Return stable bounds (do NOT use measured glyph bounds for layout).
            final sz = d.sizePx;
            return Rect2D.fromLTWH(-sz / 2, -sz / 2, sz, sz);

          case ResolvedIconPath(:final path):
            // Keep the compiled path for rendering/caching, but still return stable bounds.
            final ir = compilePath(path);
            iconPathIRById?[id] = ir;
            final sz = d.sizePx;
            return Rect2D.fromLTWH(-sz / 2, -sz / 2, sz, sz);

          default:
            final sz = d.sizePx;
            return Rect2D.fromLTWH(-sz / 2, -sz / 2, sz, sz);
        }

      case ImageNode(id: final id, data: final d):
        final intrinsic = s.images?.intrinsicSize(id);
        final layout = d.size;

        if (layout.w <= 0 || layout.h <= 0) {
          // Not measurable yet (prevents degenerate bounds affecting snap/pick/fit)
          return null;
        }

        final placement = imageSrcDst(
          intrinsic: intrinsic ?? layout,
          layout: layout,
          fit: d.fit,
          align: d.align,
        );

        imagePlacementById?[id] = placement;
        return placement.dst;

      case PathNode(id: final id, data: final d):
        final ir = compilePath(d);
        pathIRById?[id] = ir;
        return ir.localBounds(includeStroke: true);

      default:
        return null;
    }
  }
}
