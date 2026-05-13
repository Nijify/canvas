// Path: oss_packages/canvas_core/test/layout/text_measure_cache_test.dart

import 'package:test/test.dart';
import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/services/services.dart';
import 'package:canvas_core/src/services/text_measure.dart';

class _MockTextMeasurer implements TextMeasurer {
  int callCount = 0;

  @override
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required int letterSpacing,
  }) {
    callCount++;
    // Return a simple size based on text length for testing
    return Size2D(text.length * fontSize, fontSize);
  }
}

void main() {
  group('TextMeasureCache', () {
    late TextMeasureCache cache;
    late _MockTextMeasurer measurer;

    setUp(() {
      cache = TextMeasureCache();
      measurer = _MockTextMeasurer();
    });

    test('caches measurements and returns same result on repeated calls', () {
      final size1 = cache.measureSpaced(
        measurer: measurer,
        text: 'Hello',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 0,
      );

      expect(measurer.callCount, 1);

      final size2 = cache.measureSpaced(
        measurer: measurer,
        text: 'Hello',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 0,
      );

      // Should be cached, so no additional measurement call
      expect(measurer.callCount, 1);
      expect(size2, equals(size1));
    });

    test('different text results in cache miss', () {
      cache.measureSpaced(
        measurer: measurer,
        text: 'Hello',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 0,
      );

      expect(measurer.callCount, 1);

      cache.measureSpaced(
        measurer: measurer,
        text: 'World',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 0,
      );

      // Different text should cause a new measurement
      expect(measurer.callCount, 2);
    });

    test('different fontFamily results in cache miss', () {
      cache.measureSpaced(
        measurer: measurer,
        text: 'Hello',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 0,
      );

      expect(measurer.callCount, 1);

      cache.measureSpaced(
        measurer: measurer,
        text: 'Hello',
        fontFamily: 'Roboto',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 0,
      );

      expect(measurer.callCount, 2);
    });

    test('different fontWeight results in cache miss', () {
      cache.measureSpaced(
        measurer: measurer,
        text: 'Hello',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 0,
      );

      expect(measurer.callCount, 1);

      cache.measureSpaced(
        measurer: measurer,
        text: 'Hello',
        fontFamily: 'Inter',
        fontWeight: 700,
        fontSize: 16.0,
        letterSpacing: 0,
      );

      expect(measurer.callCount, 2);
    });

    test('different fontSize results in cache miss', () {
      cache.measureSpaced(
        measurer: measurer,
        text: 'Hello',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 0,
      );

      expect(measurer.callCount, 1);

      cache.measureSpaced(
        measurer: measurer,
        text: 'Hello',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 20.0,
        letterSpacing: 0,
      );

      expect(measurer.callCount, 2);
    });

    test('different letterSpacing results in cache miss', () {
      cache.measureSpaced(
        measurer: measurer,
        text: 'Hello',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 0,
      );

      expect(measurer.callCount, 1);

      cache.measureSpaced(
        measurer: measurer,
        text: 'Hello',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 2,
      );

      expect(measurer.callCount, 2);
    });

    test('fractional fontSize values are handled correctly in cache key', () {
      final size1 = cache.measureSpaced(
        measurer: measurer,
        text: 'Test',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.5,
        letterSpacing: 0,
      );

      expect(measurer.callCount, 1);

      final size2 = cache.measureSpaced(
        measurer: measurer,
        text: 'Test',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.5,
        letterSpacing: 0,
      );

      // Should hit cache for same fractional fontSize
      expect(measurer.callCount, 1);
      expect(size2, equals(size1));

      // Slightly different fractional fontSize should miss cache
      cache.measureSpaced(
        measurer: measurer,
        text: 'Test',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.50001,
        letterSpacing: 0,
      );

      expect(measurer.callCount, 2);
    });

    test('cached results match direct measurements', () {
      // First measure directly using the extension method
      final directSize = measurer.measureSpaced(
        text: 'Test',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 2,
      );

      measurer.callCount = 0; // Reset counter

      final cachedSize = cache.measureSpaced(
        measurer: measurer,
        text: 'Test',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 2,
      );

      expect(cachedSize, equals(directSize));
      expect(measurer.callCount, 1);
    });

    test('cache can handle multiple different measurements', () {
      cache.measureSpaced(
        measurer: measurer,
        text: 'A',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 0,
      );

      cache.measureSpaced(
        measurer: measurer,
        text: 'B',
        fontFamily: 'Roboto',
        fontWeight: 700,
        fontSize: 20.0,
        letterSpacing: 1,
      );

      cache.measureSpaced(
        measurer: measurer,
        text: 'C',
        fontFamily: 'Arial',
        fontWeight: 400,
        fontSize: 14.0,
        letterSpacing: 2,
      );

      expect(measurer.callCount, 3);

      // All should be cached
      measurer.callCount = 0;

      cache.measureSpaced(
        measurer: measurer,
        text: 'A',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 0,
      );

      cache.measureSpaced(
        measurer: measurer,
        text: 'B',
        fontFamily: 'Roboto',
        fontWeight: 700,
        fontSize: 20.0,
        letterSpacing: 1,
      );

      cache.measureSpaced(
        measurer: measurer,
        text: 'C',
        fontFamily: 'Arial',
        fontWeight: 400,
        fontSize: 14.0,
        letterSpacing: 2,
      );

      expect(measurer.callCount, 0);
    });
  });

  group('_TextMeasureKey equality and hashing', () {
    test('keys with same values are equal', () {
      // Note: We can't directly test _TextMeasureKey as it's private,
      // but we can verify the cache behavior which depends on it
      final cache = TextMeasureCache();
      final measurer = _MockTextMeasurer();

      cache.measureSpaced(
        measurer: measurer,
        text: 'Test',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 0,
      );

      expect(measurer.callCount, 1);

      // Same parameters should hit the cache
      cache.measureSpaced(
        measurer: measurer,
        text: 'Test',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 0,
      );

      expect(measurer.callCount, 1);
    });
  });
}
