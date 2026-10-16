// Path: lib/src/runtime/resources/scene_font_families.dart

import 'package:canvas_core/src/runtime/model/node_model.dart' show TextNode;
import 'package:canvas_core/src/runtime/model/scene_document.dart'
    show CanvasSceneDocument;
import 'package:canvas_core/src/runtime/traversal/traversal.dart'
    show visitSceneNodes;

/// Collects logical font-family dependencies referenced by a scene.
///
/// This function performs discovery only. It does not load fonts, inspect
/// platform assets, or validate that a family is available on the current host.
///
/// Hidden nodes are included because resource preflight must account for the
/// complete logical document rather than only the currently painted subset.
///
/// Icons contain vector geometry and contribute no font-family dependencies.
Set<String> collectSceneFontFamilies(
  CanvasSceneDocument scene, {
  Iterable<String> fallbackFontFamilies = const <String>[],
}) {
  final families = <String>{};

  void addFamily(String family) {
    final normalized = family.trim();
    if (normalized.isNotEmpty) {
      families.add(normalized);
    }
  }

  for (final family in fallbackFontFamilies) {
    addFamily(family);
  }

  visitSceneNodes(
    scene,
    includeHidden: true,
    visit: (node) {
      if (node is TextNode) {
        addFamily(node.data.fontFamily);
      }
    },
  );

  return Set<String>.unmodifiable(families);
}
