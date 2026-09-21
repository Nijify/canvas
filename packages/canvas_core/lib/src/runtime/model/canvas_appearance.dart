import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/foundation/paint/canvas_fill.dart';
import 'package:canvas_core/src/serialization/converters.dart';

part 'canvas_appearance.freezed.dart';
part 'canvas_appearance.g.dart';

/// Ordered paint that derives independently from the original source
/// silhouette and is painted before the authored foreground.
///
/// Index 0 is backmost.
///
/// Every underlay derives from the original source silhouette. Underlays never
/// consume the output of a preceding underlay.
///
/// Freezed owns the immutable value model. The persisted wire format is owned
/// explicitly by [_CanvasSourceUnderlayJsonConverter] so the discriminator
/// remains stable even while there is only one underlay variant.
@freezed
sealed class CanvasSourceUnderlay with _$CanvasSourceUnderlay {
  const factory CanvasSourceUnderlay.shadow({
    required String id,
    @Default(true) bool enabled,
    @Vec2Converter() required Vec2 offset,
    @Default(0.0) double blurSigma,
    required Color32 color,
  }) = ShadowEffect;
}

/// Stable persisted wire format for source underlays.
///
/// Do not rely on Freezed's union serialization here. A single-variant Freezed
/// union does not currently persist its discriminator.
final class _CanvasSourceUnderlayJsonConverter
    implements JsonConverter<CanvasSourceUnderlay, Map<String, dynamic>> {
  const _CanvasSourceUnderlayJsonConverter();

  @override
  CanvasSourceUnderlay fromJson(Map<String, dynamic> json) {
    final type = json['type'];

    if (type is! String) {
      throw const FormatException(
        'CanvasSourceUnderlay requires string field "type"',
      );
    }

    switch (type) {
      case 'shadow':
        final id = json['id'];
        final enabled = json['enabled'];
        final offset = json['offset'];
        final blurSigma = json['blurSigma'];
        final color = json['color'];

        if (id is! String) {
          throw const FormatException(
            'Shadow underlay requires string field "id"',
          );
        }

        if (enabled != null && enabled is! bool) {
          throw const FormatException(
            'Shadow underlay "enabled" must be a bool',
          );
        }

        if (offset is! Map) {
          throw const FormatException(
            'Shadow underlay requires map field "offset"',
          );
        }

        if (blurSigma != null && blurSigma is! num) {
          throw const FormatException(
            'Shadow underlay "blurSigma" must be numeric',
          );
        }

        if (color is! num) {
          throw const FormatException(
            'Shadow underlay requires numeric field "color"',
          );
        }

        return CanvasSourceUnderlay.shadow(
          id: id,
          enabled: enabled as bool? ?? true,
          offset: const Vec2Converter().fromJson(
            offset.cast<String, dynamic>(),
          ),
          blurSigma: (blurSigma as num?)?.toDouble() ?? 0.0,
          color: color.toInt(),
        );

      default:
        throw FormatException('Unknown CanvasSourceUnderlay type: $type');
    }
  }

  @override
  Map<String, dynamic> toJson(CanvasSourceUnderlay value) {
    return switch (value) {
      ShadowEffect(
        :final id,
        :final enabled,
        :final offset,
        :final blurSigma,
        :final color,
      ) =>
        <String, dynamic>{
          'type': 'shadow',
          'id': id,
          'enabled': enabled,
          'offset': const Vec2Converter().toJson(offset),
          'blurSigma': blurSigma,
          'color': color,
        },
    };
  }
}

/// Appearance shared by text and icon sources.
///
/// [foreground] controls whether/how the authored source itself is painted.
/// `CanvasFill.none()` is valid: the source silhouette still exists and may be
/// consumed by [underlays].
///
/// Underlays are painted back-to-front before the foreground.
@freezed
abstract class CanvasAppearance with _$CanvasAppearance {
  const factory CanvasAppearance({
    @CanvasFillConverter()
    @Default(CanvasFill.solid(0xFF111111))
    CanvasFill foreground,

    @_CanvasSourceUnderlayJsonConverter()
    @Default(<CanvasSourceUnderlay>[])
    List<CanvasSourceUnderlay> underlays,
  }) = _CanvasAppearance;

  factory CanvasAppearance.fromJson(Map<String, dynamic> json) =>
      _$CanvasAppearanceFromJson(json);
}
