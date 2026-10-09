// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/inspector/fill_editor.dart

import 'package:flutter/material.dart';

import 'package:canvas_core/canvas_core_runtime.dart' as rt;
import 'package:canvas_editor_flutter/src/editor_api.dart' show kSceneFieldsId;
import 'package:canvas_editor_flutter/src/editor_fill.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/controls.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_context.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_fields.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_ui.dart';

const _defaultSwatchesArgb32 = <int>[
  0xFF111111,
  0xFFFFFFFF,
  0xFFE2E2E2,
  0xFFCCCCCC,
  0xFF3B82F6,
  0xFF22C55E,
  0xFFF59E0B,
  0xFFEF4444,
  0xFF8B5CF6,
  0xFF06B6D4,
];

/// Canonical mapping of a node-family fill field and its UI copy.
///
/// Important:
/// - this maps to ONE editor field
/// - gradient sub-controls are UI projections over that one CanvasFill value
/// - construction is intentionally private; built-in targets allow all fills
class FillFieldIds {
  const FillFieldIds._({
    required this.field,
    required this.fallbackColor,
    required this.kindTitle,
    required this.solidTitle,
    required this.solidLabel,
    required this.grad1Title,
    required this.grad1Label,
    required this.grad2Title,
    required this.grad2Label,
    required this.angleTitle,
  });

  final rt.CanvasFieldKey field;
  final rt.Color32 fallbackColor;

  final String kindTitle;
  final String solidTitle;
  final String solidLabel;
  final String grad1Title;
  final String grad1Label;
  final String grad2Title;
  final String grad2Label;
  final String angleTitle;

  static const text = FillFieldIds._(
    field: rt.CanvasFields.textFill,
    fallbackColor: 0xFF111111,
    kindTitle: 'Fill Type',
    solidTitle: 'Color',
    solidLabel: 'Color',
    grad1Title: 'Start Color',
    grad1Label: 'Start Color',
    grad2Title: 'End Color',
    grad2Label: 'End Color',
    angleTitle: 'Angle',
  );

  static const icon = FillFieldIds._(
    field: rt.CanvasFields.iconFill,
    fallbackColor: 0xFF111111,
    kindTitle: 'Fill Type',
    solidTitle: 'Color',
    solidLabel: 'Color',
    grad1Title: 'Start Color',
    grad1Label: 'Start Color',
    grad2Title: 'End Color',
    grad2Label: 'End Color',
    angleTitle: 'Angle',
  );

  static const path = FillFieldIds._(
    field: rt.CanvasFields.pathFill,
    fallbackColor: 0xFF000000,
    kindTitle: 'Fill Type',
    solidTitle: 'Fill Color',
    solidLabel: 'Fill Color',
    grad1Title: 'Start Color',
    grad1Label: 'Start Color',
    grad2Title: 'End Color',
    grad2Label: 'End Color',
    angleTitle: 'Angle',
  );

  static const background = FillFieldIds._(
    field: rt.CanvasFields.sceneBackgroundFill,
    fallbackColor: 0xFF000000,
    kindTitle: 'Fill Type',
    solidTitle: 'Color',
    solidLabel: 'Color',
    grad1Title: 'Start Color',
    grad1Label: 'Start Color',
    grad2Title: 'End Color',
    grad2Label: 'End Color',
    angleTitle: 'Angle',
  );
}

class FillEditor extends StatelessWidget {
  const FillEditor({
    super.key,
    required this.nodeId,
    required this.inspector,
    required this.ids,
    this.header = 'Fill',
    this.swatchesArgb32,
  });

  final rt.ElementId nodeId;
  final InspectorContext inspector;
  final FillFieldIds ids;

  /// Optional override; defaults to the standard editor swatches.
  final List<int>? swatchesArgb32;

  /// Optional section header.
  final String? header;

  String _labelForVariant(FillVariant variant) {
    return switch (variant) {
      FillVariant.none => 'None',
      FillVariant.solid => 'Solid',
      FillVariant.gradient => 'Gradient',
    };
  }

