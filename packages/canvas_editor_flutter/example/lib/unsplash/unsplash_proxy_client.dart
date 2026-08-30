import 'dart:convert';

import 'package:canvas_editor_flutter_example/unsplash/unsplash_photo.dart';
import 'package:flutter/services.dart' show NetworkAssetBundle;

typedef UnsplashGet = Future<String> Function(Uri uri);

final class UnsplashProxyClient {
  UnsplashProxyClient({required Uri baseUri, UnsplashGet? get})
      : _baseUri = baseUri,
        _get = get ?? _defaultGet;

  final Uri _baseUri;
  final UnsplashGet _get;

  Future<List<UnsplashPhoto>> search(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return const <UnsplashPhoto>[];

    final uri = _resolve(
      'unsplash/search',
      <String, String>{'query': normalized},
    );
    final body = await _get(uri);
    final decoded = jsonDecode(body);

    if (decoded is! Map) {
      throw const FormatException('Unsplash search returned invalid JSON.');
    }

    final results = decoded['results'];
    if (results is! List) {
      throw const FormatException('Unsplash search response has no results.');
    }

    return results
        .map((value) {
          if (value is! Map) {
            throw const FormatException('Unsplash result is not an object.');
          }
          return UnsplashPhoto.fromJson(Map<String, Object?>.from(value));
        })
        .toList(growable: false);
  }

  Future<void> trackDownload(UnsplashPhoto photo) async {
    final download = photo.downloadLocation;

    if (download.scheme != 'https' ||
        download.host != 'api.unsplash.com' ||
        !download.path.endsWith('/download')) {
      throw ArgumentError.value(
        download,
        'photo.downloadLocation',
        'must be an Unsplash API download location',
      );
    }

    // Pass only the validated Unsplash path/query to the proxy. The proxy should
    // reconstruct the api.unsplash.com URL server-side and must not accept an
    // arbitrary upstream URL.
    final uri = _resolve(
      'unsplash/track',
      <String, String>{
        'path': download.path,
        if (download.hasQuery) 'query': download.query,
      },
    );

    await _get(uri);
  }

  Uri _resolve(String path, Map<String, String> queryParameters) {
    final basePath = _baseUri.path.endsWith('/')
        ? _baseUri.path
        : '${_baseUri.path}/';

    return _baseUri.replace(
      path: '$basePath$path',
      queryParameters: queryParameters,
    );
  }

  static Future<String> _defaultGet(Uri uri) {
    return NetworkAssetBundle(uri).loadString('');
  }
}
