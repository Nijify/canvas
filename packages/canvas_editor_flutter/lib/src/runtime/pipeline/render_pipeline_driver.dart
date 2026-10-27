// Path: oss_packages/canvas_editor_flutter/lib/src/runtime/pipeline/render_pipeline_driver.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:canvas_core/canvas_core_runtime.dart' as rt;

/// Pure function that maps source document -> runtime scene evaluation.
typedef RenderBuildFn<TSourceDocument> =
    rt.SceneEvaluation Function(TSourceDocument sourceDocument);

/// Coordinates source-document application, deferred render scheduling, and
/// prepared scene-evaluation publication.
///
/// Source-document callbacks fire only when the source document changes.
/// Layout-only invalidations rebuild the scene evaluation without publishing a
/// source-document change.
///
/// Render builders should return a new snapshot whenever rendered output
/// changes. Returning the current evaluation instance represents no new rendered
/// value and therefore does not notify [render] listeners.
class RenderPipelineDriver<TSourceDocument> {
  RenderPipelineDriver({
    required TSourceDocument initialSourceDocument,
    required RenderBuildFn<TSourceDocument> build,
    void Function(TSourceDocument sourceDocument)? onSourceDocumentApplied,
  }) : _sourceDocument = initialSourceDocument,
       _build = build,
       _onSourceDocumentApplied = onSourceDocumentApplied {
    _render = ValueNotifier<rt.SceneEvaluation>(_build(_sourceDocument));
  }

  final RenderBuildFn<TSourceDocument> _build;
  final void Function(TSourceDocument sourceDocument)? _onSourceDocumentApplied;

  late final ValueNotifier<rt.SceneEvaluation> _render;

  ValueListenable<rt.SceneEvaluation> get render => _render;

  TSourceDocument _sourceDocument;
  TSourceDocument? _pendingSourceDocument;
  rt.SceneEvaluation? _pendingEvaluation;

  bool _frameScheduled = false;

  /// Monotonic token used to invalidate previously scheduled frame callbacks.
  int _scheduleToken = 0;

  bool _disposed = false;

  TSourceDocument get sourceDocument => _sourceDocument;

  rt.SceneEvaluation prepare(TSourceDocument document) => _build(document);

  /// Settle the previous gesture before capturing a new starting snapshot.
  void flushPending() {
    final pending = _pendingSourceDocument;
    if (pending == null || _disposed) return;
    final evaluation = _pendingEvaluation;
    _pendingEvaluation = null;
    applySourceDocument(pending, prepared: evaluation);
  }

  /// Applies a new source document immediately or through a deferred snapshot.
  void applySourceDocument(
    TSourceDocument sourceDocument, {
    bool scheduleSnapshot = false,
    rt.SceneEvaluation? prepared,
  }) {
    if (_disposed) return;

    if (scheduleSnapshot) {
      _pendingSourceDocument = sourceDocument;
      _pendingEvaluation = prepared;
      _scheduleInvalidation();
      return;
    }

    // Invalidate any previously scheduled frame callback.
    _scheduleToken += 1;
    _frameScheduled = false;
    _pendingSourceDocument = null;
    _pendingEvaluation = null;

    _applyNow(sourceDocument, prepared);
  }

  /// Schedules a render-only invalidation.
  ///
  /// This may rebuild the scene evaluation, but it does not imply that the
  /// editable/source document changed.
  void scheduleLayoutInvalidation() {
    if (_disposed) return;
    _pendingEvaluation = null;
    _scheduleInvalidation();
  }

  void _scheduleInvalidation() {
    if (_frameScheduled) return;

    _frameScheduled = true;
    final token = ++_scheduleToken;

    SchedulerBinding.instance.ensureVisualUpdate();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (_disposed) return;
      if (!_frameScheduled) return;
      if (token != _scheduleToken) return;

      _frameScheduled = false;

      final sourceDocument = _pendingSourceDocument ?? _sourceDocument;

      final prepared = _pendingEvaluation;
      _pendingSourceDocument = null;
      _pendingEvaluation = null;
      _applyNow(sourceDocument, prepared);
    });
  }

  void _applyNow(TSourceDocument sourceDocument, [rt.SceneEvaluation? prepared]) {
    final sourceChanged = sourceDocument != _sourceDocument;
    final built = prepared ?? _build(sourceDocument);

    _sourceDocument = sourceDocument;

    // Preserve publication ordering:
    // canonical source/document first, prepared render output second.
    if (sourceChanged) {
      _onSourceDocumentApplied?.call(_sourceDocument);
    }

    _render.value = built;
  }

  void dispose() {
    if (_disposed) return;

    _disposed = true;
    _frameScheduled = false;
    _pendingSourceDocument = null;
    _pendingEvaluation = null;
    _scheduleToken += 1;

    _render.dispose();
  }
}
