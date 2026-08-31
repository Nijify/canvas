// Path: lib/src/runtime/resources/scene_font_families.dart

import 'package:canvas_core/src/runtime/model/node_model.dart'
    show IconNode, TextNode;
import 'package:canvas_core/src/runtime/model/scene_document.dart'
    show CanvasSceneDocument;
import 'package:canvas_core/src/runtime/traversal/traversal.dart'
    show visitSceneNodes;
import 'package:canvas_core/src/services/icon_resolver.dart'
    show IconResolver, ResolvedIconText;

/// Collects logical font-family dependencies referenced by a scene.
///
/// This function performs discovery only. It does not load fonts, inspect
/// platform assets, or validate that a family is available on the current host.
///
/// Hidden nodes are included because resource preflight must account for the
/// complete logical document rather than only the currently painted subset.
///
/// Font-backed icons contribute their resolved font family. Path-backed and
/// unresolved icons do not contribute a font family.
Set<String> collectSceneFontFamilies(
  CanvasSceneDocument scene, {
  Iterable<String> fallbackFontFamilies = const <String>[],
  IconResolver? icons,
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
        return;
      }

      if (node is IconNode) {
        final resolved = icons?.resolve(node.data.iconRef);

        if (resolved is ResolvedIconText) {
          addFamily(resolved.fontFamily);
        }
      }
    },
  );

  return Set<String>.unmodifiable(families);
}
