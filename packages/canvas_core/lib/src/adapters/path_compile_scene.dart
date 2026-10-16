// Path: lib/src/adapters/path_compile_scene.dart
//
// Scene-level adapter: PathData (scene model) -> PathIR (path subsystem)
//
// This must live under /scene because it depends on PathData from node_model.dart.
// Keeping /path pure makes the dependency direction clearer:
// core -> path -> scene -> algorithms/pipeline.

import 'package:canvas_core/src/path/path_compile.dart';
import 'package:canvas_core/src/path/path_ir.dart' show PathIR;
import 'package:canvas_core/src/path/path_source.dart';
import 'package:canvas_core/src/runtime/model/node_model.dart' show PathData;

const _compiler = PathCompiler();

/// Cache compiled IR per PathData instance identity.
final _irCache = Expando<PathIR>('PathIR');

PathIR compilePath(PathData d) {
  final cached = _irCache[d];
  if (cached != null) return cached;

  final ir = (d.source != null)
      ? _compiler.fromSource(d.source!)
      : _compiler.fromSource(PolylineSource(d.points));

  _irCache[d] = ir;
  return ir;
}
