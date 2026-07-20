// Path: oss_packages/canvas_editor_flutter/lib/src/image_import.dart
/// Where the user wants to import an image from.
enum ImageImportSource { gallery, camera }

/// The outcome of a host-owned user-image import.
///
/// A successful import returns a document-ready, host-resolvable source
/// reference. The editor treats [sourceRef] as opaque: it may be `media:`,
/// `asset:`, an HTTPS URL, or another host-defined scheme.
class ImageImportResult {
  const ImageImportResult._({
    required this.cancelled,
    this.sourceRef,
    this.errorMessage,
  });

  /// No image was selected. The editor must not create a document edit.
  const ImageImportResult.cancelled() : this._(cancelled: true);

  factory ImageImportResult.success(String sourceRef) {
    if (sourceRef.trim().isEmpty) {
      throw ArgumentError.value(sourceRef, 'sourceRef', 'must not be blank');
    }

    return ImageImportResult._(cancelled: false, sourceRef: sourceRef);
  }

  /// A user-safe message suitable for editor UI feedback.
  factory ImageImportResult.failure(String errorMessage) {
    final normalizedMessage = errorMessage.trim();

    return ImageImportResult._(
      cancelled: false,
      errorMessage: normalizedMessage.isEmpty
          ? 'Unable to import image.'
          : normalizedMessage,
    );
  }

  final bool cancelled;
  final String? sourceRef;
  final String? errorMessage;
}

/// Host-owned import of a user-provided image.
///
/// The host may pick, transform, upload, persist, or otherwise prepare the
/// selected image. On success, it returns the durable source reference that
/// should be stored in the canvas document.
abstract class ImageImportPort {
  Future<ImageImportResult> importImage({required ImageImportSource source});
}
