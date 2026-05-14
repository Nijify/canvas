// Path: lib/src/foundation/assets/canvas_asset_ref.dart
//
// Canonical, renderer-agnostic parsing for image/asset source references stored
// in canvas documents.
//
// Important boundary:
// - canvas_core may classify the *shape* of a ref.
// - canvas_core must not assign application/backend semantics to custom
//   schemes. For example, "media:abc" is parsed as an opaque scheme ref with
//   scheme="media", payload="abc"; canvas_core does not decide whether this
//   refers to a host application media record, a backend asset row, or another
//   application-specific media identifier.
//
// Host apps/renderers decide how to resolve or render each scheme.

sealed class CanvasAssetRef {
  const CanvasAssetRef(this.raw);

  /// The trimmed source string as it appeared in the canvas document.
  final String raw;

  /// Stable key for generic maps/caches.
  ///
  /// This is intentionally generic. App-specific resolvers may choose a
  /// different internal cache key, for example using the payload of a known
  /// scheme such as media:`<id>`.
  String get canonicalKey;

  bool get isEmpty => raw.isEmpty;
}

/// Opaque custom-scheme reference, such as:
/// - media:`<id>`
/// - asset:`<path>`
/// - library:`<id>`
/// - cms:`<id>`
///
/// canvas_core does not interpret the scheme. It only splits the syntax.
final class CanvasSchemeAssetRef extends CanvasAssetRef {
  const CanvasSchemeAssetRef({
    required String raw,
    required this.scheme,
    required this.payload,
  }) : super(raw);

  /// Lower-cased URI scheme name.
  final String scheme;

  /// Trimmed text after the first ":".
  final String payload;

  @override
  String get canonicalKey => raw;

  bool get hasPayload => payload.isNotEmpty;
}

/// Network URL reference.
final class CanvasUrlAssetRef extends CanvasAssetRef {
  const CanvasUrlAssetRef({required String raw, required this.uri})
    : super(raw);
  final Uri uri;

  @override
  String get canonicalKey => raw;
}

/// Inline data URI reference.
///
/// Usually renderable but not a stable/portable persisted asset reference.
final class CanvasDataUriAssetRef extends CanvasAssetRef {
  const CanvasDataUriAssetRef(super.raw);

  @override
  String get canonicalKey => raw;
}

/// Browser blob URL reference.
///
/// Usually renderable in-session but not stable/portable across sessions.
final class CanvasBlobUrlAssetRef extends CanvasAssetRef {
  const CanvasBlobUrlAssetRef(super.raw);

  @override
  String get canonicalKey => raw;
}

/// Local file reference.
///
/// This includes file:// URIs and path-like local strings.
final class CanvasFileAssetRef extends CanvasAssetRef {
  const CanvasFileAssetRef({required String raw, required this.path})
    : super(raw);
  final String path;

  @override
  String get canonicalKey => path;
}

/// Bare/raw source reference with no recognized syntax.
///
/// Host apps may decide that this means an app-specific id. canvas_core keeps it
/// opaque.
final class CanvasRawAssetRef extends CanvasAssetRef {
  const CanvasRawAssetRef(super.raw);

  @override
  String get canonicalKey => raw;
}

CanvasAssetRef parseCanvasAssetRef(String input) {
  final raw = input.trim();

  if (raw.isEmpty) {
    return const CanvasRawAssetRef('');
  }

  // Windows absolute path, e.g. C:\tmp\a.png or C:/tmp/a.png.
  if (RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(raw)) {
    return CanvasFileAssetRef(raw: raw, path: raw);
  }

  if (_looksLikeLocalPath(raw)) {
    return CanvasFileAssetRef(raw: raw, path: raw);
  }

  final uri = Uri.tryParse(raw);
  final scheme = uri?.scheme.toLowerCase() ?? '';

  if (scheme == 'http' || scheme == 'https') {
    return CanvasUrlAssetRef(raw: raw, uri: uri!);
  }

  if (scheme == 'data') {
    return CanvasDataUriAssetRef(raw);
  }

  if (scheme == 'blob') {
    return CanvasBlobUrlAssetRef(raw);
  }

  if (scheme == 'file') {
    return CanvasFileAssetRef(raw: raw, path: _filePathFromUri(raw));
  }

  final customScheme = _customScheme(raw);
  if (customScheme != null) {
    return CanvasSchemeAssetRef(
      raw: raw,
      scheme: customScheme.$1,
      payload: customScheme.$2,
    );
  }

  return CanvasRawAssetRef(raw);
}

bool _looksLikeLocalPath(String raw) {
  return raw.startsWith('/') ||
      raw.startsWith('./') ||
      raw.startsWith('../') ||
      raw.startsWith('~');
}

String _filePathFromUri(String raw) {
  try {
    return Uri.parse(raw).toFilePath();
  } catch (_) {
    return raw;
  }
}

(String, String)? _customScheme(String raw) {
  final colon = raw.indexOf(':');
  if (colon <= 0) return null;

  final scheme = raw.substring(0, colon);
  if (!_isValidUriScheme(scheme)) return null;

  return (scheme.toLowerCase(), raw.substring(colon + 1).trim());
}

bool _isValidUriScheme(String value) {
  return RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*$').hasMatch(value);
}
