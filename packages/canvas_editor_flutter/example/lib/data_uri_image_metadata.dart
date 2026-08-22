import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart' show Size2D;

/// Resolves stable intrinsic dimensions for images embedded in data URIs.
final class DataUriImageMetadataResolver {
  final Map<String, Future<Size2D?>> _cache = <String, Future<Size2D?>>{};

  Future<Size2D?> resolve(String ref) {
    final normalized = ref.trim();

    if (!normalized.toLowerCase().startsWith('data:')) {
      return Future<Size2D?>.value();
    }

    return _cache.putIfAbsent(normalized, () => _decode(normalized));
  }

  Future<Size2D?> _decode(String ref) async {
    try {
      final data = Uri.parse(ref).data;
      if (data == null) return null;

      final bytes = data.contentAsBytes();
      if (bytes.isEmpty) return null;

      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);

      try {
        final descriptor = await ui.ImageDescriptor.encoded(buffer);

        try {
          if (descriptor.width <= 0 || descriptor.height <= 0) return null;

          return Size2D(
            descriptor.width.toDouble(),
            descriptor.height.toDouble(),
          );
        } finally {
          descriptor.dispose();
        }
      } finally {
        buffer.dispose();
      }
    } on Exception {
      return null;
    }
  }
}
