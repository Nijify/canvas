// Path: oss_packages/canvas_core/test/canvas_asset_ref_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

void main() {
  group('parseCanvasAssetRef', () {
    test('parses custom scheme refs opaquely', () {
      final media = parseCanvasAssetRef('media:abc');

      expect(media, isA<CanvasSchemeAssetRef>());
      final mediaRef = media as CanvasSchemeAssetRef;
      expect(mediaRef.raw, 'media:abc');
      expect(mediaRef.scheme, 'media');
      expect(mediaRef.payload, 'abc');
      expect(mediaRef.canonicalKey, 'media:abc');

      final asset = parseCanvasAssetRef('asset:assets/foo.png');

      expect(asset, isA<CanvasSchemeAssetRef>());
      final assetRef = asset as CanvasSchemeAssetRef;
      expect(assetRef.scheme, 'asset');
      expect(assetRef.payload, 'assets/foo.png');
      expect(assetRef.canonicalKey, 'asset:assets/foo.png');
    });

    test('trims raw input and scheme payload', () {
      final ref = parseCanvasAssetRef('  media: abc  ');

      expect(ref, isA<CanvasSchemeAssetRef>());
      final schemeRef = ref as CanvasSchemeAssetRef;
      expect(schemeRef.raw, 'media: abc');
      expect(schemeRef.scheme, 'media');
      expect(schemeRef.payload, 'abc');
    });

    test('parses http and https URLs', () {
      final https = parseCanvasAssetRef('https://example.com/image.png');
      expect(https, isA<CanvasUrlAssetRef>());
      expect((https as CanvasUrlAssetRef).uri.scheme, 'https');

      final http = parseCanvasAssetRef('http://example.com/image.png');
      expect(http, isA<CanvasUrlAssetRef>());
      expect((http as CanvasUrlAssetRef).uri.scheme, 'http');
    });

    test('parses data and blob refs separately from generic schemes', () {
      expect(
        parseCanvasAssetRef('data:image/png;base64,abc'),
        isA<CanvasDataUriAssetRef>(),
      );

      expect(
        parseCanvasAssetRef('blob:https://example.com/123'),
        isA<CanvasBlobUrlAssetRef>(),
      );
    });

    test('parses file uri and local paths', () {
      expect(
        parseCanvasAssetRef('file:///tmp/a.png'),
        isA<CanvasFileAssetRef>(),
      );
      expect(parseCanvasAssetRef('/tmp/a.png'), isA<CanvasFileAssetRef>());
      expect(parseCanvasAssetRef('./a.png'), isA<CanvasFileAssetRef>());
      expect(parseCanvasAssetRef('../a.png'), isA<CanvasFileAssetRef>());
      expect(parseCanvasAssetRef('~/a.png'), isA<CanvasFileAssetRef>());
      expect(parseCanvasAssetRef(r'C:\tmp\a.png'), isA<CanvasFileAssetRef>());
      expect(parseCanvasAssetRef('C:/tmp/a.png'), isA<CanvasFileAssetRef>());
    });

    test('parses raw ids opaquely', () {
      final ref = parseCanvasAssetRef('abc123');

      expect(ref, isA<CanvasRawAssetRef>());
      expect(ref.raw, 'abc123');
      expect(ref.canonicalKey, 'abc123');
    });

    test('parses empty string as empty raw ref', () {
      final ref = parseCanvasAssetRef('   ');

      expect(ref, isA<CanvasRawAssetRef>());
      expect(ref.raw, '');
      expect(ref.isEmpty, isTrue);
    });
  });
}
