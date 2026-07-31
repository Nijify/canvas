// Path: test/layout/text_measure_cache_test.dart

import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/services/services.dart';
import 'package:canvas_core/src/services/text_measure.dart';
import 'package:test/test.dart';

class _RecordingTextMeasurer implements TextMeasurer {
  int callCount = 0;
  String? lastText;
  double? lastLetterSpacing;

  @override
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required double letterSpacing,
  }) {
    callCount++;
    lastText = text;
    lastLetterSpacing = letterSpacing;

    return Size2D(text.length * fontSize, fontSize);
  }
}

void main() {
  group('TextMeasureCache', () {
    late TextMeasureCache cache;
    late _RecordingTextMeasurer measurer;

    setUp(() {
      cache = TextMeasureCache();
      measurer = _RecordingTextMeasurer();
    });

    test('caches identical text measurement requests', () {
      final first = cache.measure(
        measurer: measurer,
        text: 'Hello',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 1.25,
      );

      final second = cache.measure(
        measurer: measurer,
        text: 'Hello',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 1.25,
      );

      expect(measurer.callCount, 1);
      expect(second, first);
    });

    test('uses fractional letter spacing in the cache key', () {
      cache.measure(
        measurer: measurer,
        text: 'Hello',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 1.25,
      );

      cache.measure(
        measurer: measurer,
        text: 'Hello',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 1.5,
      );

      expect(measurer.callCount, 2);
    });

    test('forwards original Unicode text unchanged', () {
      const original = 'A🙂e\u0301👨‍👩‍👧‍👦';

      cache.measure(
        measurer: measurer,
        text: original,
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: 1.25,
      );

      expect(measurer.lastText, original);
      expect(measurer.lastLetterSpacing, 1.25);
    });

    test('supports negative letter spacing', () {
      cache.measure(
        measurer: measurer,
        text: 'Tracking',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16.0,
        letterSpacing: -0.75,
      );

      expect(measurer.lastLetterSpacing, -0.75);
    });
  });
}
