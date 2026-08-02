// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/actions/editor_action_sets.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:canvas_core/canvas_core_runtime.dart'
    show CanvasFillNone, CanvasFit;
import 'package:canvas_editor_flutter/src/editor_host_capabilities.dart';
import 'package:canvas_editor_flutter/src/presentation/actions/editor_actions.dart';
import 'package:flutter/material.dart';

Future<void> _withSpinner(
  EditorActionContext ctx,
  Future<void> Function() fn,
) async {
  ctx.ui.showSpinner();
  try {
    await fn();
  } catch (e) {
    ctx.ui.toast('Operation failed: $e');
  } finally {
    ctx.ui.hideSpinner();
  }
}

final List<EditorActionSpec> coreEditorActions = [
  EditorActionSpec(
    id: EditorActionIds.undo,
    section: EditorToolbarSection.undoRedo,
    labelBuilder: (_) => 'Undo',
    iconBuilder: (_) => Icons.undo,
    isEnabled: (state) => state.canUndo,
    isVisible: (_) => true,
    invoke: (ctx) => ctx.undo(),
  ),
  EditorActionSpec(
    id: EditorActionIds.redo,
    section: EditorToolbarSection.undoRedo,
    labelBuilder: (_) => 'Redo',
    iconBuilder: (_) => Icons.redo,
    isEnabled: (state) => state.canRedo,
    isVisible: (_) => true,
    invoke: (ctx) => ctx.redo(),
  ),
  EditorActionSpec(
    id: EditorActionIds.duplicate,
    section: EditorToolbarSection.edit,
    labelBuilder: (_) => 'Duplicate',
    iconBuilder: (_) => Icons.content_copy,
    isEnabled: (state) => state.hasSelection,
    isVisible: (_) => true,
    invoke: (ctx) => ctx.duplicateSelection(),
  ),
  EditorActionSpec(
    id: EditorActionIds.duplicateGroup,
    section: EditorToolbarSection.edit,
    labelBuilder: (_) => 'Duplicate Group',
    iconBuilder: (_) => Icons.collections,
    isEnabled: (state) => state.hasSelection,
    isVisible: (_) => true,
    invoke: (ctx) => ctx.duplicateSelection(),
  ),
  EditorActionSpec(
    id: EditorActionIds.deleteSelection,
    section: EditorToolbarSection.edit,
    labelBuilder: (_) => 'Delete',
    iconBuilder: (_) => Icons.delete_outline,
    isEnabled: (state) => state.hasSelection,
    isVisible: (_) => true,
    invoke: (ctx) => ctx.deleteSelection(),
  ),
  EditorActionSpec(
    id: EditorActionIds.deleteGroup,
    section: EditorToolbarSection.edit,
    labelBuilder: (_) => 'Delete Group',
    iconBuilder: (_) => Icons.delete_sweep_outlined,
    isEnabled: (state) => state.hasSelection,
    isVisible: (_) => true,
    invoke: (ctx) => ctx.deleteSelection(),
  ),
  EditorActionSpec(
    id: EditorActionIds.bringToFront,
    section: EditorToolbarSection.arrange,
    labelBuilder: (_) => 'Bring to Front',
    iconBuilder: (_) => Icons.vertical_align_top,
    isEnabled: (state) => state.hasSelection,
    isVisible: (_) => true,
    invoke: (ctx) => ctx.bringToFront(),
  ),
  EditorActionSpec(
    id: EditorActionIds.sendToBack,
    section: EditorToolbarSection.arrange,
    labelBuilder: (_) => 'Send to Back',
    iconBuilder: (_) => Icons.vertical_align_bottom,
    isEnabled: (state) => state.hasSelection,
    isVisible: (_) => true,
    invoke: (ctx) => ctx.sendToBack(),
  ),
  EditorActionSpec(
    id: EditorActionIds.bringForward,
    section: EditorToolbarSection.arrange,
    labelBuilder: (_) => 'Bring Forward',
    iconBuilder: (_) => Icons.arrow_upward,
    isEnabled: (state) => state.hasSelection,
    isVisible: (_) => true,
    invoke: (ctx) => ctx.bringForward(),
  ),
  EditorActionSpec(
    id: EditorActionIds.sendBackward,
    section: EditorToolbarSection.arrange,
    labelBuilder: (_) => 'Send Backward',
    iconBuilder: (_) => Icons.arrow_downward,
    isEnabled: (state) => state.hasSelection,
    isVisible: (_) => true,
    invoke: (ctx) => ctx.sendBackward(),
  ),
];

