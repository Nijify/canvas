import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart' show Size2D;
import 'package:flutter/foundation.dart' show debugPrint;

typedef DataUriImageMetadataDecoder = Future<Size2D?> Function(String ref);

const _defaultDecodeTimeout = Duration(seconds: 2);

/// Resolves stable intrinsic dimensions for images embedded in data URIs.
final class DataUriImageMetadataResolver {
  DataUriImageMetadataResolver({
    this.decodeTimeout = _defaultDecodeTimeout,
    DataUriImageMetadataDecoder? decoder,
  }) : _decoder = decoder ?? _decodeDataUriImage;

  final Duration decodeTimeout;
  final DataUriImageMetadataDecoder _decoder;

  final Map<String, Future<Size2D?>> _cache = <String, Future<Size2D?>>{};

  Future<Size2D?> resolve(String ref) {
    final normalized = ref.trim();

    if (!normalized.toLowerCase().startsWith('data:')) {
      return Future<Size2D?>.value();
    }

    // Cache the bounded operation so later consumers receive a settled null
    // instead of reattaching to an underlying decode that may never complete.
    return _cache.putIfAbsent(normalized, () => _resolve(normalized));
  }

  Future<Size2D?> _resolve(String ref) async {
    try {
      return await _decoder(ref).timeout(decodeTimeout);
    } catch (error, stackTrace) {
      debugPrint(
        'Data URI image metadata resolution failed: '
        '$error\n$stackTrace',
      );
      return null;
    }
  }
}

Future<Size2D?> _decodeDataUriImage(String ref) async {
  final data = Uri.parse(ref).data;
  if (data == null) return null;

  final bytes = data.contentAsBytes();
  if (bytes.isEmpty) return null;

  final codec = await ui.instantiateImageCodec(bytes);

  try {
    final frame = await codec.getNextFrame();
    final image = frame.image;

    try {
      if (image.width <= 0 || image.height <= 0) return null;

      return Size2D(image.width.toDouble(), image.height.toDouble());
    } finally {
      image.dispose();
    }
  } finally {
    codec.dispose();
  }
}
