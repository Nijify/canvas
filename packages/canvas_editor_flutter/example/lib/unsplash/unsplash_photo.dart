import 'package:canvas_core/canvas_core_runtime.dart' show Size2D;
import 'package:canvas_editor_flutter/asset_library.dart';

const _utmSource = 'canvas_editor_example';
const _utmMedium = 'referral';

final class UnsplashCredit {
  const UnsplashCredit({
    required this.photographerName,
    required this.photographerUrl,
  });

  final String photographerName;
  final Uri photographerUrl;

  Uri get attributedPhotographerUrl => withUnsplashReferral(photographerUrl);
}

final class UnsplashPhoto {
  const UnsplashPhoto({
    required this.id,
    required this.label,
    required this.width,
    required this.height,
    required this.thumbnailUrl,
    required this.imageUrl,
    required this.credit,
    required this.downloadLocation,
  });

  factory UnsplashPhoto.fromJson(Map<String, Object?> json) {
    final urls = _requiredMap(json, 'urls');
    final user = _requiredMap(json, 'user');
    final userLinks = _requiredMap(user, 'links');
    final links = _requiredMap(json, 'links');

    final description = _optionalString(json['description']);
    final altDescription = _optionalString(json['alt_description']);

    return UnsplashPhoto(
      id: _requiredString(json, 'id'),
      label: description ?? altDescription ?? 'Unsplash photo',
      width: _requiredPositiveInt(json, 'width'),
      height: _requiredPositiveInt(json, 'height'),
      thumbnailUrl: Uri.parse(_requiredString(urls, 'small')),
      imageUrl: Uri.parse(_requiredString(urls, 'regular')),
      credit: UnsplashCredit(
        photographerName: _requiredString(user, 'name'),
        photographerUrl: Uri.parse(_requiredString(userLinks, 'html')),
      ),
      downloadLocation: Uri.parse(_requiredString(links, 'download_location')),
    );
  }

  final String id;
  final String label;
  final int width;
  final int height;
  final Uri thumbnailUrl;
  final Uri imageUrl;
  final UnsplashCredit credit;
  final Uri downloadLocation;

  String get sourceRef => imageUrl.toString();

  CanvasAssetLibraryItem toAssetLibraryItem() {
    return CanvasAssetLibraryItem(
      id: id,
      label: label,
      category: 'Unsplash',
      sourceRef: sourceRef,
      thumbnailRef: thumbnailUrl.toString(),
      intrinsicSize: Size2D(width.toDouble(), height.toDouble()),
      metadata: <String, Object?>{
        'provider': 'unsplash',
        'photographerName': credit.photographerName,
        'photographerUrl': credit.attributedPhotographerUrl.toString(),
      },
    );
  }
}

Uri get attributedUnsplashUrl => withUnsplashReferral(Uri.parse('https://unsplash.com/'));

Uri withUnsplashReferral(Uri uri) {
  return uri.replace(
    queryParameters: <String, String>{
      ...uri.queryParameters,
      'utm_source': _utmSource,
      'utm_medium': _utmMedium,
    },
  );
}

Map<String, Object?> _requiredMap(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  throw FormatException('Unsplash response is missing "$key".');
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = _optionalString(json[key]);
  if (value != null) return value;
  throw FormatException('Unsplash response is missing "$key".');
}

String? _optionalString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int _requiredPositiveInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int && value > 0) return value;
  if (value is num && value.isFinite && value > 0) return value.round();
  throw FormatException('Unsplash response has invalid "$key".');
}
