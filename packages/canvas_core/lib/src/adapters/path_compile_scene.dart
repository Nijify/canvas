// Path: lib/src/adapters/path_compile_scene.dart
//
// Adapts authored PathData to geometry-only PathIR.
// Scene-model dependencies stay here so the path compiler is independent of nodes.

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
