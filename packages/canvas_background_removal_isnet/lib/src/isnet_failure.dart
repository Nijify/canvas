// Path: packages/canvas_background_removal_isnet/lib/src/isnet_failure.dart

enum IsnetFailureKind {
  modelMissing,
  modelIdentityMismatch,
  modelOpenFailed,
  modelContractMismatch,
  invalidInput,
  inferenceFailed,
  invalidOutput,
  closed,
}

final class IsnetException implements Exception {
  const IsnetException(this.kind, {this.cause});

  final IsnetFailureKind kind;

  /// Provider/development diagnostic only.
  ///
  /// Never surface this directly as user-facing copy.
  final Object? cause;

  @override
  String toString() {
    final diagnosticCause = cause;
    if (diagnosticCause == null) {
      return 'IsnetException(kind: $kind)';
    }
    return 'IsnetException(kind: $kind, cause: $diagnosticCause)';
  }
}
