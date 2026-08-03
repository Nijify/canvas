// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/inspector/inspector_ui.dart

import 'package:flutter/material.dart';

/// Shared, canonical inspector UI bits (styles, spacing, small widgets).
class InspectorUi {
  /// Local inspector width below which controls should prefer vertical layouts.
  ///
  /// This is intentionally based on the space available to the inspector
  /// component, not the width of the overall app window or device.
  static const double compactWidth = 360;

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

/// Lays out a small group of inspector actions responsively.
///
/// Actions share the available width horizontally when there is enough room.
/// They become full-width vertical actions in compact layouts or when the user
/// has substantially enlarged system text.
class InspectorActionGroup extends StatelessWidget {
  const InspectorActionGroup({
    super.key,
    required this.children,
    this.compactWidth = InspectorUi.compactWidth,
    this.spacing = 12,
    this.verticalSpacing = 8,
  }) : assert(children.length > 0);

  final List<Widget> children;
  final double compactWidth;
  final double spacing;
  final double verticalSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelFontSize =
            Theme.of(context).textTheme.labelLarge?.fontSize ?? 14;

        final textScaler =
            MediaQuery.maybeOf(context)?.textScaler ?? TextScaler.noScaling;

        final scaledLabelFontSize = textScaler.scale(labelFontSize);
        final hasLargeText = scaledLabelFontSize > labelFontSize * 1.3;

        final useVerticalLayout =
            constraints.maxWidth < compactWidth || hasLargeText;

        if (useVerticalLayout) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0) SizedBox(height: verticalSpacing),
                children[index],
              ],
            ],
          );
        }

        return Row(
          children: <Widget>[
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) SizedBox(width: spacing),
              Expanded(child: children[index]),
            ],
          ],
        );
      },
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
