// Path: packages/canvas_background_removal/test/encoded_raster_inspector_test.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:canvas_background_removal/background_removal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const inspector = FlutterEncodedRasterInspector();

  group('FlutterEncodedRasterInspector', () {
    test('reads static PNG dimensions', () async {
      final info = await inspector.inspect(_rgbaPng2x3());

      expect(info.format, EncodedRasterFormat.png);
      expect(info.width, 2);
      expect(info.height, 3);
      expect(info.frameCount, 1);
      expect(info.isStatic, isTrue);
      expect(info.hasPositiveDimensions, isTrue);
    });

    test('recognizes an opaque RGBA PNG as transparency-capable', () async {
      final bytes = _rgbaPng2x3();

      final info = await inspector.inspect(bytes);

      expect(info.format, EncodedRasterFormat.png);
      expect(pngSupportsTransparency(bytes), isTrue);
    });

    test('rejects RGB PNG as transparency-capable output', () async {
      final bytes = _rgbPng2x3();

      final info = await inspector.inspect(bytes);

      expect(info.format, EncodedRasterFormat.png);
      expect(info.width, 2);
      expect(info.height, 3);
      expect(pngSupportsTransparency(bytes), isFalse);
    });

    test('identifies GIF input', () async {
      final info = await inspector.inspect(_gif2x3());

      expect(info.format, EncodedRasterFormat.gif);
      expect(info.width, 2);
      expect(info.height, 3);
      expect(info.frameCount, 1);
    });

    test('reports multiple frames for animated GIF', () async {
      final info = await inspector.inspect(_animatedGif2x3());

      expect(info.format, EncodedRasterFormat.gif);
      expect(info.frameCount, greaterThan(1));
      expect(info.isStatic, isFalse);
    });

    test('rejects malformed encoded bytes', () async {
      await expectLater(
        inspector.inspect(
          Uint8List.fromList(const <int>[
            0x89,
            0x50,
            0x4E,
            0x47,
            0x0D,
            0x0A,
            0x1A,
            0x0A,
          ]),
        ),
        throwsA(anything),
      );
    });
  });
}

Uint8List _rgbaPng2x3() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAYAAAC56t6BAAAAFklEQVR4nGP8z8Dwn4GBgYGJAQrgDAAxOwIE7x6DkQAAAABJRU5ErkJggg==',
);

Uint8List _rgbPng2x3() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAIAAAA2iEnWAAAAE0lEQVR4nGP8z8DAwMDAxIBMAQAUQAEF3SN5DgAAAABJRU5ErkJggg==',
);

Uint8List _gif2x3() => base64Decode(
  'R0lGODdhAgADAIEAAP8AAAAAAAAAAAAAACwAAAAAAgADAAAIBgABCBwYEAA7',
);

Uint8List _animatedGif2x3() => base64Decode(
  'R0lGODlhAgADAIEAAP8AAAAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQACgAAACwAAAAAAgADAAAIBgABCBwYEAAh+QQBCgABACwAAAAAAgADAIEA/wAAAAAAAAAAAAAIBgABCBwYEAA7',
);
