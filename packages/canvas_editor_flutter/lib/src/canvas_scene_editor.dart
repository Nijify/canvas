// Path: oss_packages/canvas_editor_flutter/lib/src/canvas_scene_editor.dart
import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/canvas_editor_surface.dart';
import 'package:canvas_editor_flutter/src/canvas_runtime_resources.dart';
import 'package:canvas_editor_flutter/src/editor_api.dart'
    show CanvasSceneDocumentAdapter;
import 'package:canvas_editor_flutter/src/editor_extensions.dart';
import 'package:canvas_editor_flutter/src/editor_host_capabilities.dart';
import 'package:canvas_editor_flutter/src/editor_shell_config.dart';
import 'package:flutter/widgets.dart';

/// Turnkey editor façade for a [CanvasSceneDocument].
///
/// Each mounted instance creates one uncontrolled editor session in the
/// underlying [CanvasEditorSurface].
///
/// [initialScene], [resources], export capabilities, and [extensions] configure
/// that session when it is created. Rebuilding with the same key preserves the
/// active edited scene and original runtime configuration.
///
/// To intentionally switch documents, discard edits, reload a chosen version,
/// or use a different resource or feature set, rebuild with a different [Key].
///
/// [resources] are required to render and edit existing scene content.
/// Optional host-owned write capabilities, such as user-image acquisition,
/// are supplied explicitly through [extensions].
class CanvasSceneEditor extends StatelessWidget {
  const CanvasSceneEditor({
    super.key,
    required this.initialScene,
    required this.resources,
    this.pngExport,
    this.jsonExport,
    this.onSceneChanged,
    this.shell = EditorShellConfig.standalone,
    this.appBarBuilder,
    this.extensions = const <EditorExtension<CanvasSceneDocument>>[],
  });

  /// The scene used to create a new editor session.
  ///
  /// This value is read when the session is created. Rebuilding
  /// [CanvasSceneEditor] with the same key does not replace the active edited
  /// scene.
  final CanvasSceneDocument initialScene;

  /// Runtime services captured for this editor session.
  ///
  /// The renderer, image loading, fonts, inspector, and actions use this same
  /// resource set until the editor is remounted with a different [Key].
  final CanvasRuntimeResources resources;

  final PngExportCapability? pngExport;
  final JsonExportCapability? jsonExport;

  /// Called when the editable/base [CanvasSceneDocument] changes.
  final ValueChanged<CanvasSceneDocument>? onSceneChanged;

  final EditorShellConfig shell;
  final EditorAppBarBuilder? appBarBuilder;

  /// Extensions that add or customize capabilities for this editor session.
  final List<EditorExtension<CanvasSceneDocument>> extensions;

  @override
  Widget build(BuildContext context) {
    return CanvasEditorSurface<CanvasSceneDocument>(
      initialDocument: initialScene,
      adapter: const CanvasSceneDocumentAdapter(),
      initialResolveContext: null,
      resources: resources,
      appBarBuilder: appBarBuilder,
      onSceneChanged: onSceneChanged,
      shell: shell,
      extensions: <EditorExtension<CanvasSceneDocument>>[
        if (pngExport != null)
          pngExportExtension<CanvasSceneDocument>(pngExport!),
        if (jsonExport != null)
          sceneJsonExportExtension<CanvasSceneDocument>(jsonExport!),
        ...extensions,
      ],
    );
  }
}
