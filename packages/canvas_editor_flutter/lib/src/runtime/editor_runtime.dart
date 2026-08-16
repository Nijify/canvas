// Path: oss_packages/canvas_editor_flutter/lib/src/runtime/editor_runtime.dart

//
// Shared editor document/render state.
//
// - Canvas editor is canonical-document agnostic.
// - Persistent scene mutations enter through EditorEdit.
// - Field codecs translate typed field commits into EditorEdit values.
// - Custom document behavior is injected through a canonical adapter.
// - Ephemeral transform updates remain runtime-owned for gesture batching.
import 'dart:async';

import 'package:canvas_core/canvas_core_runtime.dart' as rt;
import 'package:canvas_editor_flutter/src/runtime/history/txn_history_manager.dart';
import 'package:canvas_editor_flutter/src/runtime/pipeline/render_pipeline_driver.dart';
import 'package:canvas_editor_flutter/src/editor_api.dart';
import 'package:canvas_editor_flutter/src/editor_field_codecs.dart';
import 'package:canvas_editor_flutter/src/editor_hosts.dart';
import 'package:flutter/foundation.dart';

final class EditorRuntime<TSourceDocument>
    implements EditorController, EditorDocumentHost<TSourceDocument> {
  EditorRuntime({
    required TSourceDocument initial,
    required EditorDocumentAdapter<TSourceDocument> adapter,
    required this.renderPipeline,
    required this.imageIntrinsics,
    Object? initialContext,
    rt.ContentBoundsSpec? contentBounds,

    /// Optional scene transformation applied after adapter resolution and
    /// before the runtime pipeline builds the render snapshot.
    this.scenePreparer,

    Map<rt.CanvasFieldKey, FieldCodec> extraFieldCodecs =
        const <rt.CanvasFieldKey, FieldCodec>{},

    int maxHistory = 100,
  }) : _adapter = adapter,
       _ctx = initialContext,
       _extraFieldCodecs = Map<rt.CanvasFieldKey, FieldCodec>.unmodifiable(
         extraFieldCodecs,
       ) {
    _sourceListenable = ValueNotifier<TSourceDocument>(initial);

    _history = TxnHistoryManager<TSourceDocument>(
      initial: initial,
      maxHistory: maxHistory,
      onCapabilitiesChanged: (canUndo, canRedo) {
        if (_canUndoListenable.value != canUndo) {
          _canUndoListenable.value = canUndo;
        }

        if (_canRedoListenable.value != canRedo) {
          _canRedoListenable.value = canRedo;
        }
      },
    );

    _documentListenable = ValueNotifier<rt.CanvasSceneDocument>(
      _adapter.getBase(initial),
    );

    _pipeline = RenderPipelineDriver<TSourceDocument>(
      initialSourceDocument: initial,
      build: (canonical) {
        final resolvedScene = _adapter.resolve(canonical, _ctx);

        final preparedScene =
            scenePreparer?.call(resolvedScene, renderPipeline.services) ??
            resolvedScene;

        return renderPipeline.build(
          preparedScene,
          contentBounds: contentBounds,
        );
      },
      onSourceDocumentApplied: (canonical) {
        _documentListenable.value = _adapter.getBase(canonical);

        if (!identical(_sourceListenable.value, canonical) &&
            _sourceListenable.value != canonical) {
          _sourceListenable.value = canonical;
        }
      },
    );

    _imgSub = imageIntrinsics?.onIntrinsicUpdated.listen((_) {
      _pipeline.scheduleLayoutInvalidation();
    });
  }

  // --------------------------------------------------------------------------
  // Deps
  // --------------------------------------------------------------------------

  final rt.CanvasRenderPipeline renderPipeline;
  final rt.ImageIntrinsics? imageIntrinsics;
  final EditorDocumentAdapter<TSourceDocument> _adapter;

  final rt.ScenePreparer? scenePreparer;

  StreamSubscription<rt.ElementId>? _imgSub;

  Object? _ctx;

  final Map<rt.CanvasFieldKey, FieldCodec> _extraFieldCodecs;

  VoidCallback? _endActiveSession;

  bool _disposed = false;

  // --------------------------------------------------------------------------
  // Shared components
  // --------------------------------------------------------------------------

  late final TxnHistoryManager<TSourceDocument> _history;
  late final RenderPipelineDriver<TSourceDocument> _pipeline;

  // Render output surface
  @override
  ValueListenable<rt.RenderSnapshot> get render => _pipeline.render;

  // Canonical/base scene surface
  late final ValueNotifier<rt.CanvasSceneDocument> _documentListenable;

  @override
  ValueListenable<rt.CanvasSceneDocument> get document => _documentListenable;

  late final ValueNotifier<TSourceDocument> _sourceListenable;

  @override
  ValueListenable<TSourceDocument> get source => _sourceListenable;

  @override
  TSourceDocument get sourceDocument => _sourceListenable.value;

  rt.CanvasSceneDocument get baseDocument =>
      _adapter.getBase(_sourceListenable.value);

  /// Latest canonical state, including in-flight ephemeral gesture updates.
  TSourceDocument get _presentSourceDocument => _history.present;

  // --------------------------------------------------------------------------
  // Undo/redo surface
  // --------------------------------------------------------------------------

  final ValueNotifier<bool> _canUndoListenable = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _canRedoListenable = ValueNotifier<bool>(false);

  @override
  ValueListenable<bool> get canUndo => _canUndoListenable;

  @override
  ValueListenable<bool> get canRedo => _canRedoListenable;

  // --------------------------------------------------------------------------
  // Lifecycle
  // --------------------------------------------------------------------------

  void scheduleLayoutInvalidation() => _pipeline.scheduleLayoutInvalidation();

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _endActiveSession?.call();

    final imageSubscription = _imgSub;
    _imgSub = null;
    unawaited(imageSubscription?.cancel());

    _pipeline.dispose();
    _canUndoListenable.dispose();
    _canRedoListenable.dispose();
    _documentListenable.dispose();
    _sourceListenable.dispose();
  }

  // --------------------------------------------------------------------------
  // Undo/redo
  // --------------------------------------------------------------------------

  @override
  void undo() {
    if (!_history.canUndo) return;

    _history.undo();
    _pipeline.applySourceDocument(_history.present);
  }

  @override
  void redo() {
    if (!_history.canRedo) return;

    _history.redo();
    _pipeline.applySourceDocument(_history.present);
  }

  // --------------------------------------------------------------------------
  // Edit sessions (gesture batching)
  // --------------------------------------------------------------------------

  @override
  VoidCallback beginEditSession() {
    final active = _endActiveSession;
    if (active != null) return active;

    _history.beginTransaction();

    late final VoidCallback endSession;

    endSession = () {
      if (!identical(_endActiveSession, endSession)) return;

      _endActiveSession = null;
      _history.endTransaction();
    };

    _endActiveSession = endSession;
    return endSession;
  }

  // --------------------------------------------------------------------------
  // Internal write helpers
  // --------------------------------------------------------------------------

  void _commit(TSourceDocument Function(TSourceDocument) operation) {
    final previous = _history.present;
    final next = _history.applyOp(operation, pushHistory: true);

    if (identical(next, previous) || next == previous) return;

    _pipeline.applySourceDocument(next);
  }

  /// Public canonical mutation seam for domain-specific extensions.
  /// Shared/base editor code should prefer [applyEdit] for reusable scene edits.
  @override
  void updateSourceDocument(
    TSourceDocument Function(TSourceDocument document) update,
  ) {
    _commit(update);
  }

  void _applyEphemeral(TSourceDocument next) {
    assert(
      _endActiveSession != null,
      'Ephemeral updates must run inside an edit session.',
    );

    final previous = _history.present;
    final current = _history.applyOp((_) => next, pushHistory: false);

    if (identical(current, previous) || current == previous) {
      return;
    }

    _pipeline.applySourceDocument(current, scheduleSnapshot: true);
  }

  @override
  void setResolveContext(Object? context) {
    _ctx = context;
    _pipeline.scheduleLayoutInvalidation();
  }

  TSourceDocument _replaceBase(
    TSourceDocument document,
    rt.CanvasSceneDocument nextBase,
  ) {
    final currentBase = _adapter.getBase(document);

    if (identical(nextBase, currentBase) || nextBase == currentBase) {
      return document;
    }

    return _adapter.replaceBase(document, nextBase);
  }

  /// Applies a reusable base-scene edit to the canonical source document.
  ///
  /// This is the preferred path for generic scene-tree operations because it
  /// centralizes:
  /// - history commit
  /// - base-scene replacement
  /// - adapter cleanup/remap hooks
  /// - render invalidation
  @override
  rt.ElementId? applyEdit(EditorEdit edit) {
    rt.ElementId? primaryId;

    _commit((document) {
      final base = _adapter.getBase(document);
      final result = edit(base);

      primaryId = result.primaryId;

      final sceneUnchanged =
          identical(result.scene, base) || result.scene == base;

      if (sceneUnchanged &&
          result.deletedIds.isEmpty &&
          result.duplicatedIds.isEmpty) {
        return document;
      }

      var next = _replaceBase(document, result.scene);

      if (result.deletedIds.isNotEmpty) {
        next = _adapter.onDeleteSubtree(next, result.deletedIds);
      }

      if (result.duplicatedIds.isNotEmpty) {
        next = _adapter.onDuplicateSubtree(next, result.duplicatedIds);
      }

      return next;
    });

    return primaryId;
  }

  // ==========================================================================
  // TRANSFORMS (ephemeral updates write to base; commit writes to history)
  // ==========================================================================

  @override
  void updateDragMany(Set<rt.ElementId> ids, rt.Vec2 delta) {
    if (ids.isEmpty) return;

    final presentSourceDocument = _presentSourceDocument;
    var base = _adapter.getBase(presentSourceDocument);

    for (final id in ids) {
      base = rt.SceneTreeOps.translate(base, id, delta);
    }

    _applyEphemeral(_replaceBase(presentSourceDocument, base));
  }

  @override
  void updateRotate(rt.ElementId id, double deltaRad) {
    final presentSourceDocument = _presentSourceDocument;
    final presentBase = _adapter.getBase(presentSourceDocument);

    final base = rt.SceneTreeOps.rotate(presentBase, id, deltaRad);
    _applyEphemeral(_replaceBase(presentSourceDocument, base));
  }

  @override
  void updateUniformScaleAround(
    rt.ElementId id,
    rt.Vec2 anchorParent,
    double mul,
  ) {
    final presentSourceDocument = _presentSourceDocument;
    final presentBase = _adapter.getBase(presentSourceDocument);

    final n = rt.findById(presentBase, id);
    if (n == null) return;

    final xf = n.xf;
    final pos = xf.position;

    final nextPos = anchorParent + (pos - anchorParent) * mul;
    final s = xf.scale;
    final nextScale = rt.Vec2(s.x * mul, s.y * mul);

    final nextXf = xf.copyWith(position: nextPos, scale: nextScale);
    final base = rt.SceneTreeOps.replaceNodeXf(presentBase, id, nextXf);
    _applyEphemeral(_replaceBase(presentSourceDocument, base));
  }

  T _readEffectiveOrBase<T>({
    required Object? effective,
    required Object? base,
    required T Function(Object node) read,
    required T fallback,
  }) {
    if (effective != null) {
      try {
        return read(effective);
      } catch (_) {}
    }

    if (base != null) {
      try {
        return read(base);
      } catch (_) {}
    }

    return fallback;
  }

  String? _fieldEditDisabledReason(
    TSourceDocument document,
    rt.ElementId nodeId,
    rt.CanvasFieldKey fieldKey,
  ) {
    final reason = _adapter.fieldEditDisabledReason(document, nodeId, fieldKey);

    if (reason == null) return null;

    assert(
      reason.trim().isNotEmpty,
      'EditorDocumentAdapter.fieldEditDisabledReason must return null '
      'or a non-empty reason.',
    );

    // Treat an invalid empty reason as no denial in release builds rather than
    // disabling a field without a meaningful explanation.
    return reason.trim().isEmpty ? null : reason;
  }

  @override
  FieldState<T> getField<T>(rt.ElementId nodeId, rt.CanvasFieldKey fieldKey) {
    final codec = FieldCatalog.of(fieldKey, extra: _extraFieldCodecs);
    final sceneNow = render.value.scene;

    if (nodeId == kSceneFieldsId) {
      final reader = codec.readScene;

      if (reader == null) {
        return FieldState<T>(
          codec.fallback as T,
          disabledReason: 'Invalid scene field',
        );
      }

      final presentDocument = _presentSourceDocument;

      return FieldState<T>(
        reader(sceneNow) as T,
        disabledReason: _fieldEditDisabledReason(
          presentDocument,
          nodeId,
          fieldKey,
        ),
      );
    }

    if (codec.isSceneOnly) {
      return FieldState<T>(
        codec.fallback as T,
        disabledReason: 'Scene-only field',
      );
    }

    final readNode = codec.readNode;

    if (readNode == null) {
      return FieldState<T>(
        codec.fallback as T,
        disabledReason: 'Unreadable field',
      );
    }

    final presentDocument = _presentSourceDocument;
    final presentBase = _adapter.getBase(presentDocument);

    final effective = rt.findById(sceneNow, nodeId);
    final base = rt.findById(presentBase, nodeId);

    final value = _readEffectiveOrBase<Object>(
      effective: effective,
      base: base,
      fallback: codec.fallback,
      read: (node) => readNode(node as rt.Node),
    );

    if (base == null) {
      return FieldState<T>(
        value as T,
        disabledReason: 'Missing canonical node',
      );
    }

    return FieldState<T>(
      value as T,
      disabledReason: _fieldEditDisabledReason(
        presentDocument,
        nodeId,
        fieldKey,
      ),
    );
  }

  @override
  void commitField<T>(
    rt.ElementId nodeId,
    rt.CanvasFieldKey fieldKey,
    T value,
  ) {
    final codec = FieldCatalog.of(fieldKey, extra: _extraFieldCodecs);

    if (nodeId == kSceneFieldsId) {
      if (!codec.isSceneOnly) return;

      final presentDocument = _presentSourceDocument;

      if (_fieldEditDisabledReason(presentDocument, nodeId, fieldKey) != null) {
        return;
      }

      codec.commit(this, nodeId, value as Object);
      return;
    }

    if (codec.isSceneOnly) return;

    final presentDocument = _presentSourceDocument;
    final presentBase = _adapter.getBase(presentDocument);

    if (rt.findById(presentBase, nodeId) == null) return;

    if (_fieldEditDisabledReason(presentDocument, nodeId, fieldKey) != null) {
      return;
    }

    codec.commit(this, nodeId, value as Object);
  }
}
