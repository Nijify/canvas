// Path: lib/src/adapters/path_compile_scene.dart
//
// Adapts authored PathData to geometry-only PathIR.
// Scene-model dependencies stay here so the path compiler is independent of nodes.

import 'package:canvas_core/src/path/path_compile.dart';
import 'package:canvas_core/src/path/path_ir.dart' show PathIR;
import 'package:canvas_core/src/runtime/model/node_model.dart' show PathData;

const _compiler = PathCompiler();

/// Cache compiled geometry per source identity, independently of appearance
/// and fill rule. Sources with collections snapshot them at construction.
final _irCache = Expando<PathIR>('PathIR');

PathIR compilePath(PathData d) {
  final source = d.source;
  final cached = _irCache[source];
  if (cached != null) return cached;

  final ir = _compiler.fromSource(source);

  _irCache[source] = ir;
  return ir;
}
