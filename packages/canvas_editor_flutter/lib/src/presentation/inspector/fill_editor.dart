// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/inspector/fill_editor.dart

import 'package:flutter/material.dart';

import 'package:canvas_core/canvas_core_runtime.dart' as rt;
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
/// - construction is intentionally private so FillCapability stays internal to
///   the built-in fill implementation
class FillFieldIds {
  const FillFieldIds._({
    required this.field,
    required FillCapability capability,
    required this.kindTitle,
    required this.solidTitle,
    required this.solidLabel,
    required this.grad1Title,
    required this.grad1Label,
    required this.grad2Title,
    required this.grad2Label,
    required this.angleTitle,
    required this.widthTitle,
  }) : _capability = capability;

  final rt.CanvasFieldKey field;
  final FillCapability _capability;

  final String kindTitle;
  final String solidTitle;
  final String solidLabel;
  final String grad1Title;
  final String grad1Label;
  final String grad2Title;
  final String grad2Label;
  final String angleTitle;
  final String widthTitle;

  static const text = FillFieldIds._(
    field: rt.CanvasFields.textFill,
    capability: kTextFillCapability,
    kindTitle: 'Fill Type',
    solidTitle: 'Color',
    solidLabel: 'Color',
    grad1Title: 'Color 1',
    grad1Label: 'Color 1',
    grad2Title: 'Color 2',
    grad2Label: 'Color 2',
    angleTitle: 'Angle',
    widthTitle: 'Width',
  );

  static const icon = FillFieldIds._(
    field: rt.CanvasFields.iconFill,
    capability: kIconFillCapability,
    kindTitle: 'Fill Type',
    solidTitle: 'Color',
    solidLabel: 'Color',
    grad1Title: 'Gradient 1',
    grad1Label: 'Gradient 1',
    grad2Title: 'Gradient 2',
    grad2Label: 'Gradient 2',
    angleTitle: 'Angle',
    widthTitle: 'Width',
  );

  static const path = FillFieldIds._(
    field: rt.CanvasFields.pathFill,
    capability: kPathFillCapability,
    kindTitle: 'Fill Type',
    solidTitle: 'Fill Color',
    solidLabel: 'Fill Color',
    grad1Title: 'Color 1',
    grad1Label: 'Color 1',
    grad2Title: 'Color 2',
    grad2Label: 'Color 2',
    angleTitle: 'Angle',
    widthTitle: 'Width',
  );

  static const background = FillFieldIds._(
    field: rt.CanvasFields.sceneBackgroundFill,
    capability: kBackgroundFillCapability,
    kindTitle: 'Fill Type',
    solidTitle: 'Color',
    solidLabel: 'Color',
    grad1Title: 'Color 1',
    grad1Label: 'Color 1',
    grad2Title: 'Color 2',
    grad2Label: 'Color 2',
    angleTitle: 'Angle',
    widthTitle: 'Width',
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

  List<DropdownMenuItem<FillVariant>> _variantItems() {
    return [
      for (final variant in FillVariant.values)
        if (ids._capability.allows(variant))
          DropdownMenuItem(
            value: variant,
            child: Text(_labelForVariant(variant)),
          ),
    ];
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
            final safeValue = ids._capability.allows(current)
                ? current
                : ids._capability.allowed.first;

            return LabeledDropdown<FillVariant>(
              value: safeValue,
              items: _variantItems(),
              onChanged: enabled
                  ? (next) {
                      if (next == null) return;
                      commit(convertFillVariant(value, next, ids._capability));
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
                ids._capability,
              ),
              enabled: enabled,
              onPick: (color) {
                commit(coerceFill(rt.CanvasFill.solid(color), ids._capability));
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
            final g = gradientForEditing(value, ids._capability);
            return SwatchPickerRow(
              label: ids.grad1Label,
              swatchesArgb32: swatches,
              selectedArgb32: g.color1,
              enabled: enabled,
              onPick: (color) {
                commit(
                  patchLinearGradient(
                    value,
                    LinearGradientPatch(color1: color),
                    ids._capability,
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
            final g = gradientForEditing(value, ids._capability);
            return SwatchPickerRow(
              label: ids.grad2Label,
              swatchesArgb32: swatches,
              selectedArgb32: g.color2,
              enabled: enabled,
              onPick: (color) {
                commit(
                  patchLinearGradient(
                    value,
                    LinearGradientPatch(color2: color),
                    ids._capability,
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
            final g = gradientForEditing(value, ids._capability);
            return LabeledSlider(
              label: ids.angleTitle,
              value: g.angle.clamp(0, 360).toDouble(),
              min: 0,
              max: 360,
              enabled: enabled,
              onChangeStart: (_) => begin?.call(),
              onChanged: (angle) {
                commit(
                  patchLinearGradient(
                    value,
                    LinearGradientPatch(angle: angle),
                    ids._capability,
                  ),
                );
              },
              onChangeEnd: (_) => end?.call(),
            );
          },
    );
  }

  InspectorFieldSpec<rt.CanvasFill> _gradientWidthSpec() {
    return InspectorFieldSpec<rt.CanvasFill>(
      fieldKey: ids.field,
      title: ids.widthTitle,
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
            final g = gradientForEditing(value, ids._capability);
            return LabeledSlider(
              label: ids.widthTitle,
              value: g.width.clamp(0, 50).toDouble(),
              min: 0,
              max: 50,
              enabled: enabled,
              onChangeStart: (_) => begin?.call(),
              onChanged: (width) {
                commit(
                  patchLinearGradient(
                    value,
                    LinearGradientPatch(width: width),
                    ids._capability,
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

    final kind = fillVariantOf(coerceFill(currentFill, ids._capability));

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
          const Gap(6),
          inspector.fieldRow<rt.CanvasFill>(nodeId, _gradientWidthSpec()),
        ],
      ],
    );
  }
}
