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
/// The constructor snapshots [dash]; later changes to the caller's list cannot
/// change this stroke, equality, or an editor history entry.
@freezed
@JsonSerializable()
class CanvasStroke with _$CanvasStroke {
  CanvasStroke({
    required this.color,
    this.width = 4.0,
    this.cap = StrokeCap.butt,
    this.join = StrokeJoin.miter,
    this.miterLimit = 4.0,
    List<double> dash = const <double>[],
  }) : dash = List<double>.unmodifiable(dash);

  final Color32 color;
  final double width;
  final StrokeCap cap;
  final StrokeJoin join;
  final double miterLimit;
  final List<double> dash;

  factory CanvasStroke.fromJson(Map<String, dynamic> json) =>
      _$CanvasStrokeFromJson(json);

  Map<String, dynamic> toJson() => _$CanvasStrokeToJson(this);
}
