// Path: oss_packages/canvas_editor_flutter/lib/src/editor_shell_config.dart

import 'package:canvas_editor_flutter/src/presentation/actions/editor_actions.dart'
    show EditorActionDispatcher, EditorActionSpec, EditorToolbarState;
import 'package:flutter/material.dart';

/// How the inspector is presented.
/// - docked: takes layout space, good for standalone editors
/// - inlineCompact: occupies a small bottom panel in hosted shells
/// - hidden: no inspector at all
enum InspectorPresentation { docked, inlineCompact, hidden }

typedef EditorAppBarBuilder =
    PreferredSizeWidget? Function(
      BuildContext context,
      EditorToolbarState state,
      EditorActionDispatcher actions,
      List<EditorActionSpec> actionSpecs,
    );

typedef HostedHeaderBuilder =
    Widget Function(
      BuildContext context,
      EditorToolbarState state,
      EditorActionDispatcher actions,
      List<EditorActionSpec> actionSpecs,
    );

typedef HostedBottomBuilder =
    Widget Function(
      BuildContext context,
      EditorToolbarState state,
      EditorActionDispatcher actions,
      List<EditorActionSpec> actionSpecs,
    );

/// Presentation-only shell configuration.
///
/// Describes whether the editor owns its surrounding chrome or is hosted inside
/// app-provided UI such as a screen, sheet, dialog, or split pane. Shell config
/// must not own persistence, permission, analytics, or product workflow policy.
@immutable
class EditorShellConfig {
  const EditorShellConfig({
    required this.hosted,
    required this.showDefaultAppBar,
    required this.inspectorPresentation,
    this.showLayersPanel = false,
    this.hostedHeaderBuilder,
    this.hostedBottomBuilder,
    this.hostedBottomHeight,
  });

  /// Hosted means the editor does not create its own Scaffold.
  final bool hosted;

  /// Only relevant when hosted=false.
  final bool showDefaultAppBar;

  final InspectorPresentation inspectorPresentation;

  /// Whether the built-in layers panel should be shown when the shell has
  /// enough space.
  ///
  /// Layers are docked only in wide, standalone layouts.
  final bool showLayersPanel;

  /// Optional header for hosted shells.
  final HostedHeaderBuilder? hostedHeaderBuilder;

  /// Optional custom bottom panel for hosted shells.
  ///
  /// If omitted and [inspectorPresentation] is [InspectorPresentation.inlineCompact],
  /// the package renders its built-in compact inspector.
  final HostedBottomBuilder? hostedBottomBuilder;

  /// Optional explicit height for bottom panel in hosted shells.
  final double? hostedBottomHeight;

  EditorShellConfig copyWith({
    bool? hosted,
    bool? showDefaultAppBar,
    InspectorPresentation? inspectorPresentation,
    bool? showLayersPanel,
    HostedHeaderBuilder? hostedHeaderBuilder,
    HostedBottomBuilder? hostedBottomBuilder,
    double? hostedBottomHeight,
  }) {
    return EditorShellConfig(
      hosted: hosted ?? this.hosted,
      showDefaultAppBar: showDefaultAppBar ?? this.showDefaultAppBar,
      inspectorPresentation:
          inspectorPresentation ?? this.inspectorPresentation,
      showLayersPanel: showLayersPanel ?? this.showLayersPanel,
      hostedHeaderBuilder: hostedHeaderBuilder ?? this.hostedHeaderBuilder,
      hostedBottomBuilder: hostedBottomBuilder ?? this.hostedBottomBuilder,
      hostedBottomHeight: hostedBottomHeight ?? this.hostedBottomHeight,
    );
  }

  static const standalone = EditorShellConfig(
    hosted: false,
    showDefaultAppBar: true,
    inspectorPresentation: InspectorPresentation.docked,
    showLayersPanel: true,
  );

  static const hostedCompactInspector = EditorShellConfig(
    hosted: true,
    showDefaultAppBar: false,
    inspectorPresentation: InspectorPresentation.inlineCompact,
  );

  static const hostedCanvasOnly = EditorShellConfig(
    hosted: true,
    showDefaultAppBar: false,
    inspectorPresentation: InspectorPresentation.hidden,
  );
}
