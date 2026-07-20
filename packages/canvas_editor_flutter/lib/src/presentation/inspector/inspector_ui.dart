// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/inspector/inspector_ui.dart

import 'package:flutter/material.dart';

/// Shared, canonical inspector UI bits (styles, spacing, small widgets).
class InspectorUi {
  static const EdgeInsets cardPadding = EdgeInsets.all(12);

  static TextStyle hintStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    return base.copyWith(
      fontSize: 12,
      color: (base.color ?? Colors.black).withValues(alpha: 0.7),
    );
  }

  static InputDecoration inputDecoration({String? labelText}) {
    return InputDecoration(
      labelText: labelText,
      border: const OutlineInputBorder(),
      isDense: true,
    );
  }
}

class Gap extends StatelessWidget {
  const Gap(this.h, {super.key});
  final double h;

  @override
  Widget build(BuildContext context) => SizedBox(height: h);
}

class HintText extends StatelessWidget {
  const HintText(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: InspectorUi.hintStyle(context));
  }
}

class InspectorCard extends StatelessWidget {
  const InspectorCard({
    super.key,
    required this.child,
    this.padding = InspectorUi.cardPadding,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: padding, child: child),
    );
  }
}
