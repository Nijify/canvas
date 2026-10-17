import 'package:flutter/material.dart';

import 'package:canvas_core/canvas_core_runtime.dart' as rt;
import 'package:canvas_editor_flutter/src/presentation/inspector/controls.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_context.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_number_field.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_ui.dart';

const _strokeSwatches = <int>[
  0xFF111111,
  0xFFFFFFFF,
  0xFF3B82F6,
  0xFF22C55E,
  0xFFF59E0B,
  0xFFEF4444,
  0xFF8B5CF6,
  0xFF06B6D4,
];

/// Authors one optional path stroke through its canonical registered field.
class StrokeEditor extends StatefulWidget {
  const StrokeEditor({
    super.key,
    required this.nodeId,
    required this.inspector,
  });

  final rt.ElementId nodeId;
  final InspectorContext inspector;

  @override
  State<StrokeEditor> createState() => _StrokeEditorState();
}

class _StrokeEditorState extends State<StrokeEditor> {
  VoidCallback? _endOpacitySession;

  void _finishOpacitySession() {
    final end = _endOpacitySession;
    _endOpacitySession = null;
    end?.call();
  }

  @override
  void didUpdateWidget(covariant StrokeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nodeId != widget.nodeId ||
        !identical(
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

  void _patch(rt.CanvasStroke Function(rt.CanvasStroke) update) {
    widget.inspector.controller.updateField<rt.CanvasStroke?>(
      widget.nodeId,
      rt.CanvasFields.pathStroke,
      (current) => current == null ? null : update(current),
    );
  }

  void _add() {
    widget.inspector.controller.updateField<rt.CanvasStroke?>(
      widget.nodeId,
      rt.CanvasFields.pathStroke,
      (current) => current ?? const rt.CanvasStroke(color: 0xFF111111),
    );
  }

  void _remove() {
    _finishOpacitySession();
    widget.inspector.controller.commitField<rt.CanvasStroke?>(
      widget.nodeId,
      rt.CanvasFields.pathStroke,
      null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final node = rt.findById(widget.inspector.editableScene, widget.nodeId);
    final stroke = node is rt.PathNode ? node.data.appearance.stroke : null;
    final state = widget.inspector.controller.getField<rt.CanvasStroke?>(
      widget.nodeId,
      rt.CanvasFields.pathStroke,
    );
    final disabledReason =
        state.disabledReason ??
        (node is rt.PathNode
            ? null
            : 'Missing or incompatible canonical target');
    final enabled = disabledReason == null;

    if ((!enabled || stroke == null) && _endOpacitySession != null) {
      final end = _endOpacitySession;
      _endOpacitySession = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => end?.call());
    }

    final opaqueRgb = 0xFF000000 | ((stroke?.color ?? 0) & 0x00FFFFFF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Stroke',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            if (stroke != null)
              IconButton(
                tooltip: 'Remove stroke',
                icon: const Icon(Icons.delete_outline),
                onPressed: enabled ? _remove : null,
              ),
          ],
        ),
        if (disabledReason != null) ...[const Gap(8), HintText(disabledReason)],
        if (stroke == null)
          OutlinedButton.icon(
            onPressed: enabled ? _add : null,
            icon: const Icon(Icons.add),
            label: const Text('Add Stroke'),
          )
        else ...[
          const Gap(8),
          SwatchPickerRow(
            label: 'Color',
            swatchesArgb32: [
              if (!_strokeSwatches.contains(opaqueRgb)) opaqueRgb,
              ..._strokeSwatches,
            ],
            selectedArgb32: opaqueRgb,
            enabled: enabled,
            onPick: (rgb) => _patch(
              (current) => current.copyWith(
                color: (current.color & 0xFF000000) | (rgb & 0x00FFFFFF),
              ),
            ),
          ),
          const Gap(12),
          LabeledSlider(
            label: 'Opacity',
            value: ((stroke.color >> 24) & 0xFF) / 255,
            min: 0,
            max: 1,
            fraction: true,
            enabled: enabled,
            onChangeStart: (_) {
              _endOpacitySession ??= widget.inspector.controller
                  .beginEditSession();
            },
            onChanged: (opacity) => _patch(
              (current) => current.copyWith(
                color:
                    ((opacity * 255).round().clamp(0, 255).toInt() << 24) |
                    (current.color & 0x00FFFFFF),
              ),
            ),
            onChangeEnd: (_) => _finishOpacitySession(),
          ),
          InspectorNumberField(
            key: ValueKey<String>('${widget.nodeId}:stroke-width'),
            label: 'Width',
            value: stroke.width,
            minimum: 0,
            enabled: enabled,
            onCommit: (width) =>
                _patch((current) => current.copyWith(width: width)),
          ),
          const Gap(12),
          LabeledDropdown<rt.StrokeCap>(
            key: ValueKey<String>('${widget.nodeId}:stroke-cap:${stroke.cap}'),
            value: stroke.cap,
            decoration: InspectorUi.inputDecoration(labelText: 'Cap'),
            items: [
              for (final cap in rt.StrokeCap.values)
                DropdownMenuItem(
                  value: cap,
                  child: Text(switch (cap) {
                    rt.StrokeCap.butt => 'Butt',
                    rt.StrokeCap.round => 'Round',
                    rt.StrokeCap.square => 'Square',
                  }),
                ),
            ],
            onChanged: enabled
                ? (cap) {
                    if (cap != null) {
                      _patch((current) => current.copyWith(cap: cap));
                    }
                  }
                : null,
          ),
          const Gap(12),
          LabeledDropdown<rt.StrokeJoin>(
            key: ValueKey<String>(
              '${widget.nodeId}:stroke-join:${stroke.join}',
            ),
            value: stroke.join,
            decoration: InspectorUi.inputDecoration(labelText: 'Join'),
            items: [
              for (final join in rt.StrokeJoin.values)
                DropdownMenuItem(
                  value: join,
                  child: Text(switch (join) {
                    rt.StrokeJoin.miter => 'Miter',
                    rt.StrokeJoin.round => 'Round',
                    rt.StrokeJoin.bevel => 'Bevel',
                  }),
                ),
            ],
            onChanged: enabled
                ? (join) {
                    if (join != null) {
                      _patch((current) => current.copyWith(join: join));
                    }
                  }
                : null,
          ),
          if (stroke.join == rt.StrokeJoin.miter) ...[
            const Gap(12),
            InspectorNumberField(
              key: ValueKey<String>('${widget.nodeId}:stroke-miter'),
              label: 'Miter limit',
              value: stroke.miterLimit,
              minimum: 1,
              enabled: enabled,
              onCommit: (limit) =>
                  _patch((current) => current.copyWith(miterLimit: limit)),
            ),
          ],
        ],
      ],
    );
  }
}
