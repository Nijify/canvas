// Path: oss_packages/canvas_editor_flutter/lib/extensions.dart
// canvas_editor_flutter – Composable scene editor API.
//
// This entrypoint re-exports the turnkey editor API and adds contracts for
// custom editor surfaces, document adapters, extensions, shell configuration,
// inspector content, actions, and interaction policies.
//
// Use these APIs to adapt the editor to different document models and product
// experiences while retaining the package's editing runtime and UI components.
//
// As part of the package's 0.x series, these APIs may evolve between minor
// releases.

library;

export 'canvas_editor_flutter.dart';

// Editor surfaces.
export 'src/canvas_editor_surface.dart' show CanvasEditorSurface;

// Extension composition.
export 'src/editor_extensions.dart'
    show
        EditorExtension,
        EditorExtensionContext,
        StaticEditorExtension,
        CompositeEditorExtension,
        pngExportExtension,
        sceneJsonExportExtension;

export 'src/editor_shell_config.dart'
    show
        EditorShellConfig,
        InspectorPresentation,
        HostedHeaderBuilder,
        HostedBottomBuilder,
        EditorAppBarBuilder;

export 'src/editor_surface_features.dart'
    show SelectionChromeMode, EditorViewportFraming, EditorSurfaceFeatures;

// Host contracts.
export 'src/editor_hosts.dart' show EditorDocumentHost, EditorSelectionHost;

// Object tree.
export 'src/presentation/layers/scene_object_tree.dart'
    show SceneObjectPresentationPolicy;

// Inspector composition.
export 'src/presentation/inspector/inspector_context.dart'
    show InspectorContext, InspectorBuilder, InspectorFieldRowBuilder;

export 'src/presentation/inspector/inspector.dart'
    show TextInspectorPanel, IconInspectorPanel;

export 'src/presentation/inspector/inspector_field_row.dart'
    show InspectorFieldRow;

export 'src/presentation/inspector/inspector_fields.dart'
    show CommitMode, InspectorFieldSpec, doubleSliderSpec, textFieldSpec;

export 'src/presentation/inspector/inspector_ui.dart'
    show InspectorUi, Gap, HintText, InspectorCard;

export 'src/presentation/inspector/fill_editor.dart'
    show FillEditor, FillFieldIds;

// Actions and default shell widgets.
export 'src/presentation/actions/editor_actions.dart'
    show
        EditorActionContext,
        EditorActionDispatcher,
        EditorActionId,
        EditorActionIds,
        EditorActionInvoke,
        EditorActionSpec,
        EditorToolbarSection,
        EditorToolbarState,
        UiFeedback;

export 'src/presentation/widgets/editor_app_bar.dart'
    show buildEditorToolbarActions;

// Controller, edit, field, and selection contracts.
export 'src/editor_api.dart'
    show
        EditorController,
        EditorDocumentAdapter,
        EditorEdit,
        EditorEditResult,
        SelectionState,
        FieldState,
        kSceneFieldsId;

export 'src/editor_edits.dart' show EditorEdits;
export 'src/editor_field_codecs.dart' show FieldCodec;

// Interaction and viewport policy.
export 'src/interaction/editor_interaction_policy.dart'
    show EditorInteractionPolicy, NodeMovePermission;

export 'src/interaction/canvas_viewport_behavior.dart'
    show
        CanvasViewportBehavior,
        CanvasViewportBehaviorContext,
        CanvasHitTestResult,
        CanvasDragStartIntent;
