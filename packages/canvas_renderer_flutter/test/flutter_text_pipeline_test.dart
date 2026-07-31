// Path: test/flutter_text_pipeline_test.dart

import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterTextPipeline', () {
    test('reuses cached layout for identical specs', () {
      final pipeline = FlutterTextPipeline();

      const spec = TextSpec('Hello', 'Roboto', 400, 20.0, letterSpacing: 1.25);

      pipeline.measure(spec);
      expect(pipeline.cacheSize, 1);

      pipeline.measure(spec);
      expect(pipeline.cacheSize, 1);
    });

    test('includes fractional letter spacing in cache key', () {
      final pipeline = FlutterTextPipeline();

      pipeline.measure(
        const TextSpec('Hello', 'Roboto', 400, 20.0, letterSpacing: 1.25),
      );

      pipeline.measure(
        const TextSpec('Hello', 'Roboto', 400, 20.0, letterSpacing: 1.5),
      );

      expect(pipeline.cacheSize, 2);
    });

    test('positive letter spacing increases measured width', () {
      final pipeline = FlutterTextPipeline();

      final unspaced = pipeline.measure(
        const TextSpec('AAAA', 'Roboto', 400, 20.0),
      );

      final spaced = pipeline.measure(
        const TextSpec('AAAA', 'Roboto', 400, 20.0, letterSpacing: 2.0),
      );

      expect(spaced.width, greaterThan(unspaced.width));
    });

    test('accepts negative letter spacing', () {
      final pipeline = FlutterTextPipeline();

      final metrics = pipeline.measure(
        const TextSpec('Tracking', 'Roboto', 400, 20.0, letterSpacing: -0.75),
      );

      expect(metrics.width, isNonNegative);
      expect(metrics.height, greaterThan(0));
    });

    test('different zero and negative spacing values use separate entries', () {
      final pipeline = FlutterTextPipeline();

      pipeline.measure(const TextSpec('Tracking', 'Roboto', 400, 20.0));

      pipeline.measure(
        const TextSpec('Tracking', 'Roboto', 400, 20.0, letterSpacing: -0.75),
      );

      expect(pipeline.cacheSize, 2);
    });
  });
}
