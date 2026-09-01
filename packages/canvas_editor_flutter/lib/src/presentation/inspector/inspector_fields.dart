// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/inspector/inspector_fields.dart

import 'package:flutter/material.dart';

import 'package:canvas_core/canvas_core_runtime.dart'
    show CanvasFieldKey, CanvasFields;
import 'package:canvas_editor_flutter/src/canvas_runtime_resources.dart'
    show FontPickerItem, IconCatalogItem;
import 'package:canvas_editor_flutter/src/presentation/inspector/controls.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_ui.dart';

enum CommitMode { immediate, debounced, dragTxn }

typedef ControlBuilder<T> =
    Widget Function(
      BuildContext context, {
      required bool enabled,
      required T value,
      required void Function(T next) commit,

      /// Only used for dragTxn controls (sliders/gestures).
      void Function()? begin,
      void Function()? end,

      /// Used by debounced controls to end the current burst immediately
      /// (e.g. on blur / submit). Also safe for dragTxn to “force close”.
      void Function()? flush,
    });

class InspectorFieldSpec<T> {
  const InspectorFieldSpec({
    required this.fieldKey,
    required this.title,
    required this.commitMode,
    required this.control,
    this.debounce = const Duration(milliseconds: 450),
    this.semanticSlot,
  });

  final CanvasFieldKey fieldKey;
  final String title;

  final CommitMode commitMode;

  /// Controls MUST be pure UI: no controller calls, no FieldState dependency.
  final ControlBuilder<T> control;

  /// Only used when commitMode == debounced.
  final Duration debounce;

  final String? semanticSlot;
}

/// ---------------------------------------------------------------------------
/// Canonical helpers (reduce boilerplate & standardize behavior)
/// ---------------------------------------------------------------------------

InspectorFieldSpec<String> iconRefSpec({required List<IconCatalogItem> icons}) {
  return InspectorFieldSpec<String>(
    fieldKey: CanvasFields.iconRef,
    title: 'Icon',
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
          final hasCurrent = icons.any((item) => item.ref == value);

          final items = <DropdownMenuItem<String>>[
            if (!hasCurrent && value.trim().isNotEmpty)
              DropdownMenuItem<String>(
                value: value,
                enabled: false,
                child: Text('Unavailable icon: $value'),
              ),
            ...icons.map(
              (item) => DropdownMenuItem<String>(
                value: item.ref,
                child: Text(item.label),
              ),
            ),
          ];

          return LabeledDropdown<String>(
            key: ValueKey<String>('icon-ref:$value'),
            value: value.trim().isEmpty ? null : value,
            items: items,
            onChanged: enabled && icons.isNotEmpty
                ? (next) {
                    if (next == null || next == value) return;
                    commit(next);
                  }
                : null,
            decoration: InspectorUi.inputDecoration(labelText: 'Icon'),
          );
        },
  );
}

InspectorFieldSpec<String> textFieldSpec({
  required CanvasFieldKey fieldKey,
  required String title,
  CommitMode commitMode = CommitMode.debounced,
  String? semanticSlot,
}) {
  return InspectorFieldSpec<String>(
    fieldKey: fieldKey,
    title: title,
    commitMode: commitMode,
    semanticSlot: semanticSlot,
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
          return InspectorTextField(
            enabled: enabled,
            text: value,
            label: title,
            onChanged: commit,
            onBlur: flush,
          );
        },
  );
}

InspectorFieldSpec<T> dropdownSpec<T>({
  required CanvasFieldKey fieldKey,
  required String title,
  required List<DropdownMenuItem<T>> items,
  CommitMode commitMode = CommitMode.immediate,
}) {
  return InspectorFieldSpec<T>(
    fieldKey: fieldKey,
    title: title,
    commitMode: commitMode,
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
          return LabeledDropdown<T>(
            value: value,
            items: items,
            onChanged: enabled
                ? (v) {
                    if (v == null) return;
                    commit(v);
                  }
                : null,
          );
        },
  );
}

/// ---------------------------------------------------------------------------
/// Swatch field specs (canonical)
/// ---------------------------------------------------------------------------

