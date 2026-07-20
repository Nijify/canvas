// Path: oss_packages/canvas_editor_flutter/lib/src/runtime/history/txn_history_manager.dart
// New file: shared/canvas_editor_flutter/lib/src/application/history/txn_history_manager.dart

import 'package:canvas_core/canvas_core_editor.dart' show History;

/// Shared undo/redo + transaction manager for canonical documents.
///
/// Responsibilities:
/// - Owns `History<T>`
/// - Exposes canUndo/canRedo/present
/// - Provides transaction semantics (begin/end)
/// - Provides applyOp(...) that respects transactions + pushHistory
class TxnHistoryManager<T> {
  TxnHistoryManager({
    required T initial,
    required int maxHistory,
    required void Function(bool canUndo, bool canRedo) onCapabilitiesChanged,
  }) : _hist = History<T>(initial, limit: maxHistory),
       _onCapabilitiesChanged = onCapabilitiesChanged {
    _present = _hist.present;
    _sync();
  }

  final void Function(bool canUndo, bool canRedo) _onCapabilitiesChanged;

  History<T> _hist;
  late T _present;

  bool _inTxn = false;
  T? _txnStart;
  T? _txnLatest;

  bool get canUndo => _hist.canUndo;
  bool get canRedo => _hist.canRedo;

  /// Current canonical doc (outside txn this is History.present).
  T get present => _inTxn ? (_txnLatest ?? _present) : _present;

  void _sync() {
    _onCapabilitiesChanged(_hist.canUndo, _hist.canRedo);
  }

  void undo() {
    if (_inTxn) {
      assert(() {
        throw StateError('undo() during transaction');
      }());
      return;
    }

    if (!_hist.canUndo) return;
    _hist = _hist.undo();
    _present = _hist.present;
    _sync();
  }

  void redo() {
    if (_inTxn) {
      assert(() {
        throw StateError('redo() during transaction');
      }());
      return;
    }

    if (!_hist.canRedo) return;
    _hist = _hist.redo();
    _present = _hist.present;
    _sync();
  }

  /// Starts a non-nestable transaction.
  /// The transaction snapshot is seeded from the current history present.
  void beginTransaction() {
    if (_inTxn) return;
    _inTxn = true;
    _txnStart = _present;
    _txnLatest = _present;
  }

  /// Ends the transaction and commits a single history entry if changed.
  ///
  /// Returns:
  /// - the new present if a history entry was pushed
  /// - null if nothing changed
  T? endTransaction() {
    if (!_inTxn) return null;

    _inTxn = false;
    final prev = _txnStart;
    final next = _txnLatest;
    _txnStart = null;
    _txnLatest = null;

    if (prev == null || next == null) return null;
    if (identical(prev, next) || prev == next) return null;

    _hist = _hist.withPresent(next);
    _present = _hist.present;
    _sync();
    return _hist.present;
  }

  /// Applies an operation to the current document.
  ///
  /// Behavior:
  /// - if in transaction:
  ///     - updates _txnLatest
  ///     - does NOT touch History
  /// - if not in transaction:
  ///     - when pushHistory == true: pushes a history entry
  ///     - when pushHistory == false: no history mutation
  ///
  /// Returns the document that callers should treat as "current canonical".
  T applyOp(T Function(T present) op, {required bool pushHistory}) {
    final input = _inTxn ? (_txnLatest ?? _present) : _present;
    final next = op(input);

    if (identical(next, input) || next == input) {
      if (_inTxn) _txnLatest = next;
      return input;
    }

    if (_inTxn) {
      _txnLatest = next;
      return next;
    }

    if (!pushHistory) {
      _present = next;
      return _present;
    }

    _hist = _hist.withPresent(next);
    _present = _hist.present;
    _sync();

    return _hist.present;
  }
}
