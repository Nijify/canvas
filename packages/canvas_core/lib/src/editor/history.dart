// Path: lib/src/editor/history.dart
//
// History<S> – a tiny, immutable undo/redo reducer.
// - Pure/headless: no timers, no UI.
// - Each method returns a NEW History instance.
// - Size-bounded by `limit` (keeps the most recent `limit` past states).
//
// Typical usage:
//
//   var h = History(doc, limit: 100);
//   h = h.reduce(op1);       // push present -> past, present = op1(present), future = []
//   h = h.reduce(op2);
//   h = h.undo();            // pop from past -> present, push old present -> future
//   h = h.redo();            // pop from future -> present, push old present -> past
//
// Notes:
// - `label` is accepted for API symmetry (e.g., UI may log it); it is not stored.
//

class History<S> {
  /// Create a new history with an initial [present] state.
  History(this.present, {this.limit = 100})
    : assert(limit >= 0),
      _past = const [],
      _future = const [];

  /// Private constructor used by transitions.
  History._internal({
    required List<S> past,
    required this.present,
    required List<S> future,
    required this.limit,
  }) : assert(limit >= 0),
       _past = past,
       _future = future;

  /// Maximum number of entries retained in the *past* stack.
  /// (Present is always retained; future is unbounded except by usage.)
  final int limit;

  final List<S> _past;
  final List<S> _future;

  /// The current value.
  final S present;

  /// Whether an undo is possible.
  bool get canUndo => _past.isNotEmpty;

  /// Whether a redo is possible.
  bool get canRedo => _future.isNotEmpty;

  /// Number of items in the past stack.
  int get pastLength => _past.length;

  /// Number of items in the future stack.
  int get futureLength => _future.length;

  /// Apply [op] to the current [present], pushing the old present to *past*,
  /// clearing *future*. `label` is accepted for UI logging but not stored.
  History<S> reduce(S Function(S) op, {String? label}) {
    final next = op(present);
    final nextPast = _takeLast([..._past, present], limit);
    return History<S>._internal(
      past: nextPast,
      present: next,
      future: const [],
      limit: limit,
    );
  }

  /// Replace the present with [next] (equivalent to `reduce((_) => next)`).
  History<S> withPresent(S next, {String? label}) =>
      reduce((_) => next, label: label);

  /// Undo to the previous state, if available.
  History<S> undo() {
    if (!canUndo) return this;
    final prevPresent = _past.last;
    final nextPast = _past.sublist(0, _past.length - 1);
    final nextFuture = [present, ..._future];
    return History<S>._internal(
      past: nextPast,
      present: prevPresent,
      future: nextFuture,
      limit: limit,
    );
  }

  /// Redo to the next state, if available.
  History<S> redo() {
    if (!canRedo) return this;
    final nextPresent = _future.first;
    final nextFuture = _future.sublist(1);
    final nextPast = _takeLast([..._past, present], limit);
    return History<S>._internal(
      past: nextPast,
      present: nextPresent,
      future: nextFuture,
      limit: limit,
    );
  }

  /// Clear the history stacks while keeping the current [present].
  History<S> clear() => History<S>._internal(
    past: const [],
    present: present,
    future: const [],
    limit: limit,
  );
}

// ── Internal helpers ─────────────────────────────────────────────────────────

/// Return the last [n] elements of [list] as a new list (or the whole list if
/// its length ≤ n). This keeps the most recent history bounded by `limit`.
List<T> _takeLast<T>(List<T> list, int n) {
  if (n <= 0 || list.isEmpty) return <T>[];
  return list.length <= n ? List<T>.from(list) : list.sublist(list.length - n);
}
