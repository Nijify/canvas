// Path: packages/canvas_background_removal/lib/src/encoded_raster_inspector.dart

import 'dart:typed_data';
import 'dart:ui' as ui;

enum EncodedRasterFormat { png, jpeg, webp, gif, unknown }

final class EncodedRasterInfo {
  const EncodedRasterInfo({
    required this.format,
    required this.width,
    required this.height,
    required this.frameCount,
  });

  final EncodedRasterFormat format;
  final int width;
  final int height;
  final int frameCount;

  bool get isStatic => frameCount == 1;

  bool get hasPositiveDimensions => width > 0 && height > 0;
}

abstract interface class EncodedRasterInspector {
  Future<EncodedRasterInfo> inspect(Uint8List bytes);
}

final class FlutterEncodedRasterInspector implements EncodedRasterInspector {
  const FlutterEncodedRasterInspector();

  @override
  Future<EncodedRasterInfo> inspect(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw const FormatException('Encoded raster is empty.');
    }

    final format = _detectFormat(bytes);

    final codec = await ui.instantiateImageCodec(bytes);

    try {
      final frameCount = codec.frameCount;

      if (frameCount < 1) {
        throw const FormatException('Encoded raster contains no frames.');
      }

      final frame = await codec.getNextFrame();
      final image = frame.image;

      try {
        return EncodedRasterInfo(
          format: format,
          width: image.width,
          height: image.height,
          frameCount: frameCount,
        );
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }
}

/// Whether [bytes] use a PNG representation capable of representing
/// transparency.
///
/// This does not require any pixel to actually be transparent. An opaque image
/// encoded with an alpha channel is still transparency-capable.
bool pngSupportsTransparency(Uint8List bytes) {
  if (_detectFormat(bytes) != EncodedRasterFormat.png) {
    return false;
  }

  const signatureLength = 8;
  var offset = signatureLength;
  int? colorType;
  var hasTransparencyChunk = false;

  while (offset + 12 <= bytes.length) {
    final length = _readUint32BigEndian(bytes, offset);
    final typeOffset = offset + 4;
    final dataOffset = offset + 8;
    final dataEnd = dataOffset + length;
    final chunkEnd = dataEnd + 4;

    if (dataEnd < dataOffset || chunkEnd > bytes.length) {
      return false;
    }

    if (_chunkTypeEquals(bytes, typeOffset, 'IHDR')) {
      if (length != 13 || dataOffset + 10 > bytes.length) {
        return false;
      }

      colorType = bytes[dataOffset + 9];

      // PNG color types 4 and 6 have an explicit alpha channel.
      if (colorType == 4 || colorType == 6) {
        return true;
      }
    } else if (_chunkTypeEquals(bytes, typeOffset, 'tRNS')) {
      hasTransparencyChunk = true;
    } else if (_chunkTypeEquals(bytes, typeOffset, 'IEND')) {
      break;
    }

    offset = chunkEnd;
  }

  // Color types 0, 2, and 3 can represent transparency through tRNS.
  return switch (colorType) {
    0 || 2 || 3 => hasTransparencyChunk,
    _ => false,
  };
}

EncodedRasterFormat _detectFormat(Uint8List bytes) {
  if (_hasPrefix(bytes, const <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ])) {
    return EncodedRasterFormat.png;
  }

  if (_hasPrefix(bytes, const <int>[0xFF, 0xD8, 0xFF])) {
    return EncodedRasterFormat.jpeg;
  }

  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return EncodedRasterFormat.webp;
  }

  if (_hasPrefix(bytes, const <int>[0x47, 0x49, 0x46, 0x38, 0x37, 0x61]) ||
      _hasPrefix(bytes, const <int>[0x47, 0x49, 0x46, 0x38, 0x39, 0x61])) {
    return EncodedRasterFormat.gif;
  }

  return EncodedRasterFormat.unknown;
}

bool _hasPrefix(Uint8List bytes, List<int> prefix) {
  if (bytes.length < prefix.length) {
    return false;
  }

  for (var index = 0; index < prefix.length; index++) {
    if (bytes[index] != prefix[index]) {
      return false;
    }
  }

  return true;
}

bool _chunkTypeEquals(Uint8List bytes, int offset, String type) {
  if (type.length != 4 || offset + 4 > bytes.length) {
    return false;
  }

  for (var index = 0; index < 4; index++) {
    if (bytes[offset + index] != type.codeUnitAt(index)) {
      return false;
    }
  }

  return true;
}

int _readUint32BigEndian(Uint8List bytes, int offset) {
  return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}
