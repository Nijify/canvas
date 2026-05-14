// Path: lib/src/algorithms/layout/node_geometry.dart

import 'package:canvas_core/src/algorithms/layout/layout_payloads.dart';
import 'package:canvas_core/src/foundation/geometry/geometry.dart';
import 'package:canvas_core/src/path/path_ir.dart';
import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/services/icon_resolver.dart';
import 'package:canvas_core/src/adapters/path_compile_scene.dart';
import 'package:canvas_core/src/services/services_context.dart';
import 'package:canvas_core/src/algorithms/layout/image_fit.dart'
    show imageSrcDst;

final class NodeGeometry {
  const NodeGeometry(this.services);

  final CoreServices services;

  Rect2D? leafLocalBounds(
    Node n, {
    Map<NodeId, PathIR>? pathIRById,
    Map<NodeId, ImagePlacement>? imagePlacementById,
    Map<NodeId, IconTextPayload>? iconTextById,
    Map<NodeId, PathIR>? iconPathIRById,
  }) {
    final s = services;

    switch (n) {
      case TextNode(:final data):
        final m = s.measureSpacedText(
          text: data.text,
          fontFamily: data.fontFamily,
          fontWeight: data.fontWeight,
          fontSize: data.fontSize,
          letterSpacing: data.letterSpacing,
        );
        return Rect2D.fromLTWH(-m.w / 2, -m.h / 2, m.w, m.h);

      case IconNode(id: final id, data: final d):
        // ✅ IMPORTANT:
        // For layout stability (esp. LogoLayoutPolicy), icon bounds must be
        // deterministic across different icon implementations (font glyph vs svg/path).
        //
        // Glyph metrics and path bounds vary per icon, which shifts `r.left/r.top`,
        // causing layout jitter and pill-shape drift. We still resolve the icon so
        // renderer can draw it (and caches can be filled), but we return a stable
        // centered square based on sizePx for layout/picking bounds.
        final resolved = s.icons?.resolve(d.iconRef);
        switch (resolved) {
          case ResolvedIconText():
            iconTextById?[id] = IconTextPayload(
              glyph: resolved.glyph,
              family: resolved.fontFamily,
              weight: resolved.fontWeight,
            );
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
        final layout = d.size ?? intrinsic;

        if (layout == null || layout.w <= 0 || layout.h <= 0) {
          // Not measurable yet (prevents degenerate bounds affecting snap/pick/fit)
          return null;
        }

        final placement = imageSrcDst(
          intrinsic: intrinsic ?? layout,
          layout: layout,
          fit: d.fit,
          align: d.align,
        );

        imagePlacementById?[id] = ImagePlacement(
          src: placement.src,
          dst: placement.dst,
        );
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