  rt.Rect2D? _referenceBounds() {
    if (nodeId == kSceneFieldsId) {
      final size = inspector.editableScene.artboardSize;
      return _usableBounds(rt.Rect2D.fromLTWH(0, 0, size.w, size.h));
    }

    return _usableBounds(
      inspector.controller.render.value.computed.layoutBoundsLocalById[nodeId],
    );
  }

  rt.Rect2D? _usableBounds(rt.Rect2D? bounds) {
    if (bounds == null ||
        !bounds.left.isFinite ||
        !bounds.top.isFinite ||
        !bounds.right.isFinite ||
        !bounds.bottom.isFinite ||
        bounds.width <= 0) {
      return null;
    }
    return bounds;
  }

  List<DropdownMenuItem<FillVariant>> _variantItems({
    required bool gradientCreationAvailable,
    required FillVariant current,
  }) {
    return [
      for (final variant in FillVariant.values)
        DropdownMenuItem(
          value: variant,
          enabled:
              variant != FillVariant.gradient ||
              gradientCreationAvailable ||
              current == FillVariant.gradient,
          child: Text(_labelForVariant(variant)),
        ),
    ];
  }

  rt.CanvasFill _fillForVariant(rt.CanvasFill current, FillVariant target) {
    return switch (target) {
      FillVariant.none => const rt.CanvasFill.none(),
      FillVariant.solid => rt.CanvasFill.solid(
        representativeColorForFill(current, ids.fallbackColor),
      ),
      FillVariant.gradient => switch (current) {
        rt.CanvasFillGradient() => current,
        _ => rt.CanvasFill.gradient(
          createDefaultGradient(
            referenceBounds: _referenceBounds()!,
            color: representativeColorForFill(current, ids.fallbackColor),
          ),
        ),
      },
    };
  }

  InspectorFieldSpec<rt.CanvasFill> _kindSpec() {
    return InspectorFieldSpec<rt.CanvasFill>(
      fieldKey: ids.field,
      title: ids.kindTitle,
      commitMode: CommitMode.immediate,
      control:
          (
            context, {
            required enabled,
            required value,
            required commit,
            begin,
            end,
            flush,
          }) {
            final current = fillVariantOf(value);
            final gradientCreationAvailable = _referenceBounds() != null;

            return LabeledDropdown<FillVariant>(
              value: current,
              items: _variantItems(
                gradientCreationAvailable: gradientCreationAvailable,
                current: current,
              ),
              onChanged: enabled
                  ? (next) {
                      if (next == null) return;
                      if (next == FillVariant.gradient &&
                          current != FillVariant.gradient &&
                          !gradientCreationAvailable) {
                        return;
                      }
                      commit(_fillForVariant(value, next));
                    }
                  : null,
            );
          },
    );
  }

  InspectorFieldSpec<rt.CanvasFill> _solidColorSpec(List<int> swatches) {
    return InspectorFieldSpec<rt.CanvasFill>(
      fieldKey: ids.field,
      title: ids.solidTitle,
      commitMode: CommitMode.immediate,
      control:
          (
            context, {
            required enabled,
            required value,
            required commit,
            begin,
            end,
            flush,
          }) {
            return SwatchPickerRow(
              label: ids.solidLabel,
              swatchesArgb32: swatches,
              selectedArgb32: representativeColorForFill(
                value,
                ids.fallbackColor,
              ),
              enabled: enabled,
              onPick: (color) {
                commit(rt.CanvasFill.solid(color));
              },
            );
          },
    );
  }

