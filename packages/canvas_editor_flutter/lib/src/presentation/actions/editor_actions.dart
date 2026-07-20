// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/actions/editor_actions.dart

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:canvas_editor_flutter/src/canvas_runtime_resources.dart'
    show CanvasRuntimeResources;
import 'package:canvas_core/canvas_core_runtime.dart'
    show CanvasSceneDocument, Node;
import 'package:canvas_editor_flutter/src/editor_api.dart'
    show EditorController;
import 'package:canvas_editor_flutter/src/editor_edits.dart' show EditorEdits;
import 'package:canvas_editor_flutter/src/editor_hosts.dart'
    show EditorSelectionHost;

/// Action-scoped presentation feedback supplied by the editor surface.
///
/// Editor actions may request busy-state UI or display a user-facing message,
/// but do not know how the surrounding editor shell implements either behavior.
abstract class UiFeedback {
  void showSpinner();
  void hideSpinner();
  void toast(String msg);
}

@immutable
final class EditorActionId {
  const EditorActionId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EditorActionId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

@immutable
final class EditorToolbarSection {
  const EditorToolbarSection(this.value, {this.label, this.icon});

  final String value;

  /// Optional display label for sections contributed by extensions.
  final String? label;

  /// Optional display icon for sections contributed by extensions.
  final IconData? icon;

  // Built-in editor sections.
  static const undoRedo = EditorToolbarSection('undoRedo');
  static const edit = EditorToolbarSection(
    'edit',
    label: 'Edit',
    icon: Icons.edit,
  );
  static const arrange = EditorToolbarSection(
    'arrange',
    label: 'Arrange',
    icon: Icons.layers,
  );
  static const export = EditorToolbarSection('export');
  static const add = EditorToolbarSection('add', label: 'Add', icon: Icons.add);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorToolbarSection && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

@immutable
class EditorToolbarState {
  const EditorToolbarState({
    required this.compact,
    required this.canUndo,
    required this.canRedo,
    required this.hasSelection,
  });
  final bool compact;
  final bool canUndo;
  final bool canRedo;
  final bool hasSelection;
}

typedef EditorActionLabelBuilder = String Function(EditorToolbarState state);
typedef EditorActionIconBuilder = IconData Function(EditorToolbarState state);
typedef EditorActionPredicate = bool Function(EditorToolbarState state);
typedef EditorActionInvoke = FutureOr<void> Function(EditorActionContext ctx);

@immutable
class EditorActionContext {
  const EditorActionContext({
    required this.buildContext,
    required this.resources,
    required this.ui,
    required this.controller,
    required this.selection,
  });

  final BuildContext buildContext;
  final CanvasRuntimeResources resources;
  final UiFeedback ui;

  /// Editor state + document mutation capability.
  ///
  /// Actions should prefer the semantic helpers on this context where they
  /// exist instead of reaching into low-level controller state directly.
  final EditorController controller;

  /// Selection capability used by action helpers such as add-and-select.
  final EditorSelectionHost selection;

  /// Prepared/effective scene used by visual-output paths:
  /// canvas paint, hit testing, snapping, and PNG export.
  CanvasSceneDocument get renderScene => controller.render.value.scene;

  /// Canonical editable/base scene used by persistence, scene JSON export,
  /// and the object tree.
  CanvasSceneDocument get editableScene => controller.document.value;

  void undo() => controller.undo();

  void redo() => controller.redo();

  void duplicateSelection() {
    final id = selection.firstId;
    if (id == null) return;

    final newId = controller.applyEdit(EditorEdits.duplicateSubtree(id));

    if (newId != null) {
      selection.selectItems([newId], additive: false);
    }
  }

  void deleteSelection() {
    final id = selection.firstId;
    if (id == null) return;

    controller.applyEdit(EditorEdits.deleteSubtree(id));

    selection.clearSelection();
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

  String addNode(Node node) {
    return controller.applyEdit(EditorEdits.addNode(node)) ?? node.id;
  }

  String addNodeAndSelect(Node node) {
    final newId = addNode(node);
    selection.selectItems([newId], additive: false);
    return newId;
  }

  void selectItems(Iterable<String> ids, {bool additive = false}) {
    selection.selectItems(ids, additive: additive);
  }

  void clearSelection() {
    selection.clearSelection();
  }
}

@immutable
class EditorActionSpec {
  const EditorActionSpec({
    required this.id,
    required this.section,
    required this.labelBuilder,
    required this.iconBuilder,
    required this.isEnabled,
    required this.isVisible,
    required this.invoke,
    this.priority = 0,
    this.menuGroup,
  });

  final EditorActionId id;
  final EditorToolbarSection section;
  final EditorActionLabelBuilder labelBuilder;
  final EditorActionIconBuilder iconBuilder;
  final EditorActionPredicate isEnabled;
  final EditorActionPredicate isVisible;
  final EditorActionInvoke invoke;

  /// Higher priority appears earlier within a toolbar/menu section.
  final int priority;

  /// Optional subgroup label inside section menus.
  ///
  /// Example:
  /// - Add -> Shapes
  ///
  /// This is display/menu metadata only. The editor does not interpret
  /// extension-specific action groups.
  /// UI may ignore this.
  final String? menuGroup;
}

class EditorActionDispatcher {
  const EditorActionDispatcher({required this.actions, this.context});

  /// Nullable only so tests/goldens can render toolbar UI without constructing
  /// the full editor runtime context. Production editor shells always provide it.
  final EditorActionContext? context;
  final Map<EditorActionId, EditorActionSpec> actions;

  bool canInvoke(EditorActionId id) => actions.containsKey(id);

  void invoke(EditorActionId id) {
    final action = actions[id];
    final ctx = context;
    if (action == null || ctx == null) return;

    unawaited(Future<void>.sync(() => action.invoke(ctx)));
  }
}

abstract final class EditorActionIds {
  static const undo = EditorActionId('editor.undo');
  static const redo = EditorActionId('editor.redo');

  static const duplicate = EditorActionId('editor.duplicate');
  static const duplicateGroup = EditorActionId('editor.duplicateGroup');
  static const deleteSelection = EditorActionId('editor.deleteSelection');
  static const deleteGroup = EditorActionId('editor.deleteGroup');

  static const bringToFront = EditorActionId('editor.bringToFront');
  static const sendToBack = EditorActionId('editor.sendToBack');
  static const bringForward = EditorActionId('editor.bringForward');
  static const sendBackward = EditorActionId('editor.sendBackward');

  static const addText = EditorActionId('editor.add.text');
  static const addImage = EditorActionId('editor.add.image');
  static const addRect = EditorActionId('editor.add.rect');
  static const addRoundRect = EditorActionId('editor.add.roundRect');
  static const addPill = EditorActionId('editor.add.pill');
  static const addCircle = EditorActionId('editor.add.circle');
  static const addEllipse = EditorActionId('editor.add.ellipse');
  static const addUnderline = EditorActionId('editor.add.underline');
  static const addPolygon = EditorActionId('editor.add.polygon');
  static const addStar = EditorActionId('editor.add.star');

  static const sharePng = EditorActionId('export.sharePng');
  static const savePng = EditorActionId('export.savePng');

  static const copySceneJson = EditorActionId('export.copySceneJson');
  static const saveSceneJson = EditorActionId('export.saveSceneJson');
}
