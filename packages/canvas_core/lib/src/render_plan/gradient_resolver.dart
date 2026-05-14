// Path: lib/src/render_plan/gradient_resolver.dart

// Pure Dart (no Flutter): gradient math shared by all renderers.
// Converts LinearGradientSpec + canvas Size2D into concrete endpoints,
// stops, and ARGB colors with merged opacity.

import 'dart:math' as math;

import 'package:canvas_core/src/foundation/core_types.dart'; // Color32, Size2D, Vec2, LinearGradientSpec

class ResolvedLinearGradient {
  final Vec2 start; // gradient line start in canvas coords
  final Vec2 end; // gradient line end in canvas coords
  final List<Color32> colors; // ARGB colors (opacity already merged)
  final List<double> stops; // 0..1 (same length as colors)

  const ResolvedLinearGradient(this.start, this.end, this.colors, this.stops);
}

/// Resolve editor semantics into renderer-agnostic data:
/// - angle (deg) → line direction
/// - width (0..50) → two symmetric stops around 0.5
/// - opacity multiplier merged into ARGB alpha
ResolvedLinearGradient resolveLinearGradient(
  LinearGradientSpec spec,
  Size2D size, {
  double opacity = 1.0,
}) {
  // Direction unit vector from angle (degrees)
  final theta = spec.angle * math.pi / 180.0;
  final dir = Vec2(math.cos(theta), math.sin(theta));

  // Cover entire canvas by extending from center both ways
  final center = Vec2(size.w / 2, size.h / 2);
  final half = math.max(size.w, size.h).toDouble();
  final start = Vec2(center.x - dir.x * half, center.y - dir.y * half);
  final end = Vec2(center.x + dir.x * half, center.y + dir.y * half);

  // Two stops centered around 0.5; width=0..50 maps to 0..0.5
  final w = (spec.width.clamp(0, 50)) / 100.0; // 0..0.5
  final s1 = (0.5 - w).clamp(0.0, 1.0);
  final s2 = (0.5 + w).clamp(0.0, 1.0);
  final stops = <double>[s1, s2];

  // Merge opacity into alpha
  Color32 merge(Color32 argb) {
    final a = (argb >> 24) & 0xFF;
    final mergedA = (a * opacity).clamp(0, 255).round();
    return (mergedA << 24) | (argb & 0x00FFFFFF);
    // (ARGB layout: 0xAARRGGBB)
  }

  final colors = <Color32>[merge(spec.color1), merge(spec.color2)];

  return ResolvedLinearGradient(start, end, colors, stops);
}
