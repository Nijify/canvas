// Path: packages/canvas_renderer_flutter/test/flutter_text_pipeline_test.dart

import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart' show Size2D, TextMeasurer;
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterTextPipeline pipeline;

  setUp(() {
    pipeline = FlutterTextPipeline();
  });

  tearDown(() {
    pipeline.dispose();
  });

  Size2D measure({String text = 'Hello', double letterSpacing = 0}) {
    return pipeline.measure(
      text: text,
      fontFamily: 'Roboto',
      fontWeight: 400,
      fontSize: 20,
      letterSpacing: letterSpacing,
    );
  }

  group('FlutterTextPipeline', () {
    test('implements TextMeasurer directly', () {
      expect(pipeline, isA<TextMeasurer>());
    });

    test('reuses cached layout for identical measurements', () {
      measure(letterSpacing: 1.25);
      expect(pipeline.cacheSize, 1);

      measure(letterSpacing: 1.25);
      expect(pipeline.cacheSize, 1);
    });

    test('includes fractional letter spacing in cache key', () {
      measure(letterSpacing: 1.25);
      measure(letterSpacing: 1.5);

      expect(pipeline.cacheSize, 2);
    });

    test('positive letter spacing increases measured width', () {
      final unspaced = measure(text: 'AAAA');
      final spaced = measure(text: 'AAAA', letterSpacing: 2);

      expect(spaced.w, greaterThan(unspaced.w));
    });

    test('accepts raw Unicode and negative letter spacing', () {
      final size = measure(text: 'A🙂e\u0301👨‍👩‍👧‍👦', letterSpacing: -0.75);

      expect(size.w, isNonNegative);
      expect(size.h, greaterThan(0));
    });

    test('evicts layouts at the configured limit', () {
      pipeline.dispose();
      pipeline = FlutterTextPipeline(maxEntries: 2);

      measure(text: 'one');
      measure(text: 'two');
      measure(text: 'three');

      expect(pipeline.cacheSize, 2);
    });

    test('clearCache empties the cache and permits reuse', () {
      measure();
      expect(pipeline.cacheSize, 1);

      pipeline.clearCache();
      expect(pipeline.cacheSize, 0);

      measure();
      expect(pipeline.cacheSize, 1);
    });

    test('dispose is idempotent and measurement becomes unavailable', () {
      measure();

      pipeline.dispose();
      pipeline.dispose();

      expect(pipeline.cacheSize, 0);
      expect(measure, throwsStateError);
    });

    test('painting after disposal throws StateError', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      pipeline.dispose();

      expect(
        () => pipeline.paint(
          canvas,
          ui.Offset.zero,
          const TextSpec('Hello', 'Roboto', 400, 20),
        ),
        throwsStateError,
      );

      recorder.endRecording().dispose();
    });
  });
}
