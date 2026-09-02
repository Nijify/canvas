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

final class _FakeTextMeasurer implements rt.TextMeasurer {
  @override
  rt.Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required double letterSpacing,
  }) {
    return rt.Size2D(text.length * fontSize * 0.6, fontSize);
  }
}

final class _ResolvingAdapter
    extends EditorDocumentAdapter<rt.CanvasSceneDocument> {
  const _ResolvingAdapter();

  @override
  rt.CanvasSceneDocument getBase(rt.CanvasSceneDocument doc) => doc;

  @override
  rt.CanvasSceneDocument replaceBase(
    rt.CanvasSceneDocument doc,
    rt.CanvasSceneDocument base,
  ) {
    return base;
  }

  @override
  rt.CanvasSceneDocument resolve(rt.CanvasSceneDocument doc, Object? context) {
    return doc.copyWith(backgroundOpacity: 0.4);
  }
}

final class _SurfaceSeamExtension
    extends EditorExtension<rt.CanvasSceneDocument> {
  EditorRuntime<rt.CanvasSceneDocument>? runtime;

  int scenePreparerCalls = 0;
  int codecReadCalls = 0;
  rt.CoreServices? lastServices;

  @override
  rt.ScenePreparer get scenePreparer => _prepareScene;

  rt.CanvasSceneDocument _prepareScene(
    rt.CanvasSceneDocument scene,
    rt.CoreServices services,
  ) {
    scenePreparerCalls += 1;
    lastServices = services;
    return scene;
  }

  @override
  Map<rt.CanvasFieldKey, FieldCodec> get fieldCodecs {
    return <rt.CanvasFieldKey, FieldCodec>{
      rt.CanvasFields.textContent: FieldCodec(
        fallback: _customFieldValue,
        readNode: (_, _) {
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

  test(
    'resolves before preparation and preserves the canonical scene boundary',
    () {
      final canonicalScene = _fixtureScene();
      final pipeline = rt.CanvasRenderPipeline(
        textMeasurer: _FakeTextMeasurer(),
      );

      var preparerCalls = 0;
      rt.CanvasSceneDocument? receivedScene;
      rt.CoreServices? receivedServices;

      final runtime = EditorRuntime<rt.CanvasSceneDocument>(
        initial: canonicalScene,
        adapter: const _ResolvingAdapter(),
        renderPipeline: pipeline,
        scenePreparer: (scene, services) {
          preparerCalls += 1;
          receivedScene = scene;
          receivedServices = services;

          return scene.copyWith(backgroundOpacity: 0.8);
        },
      );

      addTearDown(runtime.dispose);

      expect(preparerCalls, 1);
      expect(receivedScene?.backgroundOpacity, 0.4);
      expect(identical(receivedServices, pipeline.services), isTrue);

      expect(identical(runtime.document.value, canonicalScene), isTrue);
      expect(runtime.document.value.backgroundOpacity, 1.0);
      expect(runtime.render.value.scene.backgroundOpacity, 0.8);

      final outputScene = runtime.resolveSceneForOutput();

      expect(outputScene.backgroundOpacity, 0.4);
      expect(
        preparerCalls,
        1,
        reason:
            'Resolving the final-output scene must not invoke ScenePreparer.',
      );
    },
  );

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
      expect(extension.scenePreparerCalls, greaterThanOrEqualTo(1));
      expect(
        identical(
          extension.lastServices,
          extension.runtime!.renderPipeline.services,
        ),
        isTrue,
      );
      expect(extension.runtime!.render.value.contentBounds, isNotNull);

      final field = extension.runtime!.getField<String>(
        _nodeId,
        rt.CanvasFields.textContent,
      );

      expect(field.value, _customFieldValue);
      expect(field.disabledReason, isNull);
      expect(extension.codecReadCalls, 1);
    },
  );

  testWidgets('system font changes invalidate mounted editor text layout', (
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

    final callsBefore = extension.scenePreparerCalls;

    await PaintingBinding.instance.handleSystemMessage(<String, dynamic>{
      'type': 'fontsChange',
    });
    await tester.pump();

    expect(extension.scenePreparerCalls, greaterThan(callsBefore));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await PaintingBinding.instance.handleSystemMessage(<String, dynamic>{
      'type': 'fontsChange',
    });
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

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
    final scenePreparerCallsBefore = extension.scenePreparerCalls;

    final endSession = runtime.beginEditSession();

    try {
      runtime.updateDragMany({_nodeId}, const rt.Vec2(80, 0));
    } finally {
      endSession();
    }

    await tester.pumpAndSettle();

    expect(extension.scenePreparerCalls, greaterThan(scenePreparerCallsBefore));

    expect(camera.value.pan, isNot(panBefore));
  });
}
