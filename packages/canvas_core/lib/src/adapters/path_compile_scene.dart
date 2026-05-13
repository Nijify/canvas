// Path: oss_packages/canvas_core/lib/src/adapters/path_compile_scene.dart
//
// Scene-level adapter: PathData (scene model) -> PathIR (path subsystem)
//
// This must live under /scene because it depends on PathData from node_model.dart.
// Keeping /path pure makes the dependency direction clearer:
// core -> path -> scene -> algorithms/pipeline.

import 'package:canvas_core/src/path/path_compile.dart';
import 'package:canvas_core/src/path/path_ir.dart' show PathIR, PathStyle;
import 'package:canvas_core/src/path/path_source.dart';
import 'package:canvas_core/src/runtime/model/node_model.dart' show PathData;
import 'package:canvas_core/src/foundation/paint/canvas_fill.dart';

const _compiler = PathCompiler();

/// Cache compiled IR per PathData instance identity.
final _irCache = Expando<PathIR>('PathIR');

PathIR compilePath(PathData d) {
  final cached = _irCache[d];
  if (cached != null) return cached;

  final solidFill = switch (d.fill) {
    CanvasFillSolid(:final color) =>
      (((color >> 24) & 0xFF) != 0) ? color : null,
    _ => null,
  };

  final style = PathStyle(
    fill: solidFill,
    fillRule: d.fillRule,
    stroke: (d.strokeWidth > 0 && d.strokeColor != 0) ? d.strokeColor : null,
    strokeWidth: d.strokeWidth,
    strokeCap: d.strokeCap,
    strokeJoin: d.strokeJoin,
    miterLimit: d.miterLimit,
    dash: d.dash.isEmpty ? null : d.dash,
  );

  final ir = (d.source != null)
      ? _compiler.fromSource(d.source!, style)
      : _compiler.fromSource(PolylineSource(d.points), style);

  _irCache[d] = ir;
  return ir;
}
