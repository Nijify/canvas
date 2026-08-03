// Path: packages/canvas_renderer_flutter/test/flutter_image_adapters_test.dart

import 'dart:convert';

import 'package:canvas_renderer_flutter/canvas_renderer_flutter_image_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sourceToProvider', () {
    test('maps http URLs to NetworkImage', () {
      final provider = sourceToProvider('https://example.com/image.png');

      expect(provider, isA<NetworkImage>());
      expect((provider as NetworkImage).url, 'https://example.com/image.png');
    });

    test('maps asset refs to AssetImage', () {
      final provider = sourceToProvider(
        'asset:assets/samples/sample_image.png',
      );

      expect(provider, isA<AssetImage>());
      expect(
        (provider as AssetImage).assetName,
        'assets/samples/sample_image.png',
      );
    });

    test('maps raw Flutter asset paths to AssetImage', () {
      final provider = sourceToProvider('assets/samples/sample_image.png');

      expect(provider, isA<AssetImage>());
      expect(
        (provider as AssetImage).assetName,
        'assets/samples/sample_image.png',
      );
    });

    test('maps data URIs to MemoryImage', () {
      final provider = sourceToProvider('data:image/png;base64,AAAA');

      expect(provider, isA<MemoryImage>());
      expect((provider as MemoryImage).bytes, isNotEmpty);
    });

    test('maps PNG data URIs before file fallback', () {
      const dataUri =
          'data:image/png;base64,'
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0l'
          'EQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=';

      final provider = sourceToProvider(dataUri);

      expect(provider, isA<MemoryImage>());
      expect((provider as MemoryImage).bytes, isNotEmpty);
    });
  });

  group('toUiImage', () {
    testWidgets('returns an independently owned disposable image handle', (
      tester,
    ) async {
      const pngBase64 =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0l'
          'EQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=';

      final provider = MemoryImage(base64Decode(pngBase64));

      final image = await toUiImage(provider);

      expect(image, isNotNull);

      final retained = image!;

      addTearDown(() {
        if (!retained.debugDisposed) {
          retained.dispose();
        }
      });

      expect(retained.width, 1);
      expect(retained.height, 1);
      expect(retained.debugDisposed, isFalse);

      // Evict the provider-owned cache entry. The returned clone must remain
      // alive because toUiImage transferred an independent handle.
      await provider.evict();

      expect(retained.debugDisposed, isFalse);
      expect(retained.width, 1);
      expect(retained.height, 1);

      retained.dispose();

      expect(retained.debugDisposed, isTrue);
    });
  });
}
