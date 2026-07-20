// Path: oss_packages/canvas_editor_flutter/lib/src/editor_extensions.dart

import 'package:canvas_core/canvas_core_runtime.dart'
    show CanvasFieldKey, SceneRenderBuilder;
import 'package:canvas_editor_flutter/src/editor_field_codecs.dart'
    show FieldCodec;
import 'package:canvas_editor_flutter/src/editor_hosts.dart'
    show EditorDocumentHost;
import 'package:canvas_editor_flutter/src/editor_surface_features.dart';
import 'package:canvas_editor_flutter/src/editor_host_capabilities.dart'
    show JsonExportCapability, PngExportCapability;
import 'package:canvas_editor_flutter/src/presentation/actions/editor_action_sets.dart'
    show pngExportActions, sceneJsonExportActions;
import 'package:canvas_editor_flutter/src/presentation/actions/editor_actions.dart'
    show EditorActionSpec;
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_context.dart'
    show InspectorFieldRowBuilder;
import 'package:flutter/foundation.dart';
import 'package:provider/single_child_widget.dart';

@immutable
class EditorExtensionContext<TSourceDocument> {
  const EditorExtensionContext({
    required this.documentHost,
    required this.requestRebuild,
  });

  final EditorDocumentHost<TSourceDocument> documentHost;
  final VoidCallback requestRebuild;
}

/// Product-agnostic capability-composition seam for editor surfaces.
///
/// Construction-time configuration is read once, before [attach]:
/// - [renderBuilder]
/// - [fieldCodecs]
/// - [surfaceFeatures]
///
/// [actionSpecs] is read after [attach], once per editor session.
///
/// [buildProviders] and [inspectorFieldRowBuilder] are build-time hooks and
/// may be read again when the editor surface rebuilds.
abstract class EditorExtension<TSourceDocument> {
  const EditorExtension();

  /// Optional render strategy for the runtime render pipeline.
  ///
  /// Later non-null contributions win when extensions are composed.
  SceneRenderBuilder? get renderBuilder => null;

  /// Additional or overriding document field codecs.
  ///
  /// Later extensions win for duplicate [CanvasFieldKey] values.
  Map<CanvasFieldKey, FieldCodec> get fieldCodecs =>
      const <CanvasFieldKey, FieldCodec>{};

  /// Construction-time configuration for the live editor surface.
  EditorSurfaceFeatures get surfaceFeatures => const EditorSurfaceFeatures();

  void attach(EditorExtensionContext<TSourceDocument> context) {}

  List<SingleChildWidget> buildProviders() => const <SingleChildWidget>[];

  List<EditorActionSpec> get actionSpecs => const <EditorActionSpec>[];

  InspectorFieldRowBuilder? get inspectorFieldRowBuilder => null;

  void dispose() {}
}

class StaticEditorExtension<TSourceDocument>
    extends EditorExtension<TSourceDocument> {
  const StaticEditorExtension({
    this.renderBuilder,
    this.fieldCodecs = const <CanvasFieldKey, FieldCodec>{},
    this.surfaceFeatures = const EditorSurfaceFeatures(),
    this.actionSpecs = const <EditorActionSpec>[],
  });

  @override
  final SceneRenderBuilder? renderBuilder;

  @override
  final Map<CanvasFieldKey, FieldCodec> fieldCodecs;

  @override
  final EditorSurfaceFeatures surfaceFeatures;

  @override
  final List<EditorActionSpec> actionSpecs;
}

class CompositeEditorExtension<TSourceDocument>
    extends EditorExtension<TSourceDocument> {
  const CompositeEditorExtension(this.extensions);

  final List<EditorExtension<TSourceDocument>> extensions;

  @override
  SceneRenderBuilder? get renderBuilder {
    for (final extension in extensions.reversed) {
      final candidate = extension.renderBuilder;
      if (candidate != null) return candidate;
    }
    return null;
  }

  @override
  Map<CanvasFieldKey, FieldCodec> get fieldCodecs =>
      <CanvasFieldKey, FieldCodec>{
        for (final extension in extensions) ...extension.fieldCodecs,
      };

  @override
  EditorSurfaceFeatures get surfaceFeatures {
    return extensions.fold<EditorSurfaceFeatures>(
      const EditorSurfaceFeatures(),
      (current, extension) => current.merge(extension.surfaceFeatures),
    );
  }

  @override
  void attach(EditorExtensionContext<TSourceDocument> context) {
    for (final extension in extensions) {
      extension.attach(context);
    }
  }

  @override
  List<SingleChildWidget> buildProviders() {
    return <SingleChildWidget>[
      for (final extension in extensions) ...extension.buildProviders(),
    ];
  }

  @override
  List<EditorActionSpec> get actionSpecs => <EditorActionSpec>[
    for (final extension in extensions) ...extension.actionSpecs,
  ];

  @override
  InspectorFieldRowBuilder? get inspectorFieldRowBuilder {
    for (final extension in extensions.reversed) {
      final builder = extension.inspectorFieldRowBuilder;
      if (builder != null) return builder;
    }
    return null;
  }

  @override
  void dispose() {
    for (final extension in extensions.reversed) {
      extension.dispose();
    }
  }
}

EditorExtension<TSourceDocument> pngExportExtension<TSourceDocument>(
  PngExportCapability capability,
) {
  return StaticEditorExtension<TSourceDocument>(
    actionSpecs: pngExportActions(capability),
  );
}

EditorExtension<TSourceDocument> sceneJsonExportExtension<TSourceDocument>(
  JsonExportCapability capability,
) {
  return StaticEditorExtension<TSourceDocument>(
    actionSpecs: sceneJsonExportActions(capability),
  );
}
