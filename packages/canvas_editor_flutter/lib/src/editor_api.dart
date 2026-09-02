// Path: oss_packages/canvas_editor_flutter/lib/src/editor_api.dart
// ignore_for_file: constant_identifier_names
import 'package:flutter/foundation.dart';
import 'package:canvas_core/canvas_core_runtime.dart' as rt;

/// Shared editor contracts/types that are layer-neutral.
///
/// Safe for:
/// - application
/// - presentation
/// - extension packages
///
/// Important:
/// - this file must not import presentation-layer code
/// - higher-level widgets/controllers can depend on this
/// - application code can also depend on this

@immutable
final class SelectionState {
  const SelectionState.none() : ids = const <String>{};

  factory SelectionState.items(Iterable<String> ids) {
    final normalized = Set<String>.unmodifiable(ids);

    return normalized.isEmpty
        ? const SelectionState.none()
        : SelectionState._(normalized);
  }

  const SelectionState._(this.ids);

  final Set<String> ids;

  bool get isEmpty => ids.isEmpty;
  bool get hasItems => ids.isNotEmpty;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SelectionState && setEquals(ids, other.ids);
  }

  @override
  int get hashCode => Object.hashAllUnordered(ids);
}

/// Pseudo node id used to expose scene-level inspector fields (background, etc)
/// through the unified Field API.
const rt.ElementId kSceneFieldsId = '__scene__';

/// Strategy for adapting a host-owned canonical document to the editor.
///
/// The editor mutates the canonical editable/base [rt.CanvasSceneDocument].
/// Implementations translate that scene back into [TSourceDocument] and may
/// preserve or update host-specific canonical metadata.
abstract class EditorDocumentAdapter<TSourceDocument> {
  const EditorDocumentAdapter();

  /// Returns the canonical runtime/base scene that shared mutations edit.
  rt.CanvasSceneDocument getBase(TSourceDocument doc);

  /// Replaces the canonical runtime/base scene after shared mutations.
  TSourceDocument replaceBase(TSourceDocument doc, rt.CanvasSceneDocument base);

  /// Resolves the canonical document into the runtime scene used for rendering.
  rt.CanvasSceneDocument resolve(TSourceDocument doc, Object? ctx);

  /// Returns why a registered literal field cannot currently be edited.
  ///
  /// This is evaluated against the current canonical [TSourceDocument].
  /// Return null to allow the literal commit, or a non-empty user-facing
  /// reason to deny it.
  ///
  /// [nodeId] is [kSceneFieldsId] for registered scene-level fields.
  ///
  /// This hook governs registered literal edits through
  /// [EditorController.commitField] only. It is not an authorization boundary
  /// and does not restrict structural [EditorEdit] operations or
  /// source-document-level mutations.
  ///
  /// Implementations must be synchronous, deterministic, side-effect-free,
  /// and fast because this may be evaluated during UI builds and commits.
  String? fieldEditDisabledReason(
    TSourceDocument document,
    rt.ElementId nodeId,
    rt.CanvasFieldKey fieldKey,
  ) => null;

  /// Optional hook for canonical cleanup after subtree deletion.
  TSourceDocument onDeleteSubtree(
    TSourceDocument doc,
    Set<rt.ElementId> deletedIds,
  ) => doc;

  /// Optional hook for canonical remapping after subtree duplication.
  TSourceDocument onDuplicateSubtree(
    TSourceDocument doc,
    Map<rt.ElementId, rt.ElementId> idMap,
  ) => doc;
}

/// Identity adapter for a plain [rt.CanvasSceneDocument].
///
/// Shared mutations edit the scene directly and rendering needs no resolution.
class CanvasSceneDocumentAdapter
    extends EditorDocumentAdapter<rt.CanvasSceneDocument> {
  const CanvasSceneDocumentAdapter();

  @override
  rt.CanvasSceneDocument getBase(rt.CanvasSceneDocument doc) => doc;

  @override
  rt.CanvasSceneDocument replaceBase(
    rt.CanvasSceneDocument doc,
    rt.CanvasSceneDocument base,
  ) => base;

  @override
  rt.CanvasSceneDocument resolve(rt.CanvasSceneDocument doc, Object? ctx) =>
      doc;
}

