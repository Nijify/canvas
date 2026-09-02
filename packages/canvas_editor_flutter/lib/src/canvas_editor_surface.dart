// Path: oss_packages/canvas_editor_flutter/lib/src/canvas_editor_surface.dart

import 'dart:async';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/editor_api.dart'
    show EditorController, EditorDocumentAdapter, SelectionState;
import 'package:canvas_editor_flutter/src/editor_field_codecs.dart'
    show FieldCodec;
import 'package:canvas_editor_flutter/src/editor_extensions.dart';
import 'package:canvas_editor_flutter/src/editor_surface_features.dart';
import 'package:canvas_editor_flutter/src/editor_shell_config.dart';
import 'package:canvas_editor_flutter/src/presentation/viewport/editor_camera_controller.dart';
import 'package:canvas_editor_flutter/src/canvas_runtime_resources.dart';
import 'package:canvas_editor_flutter/src/runtime/editor_asset_coordinator.dart';
import 'package:canvas_editor_flutter/src/runtime/editor_runtime.dart';
import 'package:canvas_editor_flutter/src/interaction/selection_controllers.dart';
import 'package:canvas_editor_flutter/src/presentation/layers/scene_object_tree.dart'
    show SceneObjectPresentationPolicy;
import 'package:canvas_editor_flutter/src/presentation/shortcuts/editor_shortcuts.dart';
import 'package:canvas_editor_flutter/src/presentation/widgets/canvas_editor_scaffold_layout.dart';
import 'package:canvas_editor_flutter/src/presentation/actions/editor_actions.dart';
import 'package:canvas_editor_flutter/src/presentation/actions/base_add_actions.dart'
    show baseAddActions;
import 'package:canvas_editor_flutter/src/presentation/actions/editor_action_sets.dart'
    show coreEditorActions;
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Lower-level editor surface for hosted or custom editor layouts.
///
/// One [CanvasEditorSurface] state owns one uncontrolled editor session:
/// interaction, selection, viewport, inspector/layers composition, history,
/// rendering services, and editor actions.
///
/// [initialDocument], [adapter], [initialResolveContext], [resources], and
/// [extensions] are captured when that session is created. Rebuilding with the
/// same key preserves the active session rather than replacing its document or
/// runtime configuration.
///
/// Hosts own app chrome, navigation, persistence, analytics, and deliberate
/// reload/discard decisions. Rebuild with a different [Key] to dispose the
/// current session and create a fresh one from different session inputs.
class CanvasEditorSurface<TSourceDocument> extends StatefulWidget {
  const CanvasEditorSurface({
    super.key,
    required this.initialDocument,
    required this.adapter,
    this.initialResolveContext,
    required this.resources,
    this.appBarBuilder,
    this.onSceneChanged,
    this.shell = EditorShellConfig.standalone,
    this.extensions = const [],
  });

  /// The source document used to create a new editor session.
  ///
  /// Rebuilding this surface with the same key does not replace the active edited
  /// source document. Use a different [Key] to intentionally create a fresh
  /// session from another document.
  final TSourceDocument initialDocument;

  final EditorDocumentAdapter<TSourceDocument> adapter;
  final Object? initialResolveContext;

  /// Runtime services used by this editor session.
  ///
  /// Resources are captured when the session is created so the renderer, image
  /// loading, font handling, inspector, and actions use one consistent resource
  /// set. Use a different [Key] to start a session with different resources.
  final CanvasRuntimeResources resources;

  final EditorAppBarBuilder? appBarBuilder;

  /// Called when the editable/base [CanvasSceneDocument] changes.
  ///
  /// For custom source-document adapters, this is the adapter's base runtime
  /// scene, not the resolved/prepared render scene.
  final ValueChanged<CanvasSceneDocument>? onSceneChanged;

  final EditorShellConfig shell;

  /// Optional feature composition for this editor session.
  ///
  /// Extensions and their runtime contributions are captured when the session is
  /// created. Rebuild with a different [Key] to use a different extension set.
  final List<EditorExtension<TSourceDocument>> extensions;

  @override
  State<CanvasEditorSurface<TSourceDocument>> createState() =>
      _CanvasEditorSurfaceState<TSourceDocument>();
}

