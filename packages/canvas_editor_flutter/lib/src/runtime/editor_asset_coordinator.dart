// Path: lib/src/runtime/editor_asset_coordinator.dart

import 'dart:async';

import 'package:canvas_core/canvas_core_runtime.dart' as rt;
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'package:canvas_editor_flutter/src/canvas_runtime_resources.dart';

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

  int _revision = 0;
  bool _disposed = false;

  void dispose() {
    if (_disposed) return;

    _disposed = true;
    _revision++;
  }

  /// Ensures runtime resources needed by [scene].
  ///
  /// Returns true when at least one requested font family became available
  /// during this call.
  Future<bool> ensureForScene(rt.CanvasSceneDocument scene) async {
    if (_disposed) {
      return false;
    }

    final localRevision = ++_revision;

    bool stillValid() {
      return !_disposed && localRevision == _revision;
    }

    final families = rt.collectSceneFontFamilies(
      scene,
      fallbackFontFamilies: assets.fonts.fallbackFontFamilies,
      icons: assets.icons,
    );

    final fontsChanged = await assets.fonts.ensureLoaded(families);

    // Font registration is global Flutter state. Preserve the result even when
    // this scene request became stale so the editor can clear cached layouts.
    if (!stillValid()) {
      return fontsChanged;
    }

    // Intrinsic metadata is best effort for interactive editing and must not
    // gate raster loading.
    unawaited(_resolveSceneIntrinsicsBestEffort(scene));

    await pool.preloadScene(scene, targetW: targetW, targetH: targetH);

    return fontsChanged;
  }

  Future<void> _resolveSceneIntrinsicsBestEffort(
    rt.CanvasSceneDocument scene,
  ) async {
    try {
      await pool.resolveSceneIntrinsics(scene);
    } catch (error, stackTrace) {
      debugPrint(
        'Canvas intrinsic metadata resolution failed: '
        '$error\n$stackTrace',
      );
    }
  }
}
