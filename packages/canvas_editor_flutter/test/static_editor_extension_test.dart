// Path: oss_packages/canvas_editor_flutter/test/static_editor_extension_test.dart

import 'package:canvas_core/canvas_core_runtime.dart'
    show CanvasFieldKey, SceneRenderBuilder, defaultSceneRenderBuilder;
import 'package:canvas_editor_flutter/extensions.dart';
import 'package:flutter_test/flutter_test.dart';

FieldCodec _codec() {
  return FieldCodec(fallback: '', commit: (_, _, _) {});
}

void main() {
  group('StaticEditorExtension', () {
    test('uses empty direct contributions when arguments are omitted', () {
      const extension = StaticEditorExtension<Object>();

      expect(extension.renderBuilder, isNull);
      expect(extension.fieldCodecs, isEmpty);

      expect(extension.surfaceFeatures.inspectorBuilder, isNull);
      expect(extension.surfaceFeatures.viewportFraming, isNull);
      expect(extension.surfaceFeatures.viewportBehavior, isNull);
      expect(extension.surfaceFeatures.selectionChromeMode, isNull);
      expect(extension.surfaceFeatures.sceneObjectPolicy, isNull);

      expect(extension.actionSpecs, isEmpty);
    });

    test('retains explicit direct contributions by identity', () {
      final SceneRenderBuilder renderBuilder = defaultSceneRenderBuilder;

      final fieldCodecs = <CanvasFieldKey, FieldCodec>{
        const CanvasFieldKey('test.field'): _codec(),
      };

      const surfaceFeatures = EditorSurfaceFeatures(
        selectionChromeMode: SelectionChromeMode.hidden,
      );
      final actionSpecs = <EditorActionSpec>[];

      final extension = StaticEditorExtension<Object>(
        renderBuilder: renderBuilder,
        fieldCodecs: fieldCodecs,
        surfaceFeatures: surfaceFeatures,
        actionSpecs: actionSpecs,
      );

      expect(identical(extension.renderBuilder, renderBuilder), isTrue);
      expect(identical(extension.fieldCodecs, fieldCodecs), isTrue);
      expect(identical(extension.surfaceFeatures, surfaceFeatures), isTrue);
      expect(identical(extension.actionSpecs, actionSpecs), isTrue);
    });
  });
}
