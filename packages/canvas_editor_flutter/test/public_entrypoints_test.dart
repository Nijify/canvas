// Path: oss_packages/canvas_editor_flutter/test/public_entrypoints_test.dart

import 'dart:io';

import 'package:canvas_core/canvas_core_runtime.dart' show CanvasSceneDocument;
import 'package:canvas_editor_flutter/asset_library.dart' as assets;
import 'package:canvas_editor_flutter/canvas_editor_flutter.dart' as turnkey;
import 'package:canvas_editor_flutter/extensions.dart' as composable;
import 'package:canvas_editor_flutter/image_import.dart' as image_import;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('public entrypoints', () {
    test('turnkey entrypoint exports editor and runtime contracts', () {
      final supportedTypes = <Type>[
        turnkey.CanvasSceneEditor,
        turnkey.CanvasRuntimeResources,
        turnkey.CanvasFontAssets,
        turnkey.CanvasMediaResolver,
        turnkey.IconCatalogPort,
        turnkey.PngExportCapability,
        turnkey.PngOutputPort,
        turnkey.JsonExportCapability,
        turnkey.JsonOutputPort,
        turnkey.EditorExportSpec,
      ];

      expect(supportedTypes, hasLength(10));
    });

    test('turnkey entrypoint exports only turnkey modules', () {
      final source = File('lib/canvas_editor_flutter.dart').readAsStringSync();
      final exportPaths = RegExp(r"export '([^']+)'")
          .allMatches(source)
          .map((match) => match.group(1))
          .toList(growable: false);

      expect(exportPaths, <String>[
        'src/canvas_scene_editor.dart',
        'src/editor_host_capabilities.dart',
        'src/canvas_runtime_resources.dart',
      ]);
    });

    test('composable entrypoint exports editor composition contracts', () {
      final supportedTypes = <Type>[
        composable.CanvasSceneEditor,
        composable.CanvasEditorSurface,
        composable.EditorExtension,
        composable.EditorSurfaceFeatures,
        composable.EditorDocumentAdapter,
        composable.EditorDocumentHost,
        composable.EditorSelectionHost,
        composable.EditorController,
        composable.EditorShellConfig,
        composable.EditorActionSpec,
        composable.InspectorContext,
        composable.FieldCodec,
        composable.CanvasViewportBehavior,
        composable.EditorInteractionPolicy,
      ];

      expect(supportedTypes, hasLength(14));
    });

    test('capability entrypoints export asset and image integrations', () {
      final supportedTypes = <Type>[
        assets.CanvasAssetLibraryItem,
        assets.CanvasAssetLibrary,
        assets.LocalCanvasAssetLibrary,
        image_import.ImageImportSource,
        image_import.ImageImportResult,
        image_import.ImageImportPort,
      ];

      expect(supportedTypes, hasLength(6));
      expect(
        assets.canvasAssetLibraryExtension<CanvasSceneDocument>,
        isNotNull,
      );
      expect(image_import.imageImportExtension<CanvasSceneDocument>, isNotNull);
    });
  });
}
