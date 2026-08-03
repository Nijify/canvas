// Path: oss_packages/canvas_editor_flutter/test/canvas_editor_surface_extension_integration_test.dart

import 'package:canvas_core/canvas_core_runtime.dart' as rt;
import 'package:canvas_editor_flutter/extensions.dart';
import 'package:canvas_editor_flutter/src/runtime/editor_runtime.dart';
import 'package:canvas_editor_flutter/src/presentation/widgets/canvas_viewport_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editor_runtime_fakes.dart';

const _nodeId = 't1';
const _customFieldValue = 'Value from surface extension codec';
const _contentBoundsPaddingPx = 37.0;

rt.CanvasSceneDocument _fixtureScene() {
  return const rt.CanvasSceneDocument(
    artboardSize: rt.Size2D(300, 200),
    backgroundFill: rt.CanvasFill.none(),
    backgroundOpacity: 1.0,
    children: <rt.Node>[
      rt.Node.text(
        id: _nodeId,
        xf: rt.Transform2D(position: rt.Vec2(20, 20)),
        data: rt.TextData(
          text: 'Original title',
          fontFamily: 'Inter',
          fontWeight: 400,
          fontSize: 24,
          letterSpacing: 0,
          fill: rt.CanvasFill.solid(0xFF111111),
          shadowOffset: 0,
        ),
      ),
    ],
  );
}

final class _SurfaceSeamExtension
    extends EditorExtension<rt.CanvasSceneDocument> {
  EditorRuntime<rt.CanvasSceneDocument>? runtime;

  int renderBuilderCalls = 0;
  int codecReadCalls = 0;
  rt.ContentBoundsSpec? lastContentBounds;

  @override
  rt.SceneRenderBuilder get renderBuilder => _renderBuilder;

  rt.RenderSnapshot _renderBuilder(
    rt.CanvasRenderPipeline pipeline,
    rt.CanvasSceneDocument scene, {
    rt.ContentBoundsSpec? contentBounds,
    rt.TextMeasureCache? textMeasureCache,
  }) {
    renderBuilderCalls += 1;
    lastContentBounds = contentBounds;

    return rt.defaultSceneRenderBuilder(
      pipeline,
      scene,
      contentBounds: contentBounds,
      textMeasureCache: textMeasureCache,
    );
  }

  @override
  Map<rt.CanvasFieldKey, FieldCodec> get fieldCodecs {
    return <rt.CanvasFieldKey, FieldCodec>{
      rt.CanvasFields.textContent: FieldCodec(
        fallback: _customFieldValue,
        readNode: (_) {
          codecReadCalls += 1;
          return _customFieldValue;
        },
        commit: (_, _, _) {},
      ),
    };
  }

  @override
  EditorSurfaceFeatures get surfaceFeatures {
    return const EditorSurfaceFeatures(
      viewportFraming: EditorViewportFraming.contentBounds(
        contentBoundsSpec: rt.ContentBoundsSpec(
          paddingPx: _contentBoundsPaddingPx,
        ),
      ),
    );
  }

  @override
  void attach(EditorExtensionContext<rt.CanvasSceneDocument> context) {
    runtime = context.documentHost as EditorRuntime<rt.CanvasSceneDocument>;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'forwards direct extension seams into mounted editor runtime construction',
    (tester) async {
      final extension = _SurfaceSeamExtension();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox.expand(
            child: CanvasSceneEditor(
              initialScene: _fixtureScene(),
              resources: canvasRuntimeResourcesForTest(),
              extensions: <EditorExtension<rt.CanvasSceneDocument>>[extension],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(extension.runtime, isNotNull);

      expect(extension.renderBuilderCalls, greaterThanOrEqualTo(1));
      expect(extension.lastContentBounds, isNotNull);
      expect(extension.lastContentBounds!.paddingPx, _contentBoundsPaddingPx);

      final field = extension.runtime!.getField<String>(
        _nodeId,
        rt.CanvasFields.textContent,
      );

      expect(field.value, _customFieldValue);
      expect(field.disabledReason, isNull);
      expect(extension.codecReadCalls, 1);
    },
  );

  testWidgets('content-bounds render changes force a camera refit', (
    tester,
  ) async {
    final extension = _SurfaceSeamExtension();

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: CanvasSceneEditor(
            initialScene: _fixtureScene(),
            resources: canvasRuntimeResourcesForTest(),
            extensions: <EditorExtension<rt.CanvasSceneDocument>>[extension],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final runtime = extension.runtime!;

    expect(runtime.render.value.contentBounds, isNotNull);

    final viewportSurface = tester.widget<CanvasViewportSurface>(
      find.byType(CanvasViewportSurface).first,
    );

    final camera = viewportSurface.camera;
    final panBefore = camera.value.pan;
    final renderBuilderCallsBefore = extension.renderBuilderCalls;

    final endSession = runtime.beginEditSession();

    try {
      runtime.updateDragMany({_nodeId}, const rt.Vec2(80, 0));
    } finally {
      endSession();
    }

    await tester.pumpAndSettle();

    expect(extension.renderBuilderCalls, greaterThan(renderBuilderCallsBefore));

    expect(camera.value.pan, isNot(panBefore));
  });
}
