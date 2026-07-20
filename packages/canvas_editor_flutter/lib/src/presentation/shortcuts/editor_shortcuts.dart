// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/shortcuts/editor_shortcuts.dart

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart'
    show BuildContext, ShortcutActivator, SingleActivator, VoidCallback;
import 'package:provider/provider.dart';

import 'package:canvas_editor_flutter/src/editor_api.dart'
    show EditorController;
import 'package:canvas_editor_flutter/src/editor_edits.dart' show EditorEdits;
import 'package:canvas_editor_flutter/src/interaction/selection_controllers.dart'
    show SelectionController;

Map<ShortcutActivator, VoidCallback> buildEditorShortcutBindings(
  BuildContext context,
) {
  final controller = context.read<EditorController>();
  final selection = context.read<SelectionController>();

  void bringForward() {
    final id = selection.firstId;
    if (id == null) return;

    controller.applyEdit(EditorEdits.bringForward(id));
  }

  void sendBackward() {
    final id = selection.firstId;
    if (id == null) return;

    controller.applyEdit(EditorEdits.sendBackward(id));
  }

  void bringToFront() {
    final id = selection.firstId;
    if (id == null) return;

    controller.applyEdit(EditorEdits.bringToFront(id));
  }

  void sendToBack() {
    final id = selection.firstId;
    if (id == null) return;

    controller.applyEdit(EditorEdits.sendToBack(id));
  }

  return {
    // Undo
    const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): controller.undo,
    const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
        controller.undo,

    // Redo
    const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
        controller.redo,
    const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
        controller.redo,

    // Arrange
    const SingleActivator(LogicalKeyboardKey.bracketRight, meta: true):
        bringForward,
    const SingleActivator(LogicalKeyboardKey.bracketRight, control: true):
        bringForward,

    const SingleActivator(LogicalKeyboardKey.bracketLeft, meta: true):
        sendBackward,
    const SingleActivator(LogicalKeyboardKey.bracketLeft, control: true):
        sendBackward,

    const SingleActivator(
      LogicalKeyboardKey.bracketRight,
      meta: true,
      shift: true,
    ): bringToFront,
    const SingleActivator(
      LogicalKeyboardKey.bracketRight,
      control: true,
      shift: true,
    ): bringToFront,

    const SingleActivator(
      LogicalKeyboardKey.bracketLeft,
      meta: true,
      shift: true,
    ): sendToBack,
    const SingleActivator(
      LogicalKeyboardKey.bracketLeft,
      control: true,
      shift: true,
    ): sendToBack,
  };
}