  InspectorFieldSpec<rt.CanvasFill> _gradientColor1Spec(List<int> swatches) {
    return InspectorFieldSpec<rt.CanvasFill>(
      fieldKey: ids.field,
      title: ids.grad1Title,
      commitMode: CommitMode.immediate,
      control:
          (
            context, {
            required enabled,
            required value,
            required commit,
            begin,
            end,
            flush,
          }) {
            final g = switch (value) {
              rt.CanvasFillGradient(grad: final gradient) => gradient,
              _ => null,
            };
            if (g == null || g.stops.isEmpty) {
              return const SizedBox.shrink();
            }
            return SwatchPickerRow(
              label: ids.grad1Label,
              swatchesArgb32: swatches,
              selectedArgb32: g.stops.first.color,
              enabled: enabled,
              onPick: (color) {
                commit(
                  rt.CanvasFill.gradient(
                    replaceGradientStopColor(g, index: 0, color: color),
                  ),
                );
              },
            );
          },
    );
  }

  InspectorFieldSpec<rt.CanvasFill> _gradientColor2Spec(List<int> swatches) {
    return InspectorFieldSpec<rt.CanvasFill>(
      fieldKey: ids.field,
      title: ids.grad2Title,
      commitMode: CommitMode.immediate,
      control:
          (
            context, {
            required enabled,
            required value,
            required commit,
            begin,
            end,
            flush,
          }) {
            final g = switch (value) {
              rt.CanvasFillGradient(grad: final gradient) => gradient,
              _ => null,
            };
            if (g == null || g.stops.isEmpty) {
              return const SizedBox.shrink();
            }
            return SwatchPickerRow(
              label: ids.grad2Label,
              swatchesArgb32: swatches,
              selectedArgb32: g.stops.last.color,
              enabled: enabled,
              onPick: (color) {
                commit(
                  rt.CanvasFill.gradient(
                    replaceGradientStopColor(
                      g,
                      index: g.stops.length - 1,
                      color: color,
                    ),
                  ),
                );
              },
            );
          },
    );
  }

  InspectorFieldSpec<rt.CanvasFill> _gradientAngleSpec() {
    return InspectorFieldSpec<rt.CanvasFill>(
      fieldKey: ids.field,
      title: ids.angleTitle,
      commitMode: CommitMode.dragTxn,
      control:
          (
            context, {
            required enabled,
            required value,
            required commit,
            begin,
            end,
            flush,
          }) {
            final g = switch (value) {
              rt.CanvasFillGradient(grad: final gradient) => gradient,
              _ => null,
            };
            if (g == null) return const SizedBox.shrink();
            return LabeledSlider(
              label: ids.angleTitle,
              value: linearGradientAngleDegrees(g),
              min: 0,
              max: 360,
              enabled: enabled,
              onChangeStart: (_) => begin?.call(),
              onChanged: (angle) {
                commit(
                  rt.CanvasFill.gradient(
                    setLinearGradientAngleDegrees(g, angle),
                  ),
                );
              },
              onChangeEnd: (_) => end?.call(),
            );
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    final swatches = swatchesArgb32 ?? _defaultSwatchesArgb32;

    final kindSpec = _kindSpec();

    final currentFill = inspector.controller
        .getField<rt.CanvasFill>(nodeId, kindSpec.fieldKey)
        .value;

    final kind = fillVariantOf(currentFill);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null) ...[
          Text(header!, style: Theme.of(context).textTheme.titleSmall),
          const Gap(8),
        ],

        inspector.fieldRow<rt.CanvasFill>(nodeId, kindSpec),

        if (kind == FillVariant.solid) ...[
          const Gap(12),
          inspector.fieldRow<rt.CanvasFill>(nodeId, _solidColorSpec(swatches)),
        ],

        if (kind == FillVariant.gradient) ...[
          const Gap(12),
          inspector.fieldRow<rt.CanvasFill>(
            nodeId,
            _gradientColor1Spec(swatches),
          ),
          const Gap(12),
          inspector.fieldRow<rt.CanvasFill>(
            nodeId,
            _gradientColor2Spec(swatches),
          ),
          const Gap(12),
          inspector.fieldRow<rt.CanvasFill>(nodeId, _gradientAngleSpec()),
        ],
      ],
    );
  }
}
