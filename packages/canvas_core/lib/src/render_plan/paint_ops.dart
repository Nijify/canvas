// Path: oss_packages/canvas_core/lib/src/render_plan/paint_ops.dart

import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;
import 'package:canvas_core/src/foundation/core_types.dart' show Color32, Vec2;
import 'package:canvas_core/src/foundation/ids.dart' show ElementId;
import 'package:canvas_core/src/render_plan/gradient_resolver.dart'
    show ResolvedLinearGradient;
import 'package:canvas_core/src/path/path_ir.dart';

sealed class PaintOp {}

class SaveOp extends PaintOp {}

class RestoreOp extends PaintOp {}

class SetTransformOp extends PaintOp {
  final double a, b, c, d, e, f;
  SetTransformOp(this.a, this.b, this.c, this.d, this.e, this.f);

  bool get isIdentity =>
      a == 1.0 && b == 0.0 && c == 0.0 && d == 1.0 && e == 0.0 && f == 0.0;
}

class FillRectOp extends PaintOp {
  FillRectOp(this.r, this.color);
  final Rect2D r;
  final Color32 color;
}

class FillPathOp extends PaintOp {
  final PathIR path;
  FillPathOp(this.path);
}

class StrokePathOp extends PaintOp {
  final PathIR path;
  StrokePathOp(this.path);
}

class DrawImageOp extends PaintOp {
  DrawImageOp(this.id, this.src, this.dst);
  final ElementId id;
  final Rect2D src, dst;
}

class DrawTextOp extends PaintOp {
  DrawTextOp({
    required this.text,
    required this.family,
    required this.weight,
    required this.size,
    required this.originBaselineCenter,
    this.gradient,
    this.solid,
    this.shadowOffset = 0,
  });
  final String text;
  final String family;
  final int weight;
  final double size;
  final Vec2 originBaselineCenter; // already decided by core
  final ResolvedLinearGradient? gradient;
  final Color32? solid; // used for shadow or solid text
  final double shadowOffset;
}

// NEW: gradient fill for a rectangular area (e.g. whole artboard)
class FillRectGradientOp extends PaintOp {
  final Rect2D r;
  final ResolvedLinearGradient gradient;
  FillRectGradientOp(this.r, this.gradient);
}

class FillPathGradientOp extends PaintOp {
  final PathIR path;
  final ResolvedLinearGradient gradient;
  FillPathGradientOp(this.path, this.gradient);
}
