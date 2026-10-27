/// Explicit upgrades from supported historical Canvas JSON to the current scene.
///
/// Normal document loading remains in `package:canvas_core/canvas_core_runtime.dart`.
/// Import this optional package only at an application-controlled upgrade boundary.
library;

export 'src/upgrade_scene.dart' show upgradeCanvasScene;
