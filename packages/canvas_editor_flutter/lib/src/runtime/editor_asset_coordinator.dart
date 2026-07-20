// Path: oss_packages/canvas_editor_flutter/lib/src/runtime/editor_asset_coordinator.dart

import 'dart:async';

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
    required this.intrinsics,
    this.targetW = 1536,
    this.targetH = 1536,
  });

  final CanvasRuntimeResources assets;
  final FlutterImagePool pool;
  final FlutterImageIntrinsics intrinsics;

  final int targetW;
  final int targetH;

  final Set<String> _ensuredFontFamilies = <String>{};
  int _rev = 0;
  bool _disposed = false;

  void dispose() {
    _disposed = true;
    _rev++; // invalidate in-flight work
  }

  Future<AssetPipelineResult> ensureForScene(
    rt.CanvasSceneDocument scene,
  ) async {
    final int localRev = ++_rev;

    bool stillValid() => !_disposed && localRev == _rev;

    // 1) Fonts
    final families = assets.fontFamiliesForScene(scene);
    final newFamilies = families.difference(_ensuredFontFamilies);

    var fontsLoaded = false;
    if (newFamilies.isNotEmpty) {
      await assets.fonts.ensureLoaded(newFamilies);
      if (!stillValid()) return const AssetPipelineResult(fontsLoaded: false);

      _ensuredFontFamilies.addAll(newFamilies);
      fontsLoaded = true;
    }

    // 2) Intrinsics (layout relevant)
    await pool.resolveSceneIntrinsics(scene, intrinsics: intrinsics);
    if (!stillValid()) return AssetPipelineResult(fontsLoaded: fontsLoaded);

    // 3) Raster preload (paint optimization)
    await pool.preloadScene(
      scene,
      targetW: targetW,
      targetH: targetH,
      intrinsics: intrinsics,
    );
    if (!stillValid()) return AssetPipelineResult(fontsLoaded: fontsLoaded);

    return AssetPipelineResult(fontsLoaded: fontsLoaded);
  }
}
