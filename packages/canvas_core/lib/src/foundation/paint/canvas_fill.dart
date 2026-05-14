// Path: lib/src/foundation/paint/canvas_fill.dart

import 'package:canvas_core/src/foundation/core_types.dart'
    show LinearGradientSpec;

/// Single source-of-truth fill for runtime.
/// No backward-compat: only accepts the new {type: ...} JSON shape.
sealed class CanvasFill {
  const CanvasFill();

  const factory CanvasFill.none() = CanvasFillNone;
  const factory CanvasFill.solid(int color) = CanvasFillSolid;
  const factory CanvasFill.gradient(LinearGradientSpec grad) =
      CanvasFillGradient;

  Map<String, Object?> toJson();

  static CanvasFill fromJson(Map<String, Object?> json) {
    final type = json['type'];
    if (type is! String) {
      throw const FormatException('CanvasFill requires string field "type"');
    }

    switch (type) {
      case 'none':
        return const CanvasFillNone();

      case 'solid':
        final c = json['color'];
        if (c is! num) {
          throw const FormatException(
            'CanvasFillSolid requires numeric "color"',
          );
        }
        return CanvasFillSolid(c.toInt());

      case 'gradient':
        final g = json['grad'];
        if (g is! Map) {
          throw const FormatException('CanvasFillGradient requires map "grad"');
        }
        return CanvasFillGradient(
          LinearGradientSpec.fromJson(g.cast<String, dynamic>()),
        );

      default:
        throw FormatException('Unknown CanvasFill type: $type');
    }
  }
}

final class CanvasFillNone extends CanvasFill {
  const CanvasFillNone();
  @override
  Map<String, Object?> toJson() => const {'type': 'none'};

  @override
  bool operator ==(Object other) => other is CanvasFillNone;
  @override
  int get hashCode => 0;
}

final class CanvasFillSolid extends CanvasFill {
  const CanvasFillSolid(this.color);
  final int color;

  @override
  Map<String, Object?> toJson() => {'type': 'solid', 'color': color};

  @override
  bool operator ==(Object other) =>
      other is CanvasFillSolid && other.color == color;
  @override
  int get hashCode => color.hashCode;
}

final class CanvasFillGradient extends CanvasFill {
  const CanvasFillGradient(this.grad);
  final LinearGradientSpec grad;

  @override
  Map<String, Object?> toJson() => {'type': 'gradient', 'grad': grad.toJson()};

  @override
  bool operator ==(Object other) =>
      other is CanvasFillGradient && other.grad == grad;
  @override
  int get hashCode => grad.hashCode;
}
