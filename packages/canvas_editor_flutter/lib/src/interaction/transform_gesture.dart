import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/editor_api.dart';

/// One gesture owns a fixed target and immutable starting coordinate frame.
/// Rendering/publication cadence never becomes the next operation's baseline.
final class TransformGesture {
  TransformGesture._(this.controller, this.id, this.local, this.parentWorld,
      this.evaluation, this._end);

  final EditorController controller;
  final ElementId id;
  final Affine2D local;
  final Affine2D parentWorld;
  final SceneEvaluation evaluation;
  void Function()? _end;

  static TransformGesture? start(EditorController controller, ElementId id) {
    final end = controller.beginEditSession();
    final evaluation = controller.render.value;
    final source = findById(controller.document.value, id);
    final rendered = findById(evaluation.scene, id);
    final parent = parentWorldTransformOf(evaluation.scene, id);
    // Prepared placement belongs to component controls, not free transforms.
    if (source == null || rendered == null || source.xf != rendered.xf ||
        parent == null || parent.tryInverse() == null) {
      end();
      return null;
    }
    return TransformGesture._(controller, id, source.xf, parent, evaluation, end);
  }

  bool applyWorldDelta(Affine2D delta) {
    if (_end == null || findById(controller.document.value, id) == null) return false;
    // Stop if hierarchy placement changed independently during the gesture.
    final currentParent = parentWorldTransformOf(controller.render.value.scene, id);
    if (currentParent != parentWorld) return false;
    try {
      controller.updateTransform(id, transformAfterDelta(local, delta,
        space: TransformSpace.world, parentWorld: parentWorld));
      return true;
    } on ArgumentError {
      return false;
    } on StateError {
      return false;
    }
  }

  void close() {
    final end = _end;
    _end = null;
    end?.call();
  }
}
