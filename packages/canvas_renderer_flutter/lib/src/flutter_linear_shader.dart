// Path: lib/src/flutter_linear_shader.dart
//
// The current angle/width gradient semantics are a Flutter painting detail.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:canvas_core/canvas_core_runtime.dart' show LinearGradientSpec;

ui.Shader buildLinearShaderFlutter(
  ui.Size size,
  LinearGradientSpec spec, {
  double opacity = 1.0,
}) {
  final theta = spec.angle * math.pi / 180.0;
  final direction = ui.Offset(math.cos(theta), math.sin(theta));
  final center = ui.Offset(size.width / 2, size.height / 2);
  final half = math.max(size.width, size.height).toDouble();
  final width = spec.width.clamp(0, 50) / 100.0;

  ui.Color color(int argb) {
    final alpha = ((argb >> 24) & 0xFF);
    final merged = (alpha * opacity).clamp(0, 255).round();
    return ui.Color((merged << 24) | (argb & 0x00FFFFFF));
  }

  return ui.Gradient.linear(
    center - direction * half,
    center + direction * half,
    [color(spec.color1), color(spec.color2)],
    [(0.5 - width).clamp(0.0, 1.0), (0.5 + width).clamp(0.0, 1.0)],
  );
}
