import 'package:flutter/material.dart';

import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_ui.dart';

/// Finite numeric input committed on blur or submit, with an optional minimum.
class InspectorNumberField extends StatefulWidget {
  const InspectorNumberField({
    super.key,
    required this.label,
    required this.value,
    this.minimum,
    required this.enabled,
    required this.onCommit,
  });

  final String label;
  final double value;
  final num? minimum;
  final bool enabled;
  final ValueChanged<double> onCommit;

  @override
  State<InspectorNumberField> createState() => _InspectorNumberFieldState();
}

class _InspectorNumberFieldState extends State<InspectorNumberField> {
  late final FocusNode _focus;
  late final TextEditingController _controller;

  bool _valid = true;

  @override
  void initState() {
    super.initState();

    _focus = FocusNode()..addListener(_handleFocusChange);

    _controller = TextEditingController(text: _format(widget.value));
  }

  String _format(double value) => value.toString();

  double? _parse(String text) {
    final value = double.tryParse(text.trim());

    if (value == null || !value.isFinite) {
      return null;
    }

    if (widget.minimum != null && value < widget.minimum!) {
      return null;
    }

    return value;
  }

  void _handleFocusChange() {
    if (!_focus.hasFocus) {
      _commitOrRevert();
    }
  }

  void _replaceDraftWithCurrentValue() {
    final text = _format(widget.value);

    if (_controller.text != text) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    if (!_valid && mounted) {
      setState(() {
        _valid = true;
      });
    } else {
      _valid = true;
    }
  }

  void _commitOrRevert() {
    if (!widget.enabled) {
      _replaceDraftWithCurrentValue();
      return;
    }

    final value = _parse(_controller.text);

    if (value == null) {
      _replaceDraftWithCurrentValue();
      return;
    }

    if (value != widget.value) {
      widget.onCommit(value);
    }

    if (!_valid && mounted) {
      setState(() {
        _valid = true;
      });
    } else {
      _valid = true;
    }
  }

  void _handleChanged(String text) {
    final valid = _parse(text) != null;

    if (valid == _valid) {
      return;
    }

    setState(() {
      _valid = valid;
    });
  }

  @override
  void didUpdateWidget(covariant InspectorNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.enabled && !widget.enabled && _focus.hasFocus) {
      _focus.unfocus();
    }

    if (!_focus.hasFocus && oldWidget.value != widget.value) {
      _replaceDraftWithCurrentValue();
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_handleFocusChange);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errorText = _valid
        ? null
        : widget.minimum == null
        ? 'Enter a finite number'
        : 'Enter a finite number ≥ ${widget.minimum}';

    return TextFormField(
      controller: _controller,
      focusNode: _focus,
      enabled: widget.enabled,
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: widget.minimum == null || widget.minimum! < 0,
      ),
      textInputAction: TextInputAction.done,
      onChanged: widget.enabled ? _handleChanged : null,
      onFieldSubmitted: widget.enabled ? (_) => _focus.unfocus() : null,
      decoration: InspectorUi.inputDecoration(
        labelText: widget.label,
      ).copyWith(errorText: errorText),
    );
  }
}
