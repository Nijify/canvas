import 'package:canvas_core/src/foundation/ids.dart' show CanvasAssetId;
import 'package:canvas_core/src/runtime/model/node_model.dart' show ImageNode;
import 'package:canvas_core/src/runtime/model/scene_document.dart';
import 'package:canvas_core/src/runtime/traversal/traversal.dart'
    show visitSceneNodes;
import 'package:canvas_core/src/runtime/validation/scene_document_validation.dart';

/// Validates [scene] and retains image assets referenced by its nodes.
///
/// Returns [scene] unchanged when no assets need pruning. Otherwise creates a
/// new registry, leaving existing scenes and history snapshots untouched.
/// This never deletes underlying media or examines host-owned project data.
CanvasSceneDocument pruneUnusedImageAssets(CanvasSceneDocument scene) {
  requireCanvasSceneIntegrity(scene);
  if (scene.assets.isEmpty) return scene;

  final referenced = <CanvasAssetId>{};
  visitSceneNodes(
    scene,
    visit: (node) {
      if (node is ImageNode && node.assetId != null) {
        referenced.add(node.assetId!);
      }
    },
  );
  if (scene.assets.keys.every(referenced.contains)) return scene;

  return scene.copyWith(
    assets: <CanvasAssetId, CanvasImageAsset>{
      for (final entry in scene.assets.entries)
        if (referenced.contains(entry.key)) entry.key: entry.value,
    },
  );
}
