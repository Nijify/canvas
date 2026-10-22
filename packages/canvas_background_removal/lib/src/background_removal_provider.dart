import 'dart:typed_data';

/// The native/model provider operates only on encoded bytes. Validation,
/// persistence, and Canvas result mapping belong to the shared package.
abstract interface class BackgroundRemovalByteProcessor {
  Future<Uint8List> remove(Uint8List inputBytes);
}

enum BackgroundRemovalProviderFailureKind {
  temporarilyUnavailable,
  unsupported,
  failed,
}

/// Diagnostics must never be shown directly to users.
final class BackgroundRemovalProviderException implements Exception {
  const BackgroundRemovalProviderException(this.kind, {this.cause});

  final BackgroundRemovalProviderFailureKind kind;
  final Object? cause;
}