InspectorFieldSpec<int> swatchFieldSpec({
  required CanvasFieldKey fieldKey,
  required String title,
  required String label,
  required List<int> swatchesArgb32,
  CommitMode commitMode = CommitMode.immediate,
}) {
  return InspectorFieldSpec<int>(
    fieldKey: fieldKey,
    title: title,
    commitMode: commitMode,
    control:
        (
          BuildContext context, {
          required bool enabled,
          required int value,
          required void Function(int next) commit,
          void Function()? begin,
          void Function()? end,
          void Function()? flush,
        }) {
          return SwatchPickerRow(
            label: label,
            swatchesArgb32: swatchesArgb32,
            selectedArgb32: value,
            enabled: enabled,
            onPick: commit,
          );
        },
  );
}

/// ---------------------------------------------------------------------------
/// Slider field specs (canonical)
/// ---------------------------------------------------------------------------

InspectorFieldSpec<double> doubleSliderSpec({
  required CanvasFieldKey fieldKey,
  required String title,
  required String uiLabel,
  required double min,
  required double max,
  bool fraction = false,
  int? divisions,
}) {
  return InspectorFieldSpec<double>(
    fieldKey: fieldKey,
    title: title,
    commitMode: CommitMode.dragTxn,
    control:
        (
          context, {
          required enabled,
          required value,
          required commit,
          flush,
          begin,
          end,
        }) {
          return LabeledSlider(
            label: uiLabel,
            value: value,
            min: min,
            max: max,
            fraction: fraction,
            divisions: divisions,
            enabled: enabled,
            onChangeStart: (_) => begin?.call(),
            onChanged: commit,
            onChangeEnd: (_) => end?.call(),
          );
        },
  );
}

/// ---------------------------------------------------------------------------
/// Text field specs
/// ---------------------------------------------------------------------------

InspectorFieldSpec<String> textContentSpec() {
  return textFieldSpec(
    fieldKey: CanvasFields.textContent,
    title: 'Content',
    commitMode: CommitMode.debounced,
  );
}

InspectorFieldSpec<String> textFontFamilySpec({
  required List<FontPickerItem> fonts,
}) {
  String labelFor(String family) {
    for (final font in fonts) {
      if (font.family == family) return font.label;
    }
    return family;
  }

  return InspectorFieldSpec<String>(
    fieldKey: CanvasFields.textFontFamily,
    title: 'Font',
    commitMode: CommitMode.immediate,
    control:
        (
          context, {
          required enabled,
          required value,
          required commit,
          flush,
          begin,
          end,
        }) {
          final families = <String>{
            ...fonts
                .map((font) => font.family.trim())
                .where((family) => family.isNotEmpty),
            if (value.trim().isNotEmpty) value.trim(),
          }.toList(growable: false);

          return LabeledDropdown<String>(
            value: value,
            items: families
                .map(
                  (family) => DropdownMenuItem<String>(
                    value: family,
                    child: Text(
                      labelFor(family),
                      style: TextStyle(
                        fontFamily: family,
                        fontFamilyFallback: families
                            .where((fallback) => fallback != family)
                            .toList(growable: false),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: enabled
                ? (next) {
                    if (next == null) return;
                    commit(next);
                  }
                : null,
          );
        },
  );
}

InspectorFieldSpec<double> textFontSizeSpec() {
  return doubleSliderSpec(
    fieldKey: CanvasFields.textFontSize,
    title: 'Size',
    uiLabel: 'Size',
    min: 10,
    max: 160,
  );
}

InspectorFieldSpec<double> textLetterSpacingSpec() {
  return doubleSliderSpec(
    fieldKey: CanvasFields.textLetterSpacing,
    title: 'Letter Spacing',
    uiLabel: 'Letter Spacing (px)',
    min: 0,
    max: 5,
    divisions: 20,
    fraction: true,
  );
}

InspectorFieldSpec<int> textBoldSpec() {
  return InspectorFieldSpec<int>(
    fieldKey: CanvasFields.textFontWeight,
    title: 'Bold',
    commitMode: CommitMode.immediate,
    control:
        (
          context, {
          required enabled,
          required value,
          required commit,
          flush,
          begin,
          end,
        }) {
          return Switch(
            value: value >= 700,
            onChanged: enabled ? (on) => commit(on ? 700 : 400) : null,
          );
        },
  );
}

InspectorFieldSpec<double> textShadowOffsetSpec() {
  return doubleSliderSpec(
    fieldKey: CanvasFields.textShadowOffset,
    title: 'Shadow Offset',
    uiLabel: 'Shadow Offset',
    min: 0,
    max: 8,
  );
}
