// Path: lib/src/flutter_linear_shader.dart
//
import 'dart:ui' as ui;
import 'package:canvas_core/canvas_core_runtime.dart' show LinearGradientSpec;

ui.Shader buildLinearShaderFlutter(
  LinearGradientSpec spec, {
  double opacity = 1.0,
}) {
  ui.Color color(int argb) {
    final alpha = ((argb >> 24) & 0xFF);
    final merged = (alpha * opacity).clamp(0, 255).round();
    return ui.Color((merged << 24) | (argb & 0x00FFFFFF));
  }

  return ui.Gradient.linear(
    ui.Offset(spec.start.x, spec.start.y),
    ui.Offset(spec.end.x, spec.end.y),
    [for (final stop in spec.stops) color(stop.color)],
    [for (final stop in spec.stops) stop.offset],
    ui.TileMode.clamp,
  );
}
