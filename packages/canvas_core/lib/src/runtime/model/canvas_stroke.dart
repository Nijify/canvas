import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:canvas_core/src/foundation/core_types.dart' show Color32;
import 'package:canvas_core/src/foundation/style/style_types.dart'
    show StrokeCap, StrokeJoin;

part 'canvas_stroke.freezed.dart';
part 'canvas_stroke.g.dart';

/// Authored stroke settings, including configurations that paint no pixels.
///
/// A null appearance stroke means no configured stroke. Transparent colors
/// and zero width retain the remaining settings for subsequent edits.
/// Dash lengths are finite, nonnegative document units; an empty list means
/// solid. Odd-length lists repeat when evaluated. Dash painting is not yet
/// supported, but the authored sequence is preserved without normalization.
@freezed
abstract class CanvasStroke with _$CanvasStroke {
  const factory CanvasStroke({
    required Color32 color,
    @Default(4.0) double width,
    @Default(StrokeCap.butt) StrokeCap cap,
    @Default(StrokeJoin.miter) StrokeJoin join,
    @Default(4.0) double miterLimit,
    @Default(<double>[]) List<double> dash,
  }) = _CanvasStroke;

  factory CanvasStroke.fromJson(Map<String, dynamic> json) =>
      _$CanvasStrokeFromJson(json);
}
