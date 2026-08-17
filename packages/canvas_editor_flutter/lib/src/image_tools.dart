/// Broad, editor-relevant failure classification for background removal.
///
/// Hosts may have substantially richer internal failure types. They should map
/// those failures to this small public taxonomy at the Canvas boundary.
enum BackgroundRemovalFailureKind {
  /// The selected input cannot be processed by this host capability.
  unsupported,

  /// The capability exists but cannot currently perform the operation.
  ///
  /// Examples include a temporarily unavailable local model or remote service.
  temporarilyUnavailable,

  /// The operation failed for another reason.
  failed,
}

/// Result of one host-owned background-removal operation.
sealed class BackgroundRemovalResult {
  const BackgroundRemovalResult();
}

/// Successful background removal.
///
/// [sourceRef] must be a new, non-blank, durable, host-resolvable reference that
/// can be persisted directly in `CanvasFields.imageSource`.
///
/// For the initial background-removal contract, the returned image must:
///
/// - be static;
/// - support transparency;
/// - preserve the input's display-oriented raster width and height exactly.
///
/// The editor intentionally does not receive bytes, MIME types, dimensions,
/// provider metadata, or storage details.
final class BackgroundRemovalSuccess extends BackgroundRemovalResult {
  const BackgroundRemovalSuccess({required this.sourceRef});

  final String sourceRef;
}

/// Expected host-owned background-removal failure.
///
/// [message], when supplied, must already be safe to present to the user.
/// Internal exceptions, provider diagnostics, stack traces, storage details,
/// and implementation-specific failure information must not be exposed here.
final class BackgroundRemovalFailure extends BackgroundRemovalResult {
  const BackgroundRemovalFailure({required this.kind, this.message});

  final BackgroundRemovalFailureKind kind;
  final String? message;
}

/// Host-owned background removal.
///
/// Canvas treats [sourceRef] as opaque. The host may read, decode, process,
/// encode, upload, persist, or remotely transform the source using any
/// implementation it chooses.
///
/// Success returns a new durable source reference suitable for direct storage
/// in the canvas document.
///
/// A successful result is not guaranteed to be adopted by the editor. The
/// selected image may be deleted, replaced, rebound, or otherwise become stale
/// while this asynchronous operation is running. Hosts must therefore tolerate
/// successful outputs that temporarily remain unreferenced.
///
/// Canvas intentionally does not provide output cleanup or rollback hooks.
/// Resource lifecycle and garbage collection remain host responsibilities.
abstract interface class BackgroundRemovalPort {
  Future<BackgroundRemovalResult> removeBackground({required String sourceRef});
}
