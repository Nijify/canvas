// Path: oss_packages/canvas_editor_flutter/lib/src/asset_library_extension.dart

import 'dart:math' as math;

import 'package:canvas_core/canvas_core_runtime.dart'
    show ImageData, ImageFit, ImageNode, Size2D, Transform2D, Vec2;
import 'package:canvas_editor_flutter/src/asset_library.dart'
    show
        CanvasAssetLibrary,
        CanvasAssetLibraryItem,
        CanvasAssetLibrarySelectionPresenter;
import 'package:canvas_editor_flutter/src/editor_extensions.dart'
    show EditorExtension, StaticEditorExtension;
import 'package:canvas_editor_flutter/src/presentation/actions/editor_actions.dart'
    show EditorActionId, EditorActionSpec, EditorToolbarSection;
import 'package:flutter/material.dart' show Icons;

/// Creates an editor extension that inserts assets selected from [library].
///
/// The host owns the catalog and selection UI. The extension owns the shared
/// editor behavior after selection:
///
/// - persists [CanvasAssetLibraryItem.sourceRef], never `thumbnailRef`;
/// - preserves the intrinsic aspect ratio for the initial image size;
/// - places the image at the centre of the artboard;
/// - inserts through editor history and selects the new node.
///
/// The action is hidden when [library] contains no items.
EditorExtension<TSourceDocument> canvasAssetLibraryExtension<TSourceDocument>({
  required CanvasAssetLibrary library,
  required CanvasAssetLibrarySelectionPresenter presentSelection,
}) {
  final hasAssets = library.items.isNotEmpty;

  return StaticEditorExtension<TSourceDocument>(
    actionSpecs: <EditorActionSpec>[
      EditorActionSpec(
        id: const EditorActionId('assetLibrary.open'),
        section: EditorToolbarSection.add,
        labelBuilder: (_) => 'Assets',
        iconBuilder: (_) => Icons.collections_outlined,
        isEnabled: (_) => hasAssets,
        isVisible: (_) => hasAssets,
        priority: 85,
        invoke: (context) async {
          final selected = await presentSelection(
            context.buildContext,
            library,
          );

          if (selected == null || !context.buildContext.mounted) {
            return;
          }

          final artboard = context.editableScene.artboardSize;
          final size = _initialAssetSize(selected);

          final node = ImageNode(
            id: _nextAssetNodeId(),
            data: ImageData(
              sourcePath: selected.sourceRef,
              size: size,
              fit: ImageFit.contain,
              align: const Vec2(0.5, 0.5),
            ),
            xf: Transform2D(position: Vec2(artboard.w * 0.5, artboard.h * 0.5)),
          );

          context.addNodeAndSelect(node);
        },
      ),
    ],
  );
}

int _assetInsertSequence = 0;

String _nextAssetNodeId() {
  return 'asset_${DateTime.now().microsecondsSinceEpoch}_'
      '${_assetInsertSequence++}';
}

Size2D _initialAssetSize(CanvasAssetLibraryItem item) {
  final maxExtent = _safeDefaultSize(item.defaultSize);
  final width = item.intrinsicSize.w;
  final height = item.intrinsicSize.h;

  if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
    return Size2D(maxExtent, maxExtent);
  }

  final longestSide = math.max(width, height).toDouble();

  return Size2D(
    (width / longestSide) * maxExtent,
    (height / longestSide) * maxExtent,
  );
}

double _safeDefaultSize(double value) {
  if (!value.isFinite || value <= 0) {
    return 220;
  }

  return value;
}
