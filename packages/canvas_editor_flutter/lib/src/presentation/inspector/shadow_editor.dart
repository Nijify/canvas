// Path: packages/canvas_editor_flutter/lib/src/presentation/inspector/shadow_editor.dart

import 'package:flutter/material.dart';

import 'package:canvas_core/canvas_core_runtime.dart' as rt;
import 'package:canvas_editor_flutter/src/presentation/inspector/controls.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_context.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_number_field.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_ui.dart';

const _shadowSwatchesArgb32 = <int>[
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

const _defaultShadowOffset = rt.Vec2(4, 4);
const _defaultShadowBlurSigma = 4.0;
const _defaultShadowColor = 0x66000000;

int _shadowAddSequence = 0;

String _nextShadowBaseId() {
  return 'shadow_${DateTime.now().microsecondsSinceEpoch}_'
      '${_shadowAddSequence++}';
}

String _resolveUniqueShadowId(
  String baseId,
  List<rt.CanvasSourceUnderlay> underlays,
) {
  final ids = <String>{for (final underlay in underlays) underlay.id};

  if (!ids.contains(baseId)) {
    return baseId;
  }

  var suffix = 2;

  while (true) {
    final candidate = '${baseId}_$suffix';

    if (!ids.contains(candidate)) {
      return candidate;
    }

    suffix += 1;
  }
}

List<rt.CanvasSourceUnderlay>? _canonicalUnderlaysFor(
  InspectorContext inspector,
  rt.ElementId nodeId,
  rt.CanvasFieldKey fieldKey,
) {
  final node = rt.findById(inspector.editableScene, nodeId);

  if (fieldKey == rt.CanvasFields.textUnderlays && node is rt.TextNode) {
    return node.data.appearance.underlays;
  }

  if (fieldKey == rt.CanvasFields.iconUnderlays && node is rt.IconNode) {
    return node.data.appearance.underlays;
  }

  return null;
}

typedef _ShadowPatch = rt.ShadowEffect Function(rt.ShadowEffect shadow);

List<rt.CanvasSourceUnderlay> _patchShadow(
  List<rt.CanvasSourceUnderlay> current,
  String shadowId,
  _ShadowPatch patch,
) {
  final index = current.indexWhere((underlay) => underlay.id == shadowId);

  if (index < 0) {
    return current;
  }

  final underlay = current[index];

  if (underlay is! rt.ShadowEffect) {
    return current;
  }

  final nextShadow = patch(underlay);

  if (nextShadow == underlay) {
    return current;
  }

  final next = List<rt.CanvasSourceUnderlay>.of(current);
  next[index] = nextShadow;

  return List<rt.CanvasSourceUnderlay>.unmodifiable(next);
}

List<rt.CanvasSourceUnderlay> _removeShadow(
  List<rt.CanvasSourceUnderlay> current,
  String shadowId,
) {
  final index = current.indexWhere((underlay) => underlay.id == shadowId);

  if (index < 0) {
    return current;
  }

  if (current[index] is! rt.ShadowEffect) {
    return current;
  }

  final next = List<rt.CanvasSourceUnderlay>.of(current)..removeAt(index);

  return List<rt.CanvasSourceUnderlay>.unmodifiable(next);
}

List<rt.CanvasSourceUnderlay> _moveShadow(
  List<rt.CanvasSourceUnderlay> current,
  String shadowId,
  int delta,
) {
  final from = current.indexWhere((underlay) => underlay.id == shadowId);

  if (from < 0) {
    return current;
  }

  if (current[from] is! rt.ShadowEffect) {
    return current;
  }

  final to = from + delta;

  if (to < 0 || to >= current.length) {
    return current;
  }

  final next = List<rt.CanvasSourceUnderlay>.of(current);
  final item = next.removeAt(from);
  next.insert(to, item);

  return List<rt.CanvasSourceUnderlay>.unmodifiable(next);
}

class ShadowEditor extends StatefulWidget {
  const ShadowEditor({
    super.key,
    required this.nodeId,
    required this.inspector,
    required this.fieldKey,
  });

  final rt.ElementId nodeId;
  final InspectorContext inspector;
  final rt.CanvasFieldKey fieldKey;

  @override
  State<ShadowEditor> createState() => _ShadowEditorState();
}

class _ShadowEditorState extends State<ShadowEditor> {
  VoidCallback? _endOpacitySession;

  void _beginOpacitySession() {
    _endOpacitySession ??= widget.inspector.controller.beginEditSession();
  }

  void _finishOpacitySession() {
    final end = _endOpacitySession;
    _endOpacitySession = null;
    end?.call();
  }

  @override
  void didUpdateWidget(covariant ShadowEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(
      oldWidget.inspector.controller,
      widget.inspector.controller,
    )) {
      _finishOpacitySession();
    }
  }

  @override
  void dispose() {
    _finishOpacitySession();
    super.dispose();
  }

  void _addShadow() {
    // Generate one candidate for this Add action. Collision resolution happens
    // inside updateField() against the latest canonical list.
    final baseId = _nextShadowBaseId();

    widget.inspector.controller.updateField<List<rt.CanvasSourceUnderlay>>(
      widget.nodeId,
      widget.fieldKey,
      (current) {
        final id = _resolveUniqueShadowId(baseId, current);

        final next = List<rt.CanvasSourceUnderlay>.of(current)
          ..add(
            rt.CanvasSourceUnderlay.shadow(
              id: id,
              offset: _defaultShadowOffset,
              blurSigma: _defaultShadowBlurSigma,
              color: _defaultShadowColor,
            ),
          );

        return List<rt.CanvasSourceUnderlay>.unmodifiable(next);
      },
    );
  }

  void _updateShadow(String shadowId, _ShadowPatch patch) {
    widget.inspector.controller.updateField<List<rt.CanvasSourceUnderlay>>(
      widget.nodeId,
      widget.fieldKey,
      (current) => _patchShadow(current, shadowId, patch),
    );
  }

  void _remove(String shadowId) {
    widget.inspector.controller.updateField<List<rt.CanvasSourceUnderlay>>(
      widget.nodeId,
      widget.fieldKey,
      (current) => _removeShadow(current, shadowId),
    );
  }

  void _move(String shadowId, int delta) {
    widget.inspector.controller.updateField<List<rt.CanvasSourceUnderlay>>(
      widget.nodeId,
      widget.fieldKey,
      (current) => _moveShadow(current, shadowId, delta),
    );
  }

  void _setOffsetX(String shadowId, double value) {
    _updateShadow(
      shadowId,
      (shadow) => shadow.copyWith(offset: rt.Vec2(value, shadow.offset.y)),
    );
  }

  void _setOffsetY(String shadowId, double value) {
    _updateShadow(
      shadowId,
      (shadow) => shadow.copyWith(offset: rt.Vec2(shadow.offset.x, value)),
    );
  }

  void _setBlur(String shadowId, double value) {
    _updateShadow(shadowId, (shadow) => shadow.copyWith(blurSigma: value));
  }

  void _setRgb(String shadowId, int pickedArgb) {
    _updateShadow(shadowId, (shadow) {
      final alpha = shadow.color & 0xFF000000;
      final rgb = pickedArgb & 0x00FFFFFF;

      return shadow.copyWith(color: alpha | rgb);
    });
  }

  void _setOpacity(String shadowId, double opacity) {
    final alpha = (opacity * 255).round().clamp(0, 255).toInt();

    _updateShadow(shadowId, (shadow) {
      final rgb = shadow.color & 0x00FFFFFF;

      return shadow.copyWith(color: (alpha << 24) | rgb);
    });
  }

  Widget _buildShadowCard(
    BuildContext context, {
    required rt.ShadowEffect shadow,
    required int ordinal,
    required int listIndex,
    required int listLength,
    required bool enabled,
  }) {
    final selectedOpaqueRgb = 0xFF000000 | (shadow.color & 0x00FFFFFF);

    final swatches = _shadowSwatchesArgb32.contains(selectedOpaqueRgb)
        ? _shadowSwatchesArgb32
        : <int>[selectedOpaqueRgb, ..._shadowSwatchesArgb32];

    final opacity = ((shadow.color >> 24) & 0xFF) / 255.0;

    return Container(
      key: ValueKey<String>('shadow:${shadow.id}'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Shadow $ordinal',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Tooltip(
                message: shadow.enabled ? 'Disable shadow' : 'Enable shadow',
                child: Switch(
                  value: shadow.enabled,
                  onChanged: enabled
                      ? (value) {
                          _updateShadow(
                            shadow.id,
                            (current) => current.copyWith(enabled: value),
                          );
                        }
                      : null,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Move backward',
                icon: const Icon(Icons.keyboard_arrow_up),
                onPressed: enabled && listIndex > 0
                    ? () => _move(shadow.id, -1)
                    : null,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Move forward',
                icon: const Icon(Icons.keyboard_arrow_down),
                onPressed: enabled && listIndex < listLength - 1
                    ? () => _move(shadow.id, 1)
                    : null,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Remove shadow',
                icon: const Icon(Icons.delete_outline),
                onPressed: enabled ? () => _remove(shadow.id) : null,
              ),
            ],
          ),
          const Gap(8),
          Row(
            children: [
              Expanded(
                child: InspectorNumberField(
                  key: ValueKey<String>('${shadow.id}:offset-x'),
                  label: 'Offset X',
                  value: shadow.offset.x,
                  enabled: enabled,
                  onCommit: (value) => _setOffsetX(shadow.id, value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InspectorNumberField(
                  key: ValueKey<String>('${shadow.id}:offset-y'),
                  label: 'Offset Y',
                  value: shadow.offset.y,
                  enabled: enabled,
                  onCommit: (value) => _setOffsetY(shadow.id, value),
                ),
              ),
            ],
          ),
          const Gap(8),
          InspectorNumberField(
            key: ValueKey<String>('${shadow.id}:blur'),
            label: 'Blur sigma',
            value: shadow.blurSigma,
            minimum: 0,
            enabled: enabled,
            onCommit: (value) => _setBlur(shadow.id, value),
          ),
          const Gap(12),
          SwatchPickerRow(
            label: 'Color',
            swatchesArgb32: swatches,
            selectedArgb32: selectedOpaqueRgb,
            enabled: enabled,
            onPick: (color) => _setRgb(shadow.id, color),
          ),
          const Gap(8),
          LabeledSlider(
            label: 'Opacity',
            value: opacity,
            min: 0,
            max: 1,
            divisions: 255,
            fraction: true,
            enabled: enabled,
            onChangeStart: (_) => _beginOpacitySession(),
            onChanged: (value) => _setOpacity(shadow.id, value),
            onChangeEnd: (_) => _finishOpacitySession(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canonicalUnderlays = _canonicalUnderlaysFor(
      widget.inspector,
      widget.nodeId,
      widget.fieldKey,
    );

    // getField() is intentionally used only for field editability here.
    // Row values come from the canonical editable scene above.
    final fieldState = widget.inspector.controller
        .getField<List<rt.CanvasSourceUnderlay>>(
          widget.nodeId,
          widget.fieldKey,
        );

    final hasCanonicalTarget = canonicalUnderlays != null;
    final enabled = hasCanonicalTarget && fieldState.disabledReason == null;

    final disabledReason =
        fieldState.disabledReason ??
        (hasCanonicalTarget
            ? null
            : 'Missing or incompatible canonical target');

    final underlays = canonicalUnderlays ?? const <rt.CanvasSourceUnderlay>[];

    final shadowCards = <Widget>[];
    var ordinal = 1;

    for (var index = 0; index < underlays.length; index++) {
      final underlay = underlays[index];

      if (underlay is! rt.ShadowEffect) {
        continue;
      }

      shadowCards.add(
        _buildShadowCard(
          context,
          shadow: underlay,
          ordinal: ordinal,
          listIndex: index,
          listLength: underlays.length,
          enabled: enabled,
        ),
      );

      ordinal += 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Shadows', style: Theme.of(context).textTheme.titleSmall),
        const Gap(8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: enabled ? _addShadow : null,
            icon: const Icon(Icons.add),
            label: const Text('Add Shadow'),
          ),
        ),
        if (disabledReason != null) ...[const Gap(8), HintText(disabledReason)],
        if (shadowCards.isEmpty) ...[
          const Gap(8),
          const HintText('No authored shadows.'),
        ] else ...[
          const Gap(12),
          for (var index = 0; index < shadowCards.length; index++) ...[
            if (index > 0) const Gap(10),
            shadowCards[index],
          ],
        ],
      ],
    );
  }
}
