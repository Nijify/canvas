// Path: oss_packages/canvas_editor_flutter/lib/asset_library.dart
// canvas_editor_flutter – Asset-library capability.
//
// Use this entrypoint to provide a curated asset catalog and an editor action
// that inserts selected assets into the canvas.

library;

export 'src/asset_library.dart'
    show
        CanvasAssetLibraryItem,
        CanvasAssetLibrary,
        LocalCanvasAssetLibrary,
        CanvasAssetLibrarySelectionPresenter;

export 'src/asset_library_extension.dart' show canvasAssetLibraryExtension;
