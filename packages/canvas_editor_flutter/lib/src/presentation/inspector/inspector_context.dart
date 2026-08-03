// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/inspector/inspector_context.dart

import 'package:flutter/widgets.dart';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/canvas_runtime_resources.dart';
import 'package:canvas_editor_flutter/src/editor_api.dart';
import 'package:canvas_editor_flutter/src/editor_hosts.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_fields.dart';

/// Builds the complete inspector body for the current selection.
///
/// Return null when this builder does not own the current selection and the
/// earlier builder should get an opportunity to handle it.
typedef InspectorBuilder = Widget? Function(InspectorContext context);

/// Builds one field row.
///
/// Extensions can decorate the standard field row with supplemental controls
/// without replacing field commit, debounce, or transaction behavior.
typedef InspectorFieldRowBuilder =
    Widget Function<T>(
      ElementId nodeId,
      EditorController controller,
      InspectorFieldSpec<T> spec,
    );

/// Immutable values available while building the inspector.
@immutable
class InspectorContext {
  const InspectorContext({
    required this.selectedId,
    required this.selection,
    required this.controller,
    required this.editableScene,
    required this.renderedScene,
    required this.resources,
    required this.fieldRowBuilder,
  });

  /// Selected item ID when exactly one canvas item is selected.
  ///
  /// Null means there is no single-item selection.
  final ElementId? selectedId;

  final EditorSelectionHost selection;
  final EditorController controller;

  /// Canonical scene edited by commands and field commits.
  final CanvasSceneDocument editableScene;

  /// Prepared/resolved scene currently displayed by the renderer.
  final CanvasSceneDocument renderedScene;

  final CanvasRuntimeResources resources;
  final InspectorFieldRowBuilder fieldRowBuilder;

  Node? get selectedEditableNode {
    final id = selectedId;
    return id == null ? null : findById(editableScene, id);
  }

  Node? get selectedRenderedNode {
    final id = selectedId;
    return id == null ? null : findById(renderedScene, id);
  }

  Widget fieldRow<T>(ElementId nodeId, InspectorFieldSpec<T> spec) {
    return fieldRowBuilder<T>(nodeId, controller, spec);
  }
}