List<EditorActionSpec> pngExportActions(PngExportCapability capability) {
  return [
    EditorActionSpec(
      id: EditorActionIds.sharePng,
      section: EditorToolbarSection.export,
      labelBuilder: (_) => 'Share PNG',
      iconBuilder: (_) => Icons.ios_share,
      isEnabled: (_) => true,
      isVisible: (_) => capability.canShare,
      invoke: (ctx) async {
        await _withSpinner(ctx, () async {
          final bytes = await _renderCurrentPng(ctx, capability);

          final msg = await capability.output.sharePng(
            bytes,
            filename: 'canvas_export.png',
          );

          ctx.ui.toast(msg);
        });
      },
    ),
    EditorActionSpec(
      id: EditorActionIds.savePng,
      section: EditorToolbarSection.export,
      labelBuilder: (_) => 'Save as PNG',
      iconBuilder: (_) => Icons.download,
      isEnabled: (_) => true,
      isVisible: (_) => capability.canSave,
      invoke: (ctx) async {
        await _withSpinner(ctx, () async {
          final bytes = await _renderCurrentPng(ctx, capability);

          final msg = await capability.output.savePng(
            bytes,
            filename: 'canvas_export.png',
          );

          ctx.ui.toast(msg);
        });
      },
    ),
  ];
}

List<EditorActionSpec> sceneJsonExportActions(JsonExportCapability capability) {
  String encodeScene(EditorActionContext ctx) {
    final jsonMap = ctx.editableScene.toJson();
    if (!capability.pretty) return jsonEncode(jsonMap);
    return const JsonEncoder.withIndent('  ').convert(jsonMap);
  }

  return [
    EditorActionSpec(
      id: EditorActionIds.copySceneJson,
      section: EditorToolbarSection.export,
      labelBuilder: (_) => 'Copy Scene JSON',
      iconBuilder: (_) => Icons.data_object,
      isEnabled: (_) => true,
      isVisible: (_) => capability.canCopy,
      invoke: (ctx) async {
        await _withSpinner(ctx, () async {
          final msg = await capability.output.copyJson(json: encodeScene(ctx));
          ctx.ui.toast(msg);
        });
      },
    ),
    EditorActionSpec(
      id: EditorActionIds.saveSceneJson,
      section: EditorToolbarSection.export,
      labelBuilder: (_) => 'Export Scene JSON',
      iconBuilder: (_) => Icons.file_download_outlined,
      isEnabled: (_) => true,
      isVisible: (_) => capability.canSave,
      invoke: (ctx) async {
        await _withSpinner(ctx, () async {
          final msg = await capability.output.saveJson(
            json: encodeScene(ctx),
            filename: capability.defaultFilename,
          );
          ctx.ui.toast(msg);
        });
      },
    ),
  ];
}

Future<Uint8List> _renderCurrentPng(
  EditorActionContext ctx,
  PngExportCapability export,
) async {
  final scene = ctx.renderScene;

  await ctx.resources.ensureFontsForScene(scene);

  final jsonStr = jsonEncode(scene.toJson());
  final art = scene.artboardSize;

  const maxSide = 2048.0;
  final scale = maxSide / (art.w > art.h ? art.w : art.h);
  final w = (art.w * scale).round();
  final h = (art.h * scale).round();

  return export.renderer.renderPng(
    documentJson: jsonStr,
    spec: EditorExportSpec(
      widthPx: w,
      heightPx: h,
      bleedPx: 0,
      transparent:
          scene.backgroundFill is CanvasFillNone ||
          !(scene.backgroundOpacity > 0),
      fit: CanvasFit.contain,
      pixelRatio: 2.0,
    ),
  );
}
