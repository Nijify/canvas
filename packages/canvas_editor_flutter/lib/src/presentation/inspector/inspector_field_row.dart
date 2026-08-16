// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/inspector/inspector_field_row.dart

import 'dart:async';

import 'package:canvas_core/canvas_core_runtime.dart' show ElementId;
import 'package:canvas_editor_flutter/src/editor_api.dart'
    show EditorController;
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_fields.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_ui.dart';
import 'package:flutter/material.dart';

class InspectorFieldRow<T> extends StatefulWidget {
  const InspectorFieldRow({
    super.key,
    required this.nodeId,
    required this.controller,
    required this.spec,
  });

  final ElementId nodeId;
  final EditorController controller;
  final InspectorFieldSpec<T> spec;

  @override
  State<InspectorFieldRow<T>> createState() => _InspectorFieldRowState<T>();
}

class _InspectorFieldRowState<T> extends State<InspectorFieldRow<T>> {
  _Debouncer? _debouncer;
  VoidCallback? _endSession;

  bool _closingScheduled = false;

  @override
  void initState() {
    super.initState();
    if (widget.spec.commitMode == CommitMode.debounced) {
      _debouncer = _Debouncer(widget.spec.debounce);
    }
  }

  @override
  void didUpdateWidget(covariant InspectorFieldRow<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final specChanged =
        oldWidget.spec.fieldKey != widget.spec.fieldKey ||
        oldWidget.spec.commitMode != widget.spec.commitMode ||
        oldWidget.spec.debounce != widget.spec.debounce;

    final identityChanged =
        oldWidget.nodeId != widget.nodeId ||
        oldWidget.controller != widget.controller;

    if (specChanged || identityChanged) {
      _closeEditSession();

      _debouncer?.dispose();
      _debouncer = null;
      if (widget.spec.commitMode == CommitMode.debounced) {
        _debouncer = _Debouncer(widget.spec.debounce);
      }
    }
  }

  @override
  void dispose() {
    _flushDebounceAndEnd();
    _debouncer?.dispose();
    super.dispose();
  }

  void _openEditSession() {
    _endSession ??= widget.controller.beginEditSession();
  }

  void _closeEditSession() {
    _debouncer?.cancel();

    final endSession = _endSession;
    if (endSession == null) return;

    _endSession = null;
    endSession();
  }

  void _scheduleCloseIfNeeded(bool enabledNow) {
    if (enabledNow) return;
    if (_endSession == null) return;
    if (_closingScheduled) return;

    _closingScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _closingScheduled = false;
      if (!mounted) return;

      _closeEditSession();
    });
  }

  void _commitImmediate(T next) {
    widget.controller.commitField<T>(widget.nodeId, widget.spec.fieldKey, next);
  }

  void _commitDebounced(T next) {
    _openEditSession();

    widget.controller.commitField<T>(widget.nodeId, widget.spec.fieldKey, next);

    _debouncer!.run(() {
      if (!mounted) return;
      _closeEditSession();
    });
  }

  void _flushDebounceAndEnd() {
    _debouncer?.flush();

    if (_endSession != null) {
      _closeEditSession();
    }
  }

  void _dragBegin() => _openEditSession();

  void _dragEnd() => _flushDebounceAndEnd();

  void _commitDrag(T next) {
    _openEditSession();
    widget.controller.commitField<T>(widget.nodeId, widget.spec.fieldKey, next);
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.controller.getField<T>(
      widget.nodeId,
      widget.spec.fieldKey,
    );

    final disabledHint = st.disabledReason;
    final enabled = disabledHint == null;

    _scheduleCloseIfNeeded(enabled);

    void Function()? flushCb() {
      return switch (widget.spec.commitMode) {
        CommitMode.debounced => _flushDebounceAndEnd,
        CommitMode.dragTxn => _dragEnd,
        CommitMode.immediate => null,
      };
    }

    void onCommit(T next) {
      if (!enabled) return;

      switch (widget.spec.commitMode) {
        case CommitMode.immediate:
          _commitImmediate(next);
          break;
        case CommitMode.debounced:
          _commitDebounced(next);
          break;
        case CommitMode.dragTxn:
          _commitDrag(next);
          break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.spec.control(
          context,
          enabled: enabled,
          value: st.value,
          commit: onCommit,
          begin: widget.spec.commitMode == CommitMode.dragTxn
              ? _dragBegin
              : null,
          end: widget.spec.commitMode == CommitMode.dragTxn ? _dragEnd : null,
          flush: flushCb(),
        ),

        if (disabledHint != null) ...[
          const SizedBox(height: 6),
          HintText(disabledHint),
        ],
      ],
    );
  }
}

class _Debouncer {
  _Debouncer(this.delay);

  final Duration delay;
  Timer? _timer;
  void Function()? _pending;

  bool get hasPending => _timer != null;

  void run(void Function() action) {
    _pending = action;
    _timer?.cancel();
    _timer = Timer(delay, () {
      _timer = null;
      final fn = _pending;
      _pending = null;
      fn?.call();
    });
  }

  void flush() {
    _timer?.cancel();
    _timer = null;
    final fn = _pending;
    _pending = null;
    fn?.call();
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
  }

  void dispose() => cancel();
}
