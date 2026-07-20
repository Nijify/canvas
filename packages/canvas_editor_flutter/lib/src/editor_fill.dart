// Path: oss_packages/canvas_editor_flutter/lib/src/editor_fill.dart

import 'package:canvas_core/canvas_core_runtime.dart' as rt;

/// Editor-facing fill variants.
///
/// This is intentionally a UI/editing discriminator over [rt.CanvasFill],
/// not a persisted field and not a separate document model.
enum FillVariant { none, solid, gradient }

class FillCapability {
  const FillCapability({required this.allowed, required this.fallback});

  final Set<FillVariant> allowed;
  final rt.CanvasFill fallback;

  bool allows(FillVariant variant) => allowed.contains(variant);
}

const kTextFillCapability = FillCapability(
  allowed: {FillVariant.solid, FillVariant.gradient},
  fallback: rt.CanvasFill.solid(0xFF111111),
);

const kIconFillCapability = FillCapability(
  allowed: {FillVariant.solid, FillVariant.gradient},
  fallback: rt.CanvasFill.solid(0xFF111111),
);

const kPathFillCapability = FillCapability(
  allowed: {FillVariant.none, FillVariant.solid, FillVariant.gradient},
  fallback: rt.CanvasFill.solid(0xFF000000),
);

const kBackgroundFillCapability = FillCapability(
  allowed: {FillVariant.none, FillVariant.solid, FillVariant.gradient},
  fallback: rt.CanvasFill.none(),
);

FillCapability fillCapabilityForNode(rt.Node node) {
  return switch (node) {
    rt.TextNode() => kTextFillCapability,
    rt.IconNode() => kIconFillCapability,
    rt.PathNode() => kPathFillCapability,
    _ => const FillCapability(
      allowed: {FillVariant.solid},
      fallback: rt.CanvasFill.solid(0xFF000000),
    ),
  };
}

FillVariant fillVariantOf(rt.CanvasFill fill) {
  return switch (fill) {
    rt.CanvasFillNone() => FillVariant.none,
    rt.CanvasFillSolid() => FillVariant.solid,
    rt.CanvasFillGradient() => FillVariant.gradient,
  };
}

int representativeColorForFill(rt.CanvasFill fill, FillCapability capability) {
  int c = switch (fill) {
    rt.CanvasFillSolid(color: final color) => color,
    rt.CanvasFillGradient(grad: final g) => g.color1,
    rt.CanvasFillNone() => _representativeColorForFallback(capability),
  };

  if (c == 0) c = _representativeColorForFallback(capability);

  // Avoid invisible fallback swatches when an RGB color has alpha == 0.
  final a = (c >> 24) & 0xFF;
  if (a == 0) c = 0xFF000000 | (c & 0x00FFFFFF);

  return c;
}

int _representativeColorForFallback(FillCapability capability) {
  return switch (capability.fallback) {
    rt.CanvasFillSolid(color: final color) => color,
    rt.CanvasFillGradient(grad: final g) => g.color1,
    rt.CanvasFillNone() => 0xFF000000,
  };
}

rt.LinearGradientSpec gradientForEditing(
  rt.CanvasFill fill,
  FillCapability capability, {
  double defaultAngle = 0,
  double defaultWidth = 20,
}) {
  return switch (fill) {
    rt.CanvasFillGradient(grad: final g) => g,
    rt.CanvasFillSolid(color: final c) => rt.LinearGradientSpec(
      color1: c,
      color2: c,
      angle: defaultAngle,
      width: defaultWidth,
    ),
    _ => rt.LinearGradientSpec(
      color1: representativeColorForFill(fill, capability),
      color2: representativeColorForFill(fill, capability),
      angle: defaultAngle,
      width: defaultWidth,
    ),
  };
}

rt.CanvasFill coerceFill(rt.CanvasFill fill, FillCapability capability) {
  final variant = fillVariantOf(fill);
  if (capability.allows(variant)) return fill;

  if (capability.allows(FillVariant.solid)) {
    return rt.CanvasFill.solid(representativeColorForFill(fill, capability));
  }

  if (capability.allows(FillVariant.gradient)) {
    return rt.CanvasFill.gradient(gradientForEditing(fill, capability));
  }

  if (capability.allows(FillVariant.none)) {
    return const rt.CanvasFill.none();
  }

  return capability.fallback;
}

rt.CanvasFill coerceFillForNode(rt.Node node, rt.CanvasFill fill) {
  return coerceFill(fill, fillCapabilityForNode(node));
}

rt.CanvasFill convertFillVariant(
  rt.CanvasFill current,
  FillVariant target,
  FillCapability capability,
) {
  if (!capability.allows(target)) {
    return coerceFill(current, capability);
  }

  switch (target) {
    case FillVariant.none:
      return const rt.CanvasFill.none();

    case FillVariant.solid:
      return rt.CanvasFill.solid(
        representativeColorForFill(current, capability),
      );

    case FillVariant.gradient:
      if (current is rt.CanvasFillGradient) {
        return coerceFill(current, capability);
      }
      return rt.CanvasFill.gradient(gradientForEditing(current, capability));
  }
}

class LinearGradientPatch {
  const LinearGradientPatch({this.color1, this.color2, this.angle, this.width});

  final int? color1;
  final int? color2;
  final double? angle;
  final double? width;
}

rt.CanvasFill patchLinearGradient(
  rt.CanvasFill current,
  LinearGradientPatch patch,
  FillCapability capability,
) {
  final g = gradientForEditing(current, capability);

  return coerceFill(
    rt.CanvasFill.gradient(
      g.copyWith(
        color1: patch.color1 ?? g.color1,
        color2: patch.color2 ?? g.color2,
        angle: patch.angle ?? g.angle,
        width: patch.width ?? g.width,
      ),
    ),
    capability,
  );
}
