// Path: test/flutter_text_measurer_test.dart

import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapturingMeasurePipeline extends FlutterTextPipeline {
  TextSpec? lastSpec;

  @override
  TextMetrics measure(TextSpec s) {
    lastSpec = s;
    return const TextMetrics(120.0, 24.0, 18.0);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FlutterTextMeasurer forwards raw text and fractional spacing', () {
    final pipeline = _CapturingMeasurePipeline();
    final measurer = FlutterTextMeasurer(pipeline);

    const original = 'A🙂e\u0301👨‍👩‍👧‍👦';

    final size = measurer.measure(
      text: original,
      fontFamily: 'Roboto',
      fontWeight: 400,
      fontSize: 20.0,
      letterSpacing: 1.25,
    );

    expect(pipeline.lastSpec, isNotNull);
    expect(pipeline.lastSpec!.text, original);
    expect(pipeline.lastSpec!.family, 'Roboto');
    expect(pipeline.lastSpec!.weight, 400);
    expect(pipeline.lastSpec!.size, 20.0);
    expect(pipeline.lastSpec!.letterSpacing, 1.25);

    expect(size.w, 120.0);
    expect(size.h, 24.0);
  });

  test('FlutterTextMeasurer forwards negative spacing', () {
    final pipeline = _CapturingMeasurePipeline();
    final measurer = FlutterTextMeasurer(pipeline);

    measurer.measure(
      text: 'Tracking',
      fontFamily: 'Roboto',
      fontWeight: 500,
      fontSize: 16.0,
      letterSpacing: -0.5,
    );

    expect(pipeline.lastSpec!.letterSpacing, -0.5);
  });
}