/// Typed state for a single inspector field.
///
/// A null [disabledReason] means the field can be edited.
final class FieldState<T> {
  const FieldState(this.value, {this.disabledReason});

  final T value;
  final String? disabledReason;
}

/// A reusable canonical scene edit.
///
/// The function transforms one editable base scene into an [EditorEditResult].
/// The editor runtime remains responsible for history, document-adapter hooks,
/// and render publication.
typedef EditorEdit = EditorEditResult Function(rt.CanvasSceneDocument scene);

/// Result of applying an [EditorEdit] to a base scene.
///
/// [primaryId] is useful for follow-up selection, especially add/duplicate.
/// [deletedIds] and [duplicatedIds] let document adapters clean up or remap
/// app-specific canonical data.
@immutable
class EditorEditResult {
  const EditorEditResult({
    required this.scene,
    this.primaryId,
    this.deletedIds = const <rt.ElementId>{},
    this.duplicatedIds = const <rt.ElementId, rt.ElementId>{},
  });

  final rt.CanvasSceneDocument scene;
  final rt.ElementId? primaryId;
  final Set<rt.ElementId> deletedIds;
  final Map<rt.ElementId, rt.ElementId> duplicatedIds;
}

/// UI/controller boundary for the editor.
///
/// This is the shared editor-facing API consumed by:
/// - widgets/shells
/// - application-backed controller implementations
/// - extension packages
abstract class EditorController {
  /// Latest prepared/effective render output.
  ///
  /// This may contain a resolved or otherwise prepared scene that differs from
  /// the canonical editable document.
  ValueListenable<rt.RenderSnapshot> get render;

  /// Latest canonical editable base scene.
  ///
  /// Persistence, object-tree UI, and canonical editing decisions should read
  /// this value rather than [render].
  ValueListenable<rt.CanvasSceneDocument> get document;

  /// Resolves the current source document for authoritative output.
  ///
  /// This applies the current [EditorDocumentAdapter.resolve] semantics using the
  /// editor's current resolve context.
  ///
  /// The returned scene is resolved but deliberately unprepared. Final-output
  /// renderers own any [rt.ScenePreparer] invocation.
  rt.CanvasSceneDocument resolveSceneForOutput();

  // ---- Undo-redo ----
  ValueListenable<bool> get canUndo;
  ValueListenable<bool> get canRedo;

  /// Opens a session that coalesces repeated mutations into one undo entry.
  ///
  /// Returns an idempotent callback that closes the active session.
  VoidCallback beginEditSession();

  // ---- Commands ----
  void undo();
  void redo();

  // ---- Ephemeral transforms ----
  void updateDragMany(Set<rt.ElementId> ids, rt.Vec2 delta);
  void updateRotate(rt.ElementId id, double deltaRad);

  /// Scale around an anchor point expressed in the node's parent space.
  void updateUniformScaleAround(
    rt.ElementId id,
    rt.Vec2 anchorParent,
    double mul,
  );

  // ---- Persistent edit pipeline ----

  /// Executes a persistent canonical scene edit.
  ///
  /// Use this directly for structural, multi-node, or custom operations that are
  /// not represented by a [rt.CanvasFieldKey]. UI editing a registered field
  /// should use [commitField] so that its `FieldCodec` policy is not bypassed.
  rt.ElementId? applyEdit(EditorEdit edit);

  // ---- Inspector Field API ----

  /// Reads the effective value of a registered field.
  ///
  /// The value may come from the resolved/rendered scene even though commits are
  /// applied to the canonical document.
  FieldState<T> getField<T>(rt.ElementId nodeId, rt.CanvasFieldKey fieldKey);

  /// Commits a literal value for a registered field.
  ///
  /// The field's `FieldCodec` owns field-specific normalization and translation
  /// into an [EditorEdit]. The current [EditorDocumentAdapter] may additionally
  /// deny the literal edit based on canonical source-document state.
  ///
  /// Invalid, stale, or source-document-denied commit targets are ignored
  /// safely.
  void commitField<T>(rt.ElementId nodeId, rt.CanvasFieldKey fieldKey, T value);

  /// Lifecycle hook for implementations that hold subscriptions.
  void dispose();
}
