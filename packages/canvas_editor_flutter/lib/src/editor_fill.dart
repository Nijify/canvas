// Path: oss_packages/canvas_editor_flutter/lib/src/editor_fill.dart

import 'dart:math' as math;

import 'package:canvas_core/canvas_core_runtime.dart' as rt;

/// Editor-facing fill variants.
///
/// This is intentionally a UI/editing discriminator over [rt.CanvasFill],
/// not a persisted field and not a separate document model.
enum FillVariant { none, solid, gradient }

FillVariant fillVariantOf(rt.CanvasFill fill) {
  return switch (fill) {
    rt.CanvasFillNone() => FillVariant.none,
    rt.CanvasFillSolid() => FillVariant.solid,
    rt.CanvasFillGradient() => FillVariant.gradient,
  };
}

/// An opaque color for inspector swatches and fill-variant conversions.
///
/// Zero colors fall back to [fallbackColor]. Partially transparent RGB colors
/// retain their RGB channels but are made opaque for visibility.
int representativeColorForFill(rt.CanvasFill fill, rt.Color32 fallbackColor) {
  int color = switch (fill) {
    rt.CanvasFillSolid(color: final value) => value,
    rt.CanvasFillGradient(grad: final gradient) =>
      gradient.stops.isEmpty ? 0xFF000000 : gradient.stops.first.color,
    rt.CanvasFillNone() => fallbackColor,
  };

  if (color == 0) color = fallbackColor;

  // Avoid invisible fallback swatches when an RGB color has alpha == 0.
  final alpha = (color >> 24) & 0xFF;
  if (alpha == 0) color = 0xFF000000 | (color & 0x00FFFFFF);

  return color;
}

/// Creates the standard horizontal gradient for a target with real local
/// bounds. Callers intentionally own the geometry lookup; existing-gradient
/// editing never needs it.
rt.LinearGradientSpec createDefaultGradient({
  required rt.Rect2D referenceBounds,
  required rt.Color32 color,
}) {
  final values = <double>[
    referenceBounds.left,
    referenceBounds.top,
    referenceBounds.right,
    referenceBounds.bottom,
  ];
  if (values.any((value) => !value.isFinite) || referenceBounds.width <= 0) {
    throw ArgumentError.value(
      referenceBounds,
      'referenceBounds',
      'must be finite with positive width',
    );
  }

  final centerY = (referenceBounds.top + referenceBounds.bottom) / 2.0;
  return rt.LinearGradientSpec(
    start: rt.Vec2(referenceBounds.left, centerY),
    end: rt.Vec2(referenceBounds.right, centerY),
    stops: <rt.GradientStop>[
      rt.GradientStop(offset: 0, color: color),
      rt.GradientStop(offset: 1, color: color),
    ],
  );
}

rt.LinearGradientSpec replaceGradientStopColor(
  rt.LinearGradientSpec gradient, {
  required int index,
  required rt.Color32 color,
}) {
  RangeError.checkValidIndex(index, gradient.stops, 'index');
  return gradient.copyWith(
    stops: <rt.GradientStop>[
      for (var stopIndex = 0; stopIndex < gradient.stops.length; stopIndex++)
        stopIndex == index
            ? gradient.stops[stopIndex].copyWith(color: color)
            : gradient.stops[stopIndex],
    ],
  );
}

double linearGradientAngleDegrees(rt.LinearGradientSpec gradient) {
  final delta = gradient.end - gradient.start;
  var degrees = math.atan2(delta.y, delta.x) * 180.0 / math.pi;
  if (degrees < 0) degrees += 360.0;
  return degrees;
}

rt.LinearGradientSpec setLinearGradientAngleDegrees(
  rt.LinearGradientSpec gradient,
  double angleDegrees,
) {
  if (!angleDegrees.isFinite) {
    throw ArgumentError.value(angleDegrees, 'angleDegrees', 'must be finite');
  }

  final delta = gradient.end - gradient.start;
  final halfLength = delta.length / 2.0;
  if (!halfLength.isFinite || halfLength <= 0) {
    throw ArgumentError.value(
      gradient,
      'gradient',
      'must have distinct finite endpoints',
    );
  }

  final center = (gradient.start + gradient.end) / 2.0;
  final radians = angleDegrees * math.pi / 180.0;
  final halfVector = rt.Vec2(
    math.cos(radians) * halfLength,
    math.sin(radians) * halfLength,
  );

  return gradient.copyWith(
    start: center - halfVector,
    end: center + halfVector,
  );
}