class _CanvasEditorSurfaceState<TSourceDocument>
    extends State<CanvasEditorSurface<TSourceDocument>> {
  late final CanvasRuntimeResources _sessionResources;
  CanvasRuntimeResources get _assets => _sessionResources;

  late final FlutterImagePool _pool = FlutterImagePool(
    resolver: _assets.images,
  );

  late final EditorRuntime<TSourceDocument> _runtime;

  late final SelectionController _selectionController = SelectionController();

  late final EditorCameraController _camera = EditorCameraController();

  late final CompositeEditorExtension<TSourceDocument> _extension;
  late final EditorSurfaceFeatures _surfaceFeatures;

  late final List<EditorActionSpec> _actionSpecs;
  late final Map<EditorActionId, EditorActionSpec> _actionsById;

  EditorViewportFraming get _viewportFraming =>
      _surfaceFeatures.viewportFraming ??
      const EditorViewportFraming.artboard();

  late final VoidCallback _renderListener;
  late final VoidCallback _documentListener;

  StreamSubscription<ElementId>? _intrinsicSubscription;

  CanvasSceneDocument? _lastAssetScene;
  bool _isDisposing = false;

  // Latest viewport size reported by CanvasViewport (screen px).
  Size? _lastViewportPx;

  // Tracks the first viewport-size camera sync.
  //
  // This is only a paint gate for hosted content-bounds framing. In that mode,
  // the first visible frame should wait until rendered bounds and measured
  // viewport size have both been used to fit the focused content.

  bool _didInitialCameraSync = false;

  bool get _requiresInitialCameraGate =>
      widget.shell.hosted && _viewportFraming.contentBoundsSpec != null;

  bool get _cameraReady => !_requiresInitialCameraGate || _didInitialCameraSync;

  // Editor is long-lived; give text cache room but keep it bounded.
  late final _textPipeline = FlutterTextPipeline(
    maxEntries: 8192,
    fallbackFontFamilies: _assets.fonts.fallbackFontFamilies,
  );

  late final EditorAssetCoordinator _assetCoordinator = EditorAssetCoordinator(
    assets: _assets,
    pool: _pool,
    targetW: 2048,
    targetH: 2048,
  );

  late final CanvasRenderPipeline renderPipeline = CanvasRenderPipeline(
    textMeasurer: _textPipeline,
    images: _pool,
    icons: _assets.icons,
  );

  late final CanvasRenderer renderer = CanvasRenderer(
    images: _pool.images,
    text: _textPipeline,
    intrinsics: _pool,
    options: const CanvasRendererOptions(
      missingImageBehavior: MissingImageBehavior.placeholder,
    ),
  );

  void _invalidateFontLayouts() {
    if (_isDisposing) return;

    _textPipeline.clearCache();
    _runtime.scheduleLayoutInvalidation();
  }

  void _ensureAssetsForScene(CanvasSceneDocument scene) {
    if (identical(_lastAssetScene, scene) || _lastAssetScene == scene) {
      return;
    }

    _lastAssetScene = scene;

    unawaited(() async {
      final fontsChanged = await _assetCoordinator.ensureForScene(scene);

      if (_isDisposing) {
        return;
      }

      // Font registration changes Flutter text layout globally, even when the
      // asset request that loaded the fonts is no longer the latest request.
      if (fontsChanged) {
        _invalidateFontLayouts();
      }
    }());
  }

  void _handleViewportPx(Size vp) {
    _lastViewportPx = vp;

    if (_didInitialCameraSync) return;
    if (!vp.width.isFinite ||
        !vp.height.isFinite ||
        vp.width <= 0 ||
        vp.height <= 0) {
      return;
    }

    final snap = _runtime.render.value;

    _syncViewportCamera(viewportPx: vp, snap: snap, forceFit: true);

    if (_didInitialCameraSync) return;
    _didInitialCameraSync = true;

    if (!_requiresInitialCameraGate) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _syncViewportCamera({
    required Size viewportPx,
    required RenderSnapshot snap,
    required bool forceFit,
  }) {
    if (!viewportPx.width.isFinite ||
        !viewportPx.height.isFinite ||
        viewportPx.width <= 0 ||
        viewportPx.height <= 0) {
      return;
    }

    final framing = _viewportFraming;

    _camera.syncToLayout(
      viewportPx: viewportPx,
      artboard: snap.scene.artboardSize,
      paddingPx: framing.paddingPx,
      forceFit: forceFit,
      contentBounds: framing.contentBoundsSpec == null
          ? null
          : snap.contentBounds,
    );
  }

  @override
  void initState() {
    super.initState();

    _sessionResources = widget.resources;

    _extension = CompositeEditorExtension<TSourceDocument>(
      List<EditorExtension<TSourceDocument>>.unmodifiable(widget.extensions),
    );

    final scenePreparer = _extension.scenePreparer;

    final fieldCodecs = Map<CanvasFieldKey, FieldCodec>.unmodifiable(
      _extension.fieldCodecs,
    );

    _surfaceFeatures = _extension.surfaceFeatures;

    final viewportFraming = _viewportFraming;

    _runtime = EditorRuntime<TSourceDocument>(
      initial: widget.initialDocument,
      adapter: widget.adapter,
      renderPipeline: renderPipeline,
      initialContext: widget.initialResolveContext,
      scenePreparer: scenePreparer,
      maxHistory: 100,
      contentBounds: viewportFraming.contentBoundsSpec,
      extraFieldCodecs: fieldCodecs,
    );

    _intrinsicSubscription = _pool.onIntrinsicUpdated.listen((_) {
      if (_isDisposing) return;

      _runtime.scheduleLayoutInvalidation();
    });

    PaintingBinding.instance.systemFonts.addListener(_invalidateFontLayouts);

    _ensureAssetsForScene(_runtime.render.value.scene);

    _extension.attach(
      EditorExtensionContext<TSourceDocument>(
        documentHost: _runtime,
        requestRebuild: () {
          if (!mounted) return;
          setState(() {});
        },
      ),
    );

    _actionSpecs = _freezeActionSpecs(<EditorActionSpec>[
      ...coreEditorActions,
      ...baseAddActions,
      ..._extension.actionSpecs,
    ]);

    _actionsById = Map<EditorActionId, EditorActionSpec>.unmodifiable({
      for (final spec in _actionSpecs) spec.id: spec,
    });

    _renderListener = () {
      if (!mounted) return;

      final snap = _runtime.render.value;

      _ensureAssetsForScene(snap.scene);

      // Keep camera sync in CanvasEditorSurface, not CanvasViewport.build().
      // The viewport should render the camera it receives; syncing here avoids
      // stale framing when content bounds change.
      if (_viewportFraming.contentBoundsSpec != null) {
        final viewportPx = _lastViewportPx;

        if (viewportPx != null) {
          _syncViewportCamera(
            viewportPx: viewportPx,
            snap: snap,
            forceFit: true,
          );
        }
      }
    };

    _runtime.render.addListener(_renderListener);

    _documentListener = () {
      if (!mounted) return;

      widget.onSceneChanged?.call(_runtime.document.value);
    };

    _runtime.document.addListener(_documentListener);
  }

  @override
  void didUpdateWidget(
    covariant CanvasEditorSurface<TSourceDocument> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    // Editor-session configuration is intentionally captured in initState:
    //
    // - initialDocument
    // - adapter and initialResolveContext
    // - resources
    // - extensions and their runtime contributions
    //
    // Rebuild the editor with a new key to intentionally create a fresh session
    // from different values.
    if (oldWidget.shell.hosted != widget.shell.hosted) {
      _didInitialCameraSync = false;
    }
  }

  @override
  void dispose() {
    _isDisposing = true;

    final intrinsicSubscription = _intrinsicSubscription;
    _intrinsicSubscription = null;
    unawaited(intrinsicSubscription?.cancel());

    PaintingBinding.instance.systemFonts.removeListener(_invalidateFontLayouts);

    _runtime.render.removeListener(_renderListener);
    _runtime.document.removeListener(_documentListener);

    _extension.dispose();
    _runtime.dispose();

    _camera.dispose();
    _selectionController.dispose();

    _assetCoordinator.dispose();
    _pool.dispose();
    _textPipeline.dispose();

    super.dispose();
  }

  List<EditorActionSpec> _freezeActionSpecs(Iterable<EditorActionSpec> source) {
    final ids = <EditorActionId>{};
    final specs = <EditorActionSpec>[];
    for (final spec in source) {
      if (!ids.add(spec.id)) {
        throw StateError('Duplicate editor action ID: ${spec.id}');
      }
      specs.add(spec);
    }
    return List<EditorActionSpec>.unmodifiable(specs);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _runtime;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SelectionController>.value(
          value: _selectionController,
        ),
        Provider<EditorController>.value(value: controller),
        ..._extension.buildProviders(),
      ],
      child: Builder(
        builder: (ctx) {
          final ui = _OverlayUiFeedback(
            Overlay.of(ctx, rootOverlay: true),
            ScaffoldMessenger.of(ctx),
          );

          return CallbackShortcuts(
            bindings: buildEditorShortcutBindings(ctx),
            child: Focus(
              autofocus: true,
              child: ValueListenableBuilder<SelectionState>(
                valueListenable: _selectionController,
                builder: (context, selectionState, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: controller.canUndo,
                    builder: (context, canUndo, _) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: controller.canRedo,
                        builder: (context, canRedo, _) {
                          final toolbarState = EditorToolbarState(
                            compact: MediaQuery.of(context).size.width < 500,
                            canUndo: canUndo,
                            canRedo: canRedo,
                            hasSelection: selectionState.hasItems,
                          );

                          final actionContext = EditorActionContext(
                            buildContext: ctx,
                            resources: _sessionResources,
                            ui: ui,
                            controller: controller,
                            selection: _selectionController,
                          );

                          final actions = EditorActionDispatcher(
                            context: actionContext,
                            actions: _actionsById,
                          );

                          final inspectorFieldRowBuilder =
                              _extension.inspectorFieldRowBuilder;

                          return CanvasEditorScaffoldLayout(
                            shell: widget.shell,
                            camera: _camera,
                            onViewportPx: _handleViewportPx,
                            cameraReady: _cameraReady,
                            selectionChromeMode:
                                _surfaceFeatures.selectionChromeMode ??
                                SelectionChromeMode.transformControls,
                            resources: _sessionResources,
                            toolbarState: toolbarState,
                            actions: actions,
                            actionSpecs: _actionSpecs,
                            renderer: renderer,
                            repaint: _pool.revision,
                            appBarBuilder: widget.appBarBuilder,
                            inspectorBuilder: _surfaceFeatures.inspectorBuilder,
                            inspectorSections:
                                _surfaceFeatures.inspectorSections,
                            interactionPolicy:
                                _surfaceFeatures.interactionPolicy,
                            viewportBehavior: _surfaceFeatures.viewportBehavior,
                            sceneObjectPolicy:
                                _surfaceFeatures.sceneObjectPolicy ??
                                const SceneObjectPresentationPolicy(),
                            inspectorFieldRowBuilder: inspectorFieldRowBuilder,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

final class _OverlayUiFeedback implements UiFeedback {
  _OverlayUiFeedback(this._overlay, this._scaffoldMessenger);

  final OverlayState _overlay;
  final ScaffoldMessengerState _scaffoldMessenger;

  OverlayEntry? _entry;
  int _depth = 0;

  @override
  void showSpinner() {
    _depth++;
    if (_entry != null) return;
    if (!_overlay.mounted) return;

    _entry = OverlayEntry(
      builder: (_) => const IgnorePointer(
        child: ColoredBox(
          color: Color(0x66000000),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    _overlay.insert(_entry!);
  }

  @override
  void hideSpinner() {
    if (_depth > 0) _depth--;

    if (_depth == 0 && _entry != null) {
      final entry = _entry!;
      _entry = null;

      if (entry.mounted) {
        entry.remove();
      }
    }
  }

  @override
  void toast(String msg) {
    if (!_scaffoldMessenger.mounted) return;
    _scaffoldMessenger.showSnackBar(SnackBar(content: Text(msg)));
  }
}
