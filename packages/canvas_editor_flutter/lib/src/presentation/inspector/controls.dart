// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/inspector/controls.dart

import 'package:flutter/material.dart';

import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_ui.dart';

// -----------------------------------------------------------------------------
// Swatch picker
// -----------------------------------------------------------------------------

class SwatchPickerRow extends StatelessWidget {
  const SwatchPickerRow({
    super.key,
    required this.label,
    required this.swatchesArgb32,
    required this.selectedArgb32,
    required this.onPick,
    this.enabled = true,
  });

  final String label;
  final List<int> swatchesArgb32;
  final int selectedArgb32;
  final ValueChanged<int> onPick;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: swatchesArgb32
                  .map((argb) {
                    final selected = argb == selectedArgb32;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: enabled ? () => onPick(argb) : null,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(argb),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? Colors.black
                                  : Colors.grey.shade300,
                              width: selected ? 2 : 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Dropdown
// -----------------------------------------------------------------------------

class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.decoration,
  });

  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: decoration ?? InspectorUi.inputDecoration(),
    );
  }
}

// -----------------------------------------------------------------------------
// Slider
// -----------------------------------------------------------------------------

class LabeledSlider extends StatelessWidget {
  const LabeledSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.fraction = false,
    this.divisions,
    this.enabled = true,
  });

  final String label;
  final double value;
  final double min;
  final double max;

  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;

  final bool fraction;
  final int? divisions;
  final bool enabled;

  String _format(double v) {
    if (fraction) return v.toStringAsFixed(2);
    final digits = (max <= 1) ? 2 : 0;
    return v.toStringAsFixed(digits);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDivisions =
        divisions ?? ((max - min) <= 1 ? 100 : (max - min).round());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Text('$label: ${_format(value)}')]),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: effectiveDivisions,
          onChangeStart: enabled ? onChangeStart : null,
          onChanged: enabled ? onChanged : null,
          onChangeEnd: enabled ? onChangeEnd : null,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Text field (inspector behavior)
// -----------------------------------------------------------------------------

class InspectorTextField extends StatefulWidget {
  const InspectorTextField({
    super.key,
    required this.enabled,
    required this.text,
    required this.label,
    required this.onChanged,
    this.onBlur,
    this.decoration,
  });

  final bool enabled;
  final String text;
  final String label;

  /// Called on each keystroke when enabled.
  final ValueChanged<String> onChanged;

  /// Called when focus is lost (so FieldRow can flush/end debounced sessions).
  final VoidCallback? onBlur;

  /// Optional overrides; default is standardized by InspectorUi.
  final InputDecoration? decoration;

  @override
  State<InspectorTextField> createState() => _InspectorTextFieldState();
}

class _InspectorTextFieldState extends State<InspectorTextField> {
  late final FocusNode _focus = FocusNode()..addListener(_onFocusChange);

  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  void _onFocusChange() {
    if (!_focus.hasFocus) widget.onBlur?.call();
  }

  @override
  void didUpdateWidget(covariant InspectorTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If we became disabled while focused, drop focus (FieldRow will also end).
    if (oldWidget.enabled && !widget.enabled && _focus.hasFocus) {
      _focus.unfocus();
    }

    // Only sync external text when the user is not actively typing.
    if (!_focus.hasFocus && _controller.text != widget.text) {
      _controller.text = widget.text;
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focus,
      enabled: widget.enabled,
      onChanged: widget.enabled ? widget.onChanged : null,
      onEditingComplete: () => widget.onBlur?.call(),
      onFieldSubmitted: (_) => widget.onBlur?.call(),
      decoration: (widget.decoration ?? InspectorUi.inputDecoration()).copyWith(
        labelText: widget.label,
      ),
    );
  }
}
