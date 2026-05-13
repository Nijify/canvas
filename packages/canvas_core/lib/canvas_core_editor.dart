// Path: oss_packages/canvas_core/lib/canvas_core_editor.dart
//
// canvas_core_editor – Public EDITOR utilities (interaction mechanics)
//
// Mental model:
// Editor utilities are “how you interact with a runtime scene” (undo/redo,
// picking, snapping). They operate on *resolved runtime data*
// (CanvasSceneDocument / Node), and do not define a second scene system.
//
// Dependency direction:
//   • Editor helpers depend on runtime.
//   • Runtime does NOT depend on editor helpers.
// Importing guidance:
//   • Interactive editor UI: import BOTH
//       - canvas_core_runtime.dart  (scene + compute + paint ops)
//       - canvas_core_editor.dart   (interaction mechanics)
//
//   • Editor helpers consume ComputedScene so picking/snapping match rendered output.

// ─────────────────────────────────────────────────────────────────────────────

library;

// ============================================================================
// 1) Picking / hit-test (editor-facing helpers; headless/runtime-safe)
// ============================================================================
export 'src/algorithms/picking/hit_test_scene.dart' show pickTopAtScene;

// ============================================================================
// 2) Snapping (headless, deterministic)
// ============================================================================
export 'src/algorithms/snapping/snap_types.dart'
    show
        SnapOptions,
        SnapResult,
        SnapLine,
        SnapKind,
        SnapAxis,
        SnapCandidate,
        SnapConfig;
export 'src/algorithms/snapping/snap_scene.dart' show snapScene;

// ============================================================================
// 3) History (editor-facing, headless)
// ============================================================================
export 'src/editor/history.dart' show History;
