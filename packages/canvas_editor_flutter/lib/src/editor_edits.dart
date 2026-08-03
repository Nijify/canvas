// Path: oss_packages/canvas_editor_flutter/lib/src/editor_edits.dart
//
// Concrete reusable scene-edit factories.
//
// Mental model:
// - editor_api.dart owns the layer-neutral edit contract.
// - this file owns reusable base/runtime scene edit factories.
// - EditorRuntime applies edits to the canonical/base scene with history,
//   adapter hooks, and render invalidation.
// - UI/actions should prefer these factories over one-off controller methods
//   when the edit is a generic scene-tree mutation.

import 'package:canvas_core/canvas_core_runtime.dart' as rt;
import 'package:canvas_editor_flutter/src/editor_api.dart';

abstract final class EditorEdits {
  static EditorEdit addNode(rt.Node node) {
    return (scene) {
      return EditorEditResult(
        scene: rt.SceneTreeOps.addNode(scene, node),
        primaryId: node.id,
      );
    };
  }

  static EditorEdit updateNode(
    rt.ElementId id,
    rt.Node Function(rt.Node node) update,
  ) {
    return (scene) {
      final node = rt.findById(scene, id);

      if (node == null) {
        return EditorEditResult(scene: scene);
      }

      final nextNode = update(node);

      if (identical(nextNode, node) || nextNode == node) {
        return EditorEditResult(scene: scene, primaryId: id);
      }

      return EditorEditResult(
        scene: rt.replaceById(scene, id, nextNode),
        primaryId: id,
      );
    };
  }

  static EditorEdit updateScene(
    rt.CanvasSceneDocument Function(rt.CanvasSceneDocument scene) update,
  ) {
    return (scene) {
      final next = update(scene);

      if (identical(next, scene) || next == scene) {
        return EditorEditResult(scene: scene);
      }

      return EditorEditResult(scene: next);
    };
  }

  static EditorEdit replaceNode(rt.ElementId id, rt.Node updated) {
    return updateNode(id, (_) => updated);
  }

  static EditorEdit renameElement(rt.ElementId id, String? name) {
    return updateNode(id, (node) => node.withName(name));
  }

  // TODO(canvas-model): Layer visibility currently uses persisted Node.hidden.
  // Revisit whether visibility should instead be represented by editor-owned
  // state when it must not affect the rendered or exported document.
  static EditorEdit setElementHidden(rt.ElementId id, bool hidden) {
    return updateNode(id, (node) => node.withHidden(hidden));
  }

  static EditorEdit setElementLocked(rt.ElementId id, bool locked) {
    return updateNode(id, (node) => node.withLocked(locked));
  }

  static EditorEdit deleteSubtree(rt.ElementId id) {
    return (scene) {
      final result = rt.SceneTreeOps.deleteSubtree(scene, id);

      return EditorEditResult(scene: result.doc, deletedIds: result.deletedIds);
    };
  }

  static EditorEdit duplicateSubtree(rt.ElementId id) {
    return (scene) {
      final result = rt.SceneTreeOps.duplicateSubtree(scene, id);

      return EditorEditResult(
        scene: result.doc,
        primaryId: result.primaryId,
        duplicatedIds: result.idMap,
      );
    };
  }

  static EditorEdit bringToFront(rt.ElementId id) {
    return (scene) {
      return EditorEditResult(
        scene: rt.SceneTreeOps.bringToFront(scene, id),
        primaryId: id,
      );
    };
  }

  static EditorEdit sendToBack(rt.ElementId id) {
    return (scene) {
      return EditorEditResult(
        scene: rt.SceneTreeOps.sendToBack(scene, id),
        primaryId: id,
      );
    };
  }

  static EditorEdit bringForward(rt.ElementId id) {
    return (scene) {
      return EditorEditResult(
        scene: rt.SceneTreeOps.bringForward(scene, id),
        primaryId: id,
      );
    };
  }

  static EditorEdit sendBackward(rt.ElementId id) {
    return (scene) {
      return EditorEditResult(
        scene: rt.SceneTreeOps.sendBackward(scene, id),
        primaryId: id,
      );
    };
  }
}
