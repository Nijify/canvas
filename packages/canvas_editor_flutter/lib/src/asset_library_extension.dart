// Path: oss_packages/canvas_editor_flutter/lib/src/asset_library_extension.dart

import 'dart:math' as math;

import 'package:canvas_core/canvas_core_runtime.dart'
    show
        CanvasAssetId,
        CanvasImageAsset,
        ImageData,
        ImageFit,
        ImageNode,
        SceneTreeOps,
        Size2D,
        Transform2D,
        Vec2;
import 'package:canvas_editor_flutter/src/asset_library.dart'
    show
        CanvasAssetLibrary,
        CanvasAssetLibraryItem,
        CanvasAssetLibrarySelectionPresenter;
import 'package:canvas_editor_flutter/src/editor_extensions.dart'
    show EditorExtension, StaticEditorExtension;
import 'package:canvas_editor_flutter/src/editor_edits.dart' show EditorEdits;
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

          if (selected.sourceRef.trim().isEmpty) {
            context.ui.toast('Unable to add asset: missing image source.');
            return;
          }

          final artboard = context.editableScene.artboardSize;
          final size = _initialAssetSize(selected);
          final nodeId = _nextAssetNodeId();
          final assetId = nodeId;

          final node = ImageNode(
            id: nodeId,
            data: ImageData(
              assetId: assetId,
              size: size,
              fit: ImageFit.contain,
              align: const Vec2(0.5, 0.5),
            ),
            xf: Transform2D(position: Vec2(artboard.w * 0.5, artboard.h * 0.5)),
          );

          context.controller.applyEdit(
            EditorEdits.updateScene((scene) {
              final nextScene = scene.copyWith(
                assets: <CanvasAssetId, CanvasImageAsset>{
                  ...scene.assets,
                  assetId: CanvasImageAsset(
                    sourceRef: selected.sourceRef,
                    intrinsicSize: _validIntrinsicSize(selected.intrinsicSize),
                  ),
                },
              );

              return SceneTreeOps.addNode(nextScene, node);
            }),
          );
          context.selectItems([nodeId]);
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

Size2D? _validIntrinsicSize(Size2D size) {
  if (!size.w.isFinite || !size.h.isFinite || size.w <= 0 || size.h <= 0) {
    return null;
  }

  return size;
}

double _safeDefaultSize(double value) {
  if (!value.isFinite || value <= 0) {
    return 220;
  }

  return value;
}
