// Path: packages/canvas_editor_flutter/lib/src/runtime/editor_asset_coordinator.dart

import 'package:canvas_core/canvas_core_runtime.dart' as rt;
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';

import 'package:canvas_editor_flutter/src/canvas_runtime_resources.dart';

class AssetPipelineResult {
  const AssetPipelineResult({required this.fontsLoaded});

  final bool fontsLoaded;
}

class EditorAssetCoordinator {
  EditorAssetCoordinator({
    required this.assets,
    required this.pool,
    this.targetW = 1536,
    this.targetH = 1536,
  });

  final CanvasRuntimeResources assets;
  final FlutterImagePool pool;

  final int targetW;
  final int targetH;

  final Set<String> _ensuredFontFamilies = <String>{};

  int _revision = 0;
  bool _disposed = false;

  void dispose() {
    if (_disposed) return;

    _disposed = true;
    _revision++;
  }

  Future<AssetPipelineResult> ensureForScene(
    rt.CanvasSceneDocument scene,
  ) async {
    if (_disposed) {
      return const AssetPipelineResult(fontsLoaded: false);
    }

    final localRevision = ++_revision;

    bool stillValid() {
      return !_disposed && localRevision == _revision;
    }

    final families = assets.fontFamiliesForScene(scene);
    final newFamilies = families.difference(_ensuredFontFamilies);

    var fontsLoaded = false;

    if (newFamilies.isNotEmpty) {
      await assets.fonts.ensureLoaded(newFamilies);

      if (!stillValid()) {
        return const AssetPipelineResult(fontsLoaded: false);
      }

      _ensuredFontFamilies.addAll(newFamilies);
      fontsLoaded = true;
    }

    await pool.resolveSceneIntrinsics(scene);

    if (!stillValid()) {
      return AssetPipelineResult(fontsLoaded: fontsLoaded);
    }

    await pool.preloadScene(scene, targetW: targetW, targetH: targetH);

    return AssetPipelineResult(fontsLoaded: fontsLoaded);
  }
}
