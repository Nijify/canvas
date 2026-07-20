// Path: oss_packages/canvas_editor_flutter/test/editor_surface_features_test.dart

import 'package:canvas_core/canvas_core_runtime.dart' show GroupNode;
import 'package:canvas_editor_flutter/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final class _InspectorContextFake extends Fake implements InspectorContext {}

class _ViewportBehavior extends CanvasViewportBehavior {
  const _ViewportBehavior();
}

class _SceneObjectPolicy extends SceneObjectPresentationPolicy {
  const _SceneObjectPolicy();
}

void main() {
  group('EditorSurfaceFeatures', () {
    test('defaults to neutral live-surface configuration', () {
      const features = EditorSurfaceFeatures();

      expect(features.inspectorBuilder, isNull);
      expect(features.viewportFraming, isNull);
      expect(features.viewportBehavior, isNull);
      expect(features.selectionChromeMode, isNull);
      expect(features.sceneObjectPolicy, isNull);

      final node = GroupNode(id: 'node');

      expect(features.interactionPolicy.canMove(node), isTrue);
      expect(features.interactionPolicy.showTransformChrome(node), isTrue);
    });

    test('viewport framing encodes its target through contentBoundsSpec', () {
      const artboard = EditorViewportFraming.artboard(paddingPx: 12);

      const content = EditorViewportFraming.contentBounds(paddingPx: 4);

      expect(artboard.paddingPx, 12);
      expect(artboard.contentBoundsSpec, isNull);

      expect(content.paddingPx, 4);
      expect(content.contentBoundsSpec, isNotNull);
      expect(content.contentBoundsSpec!.paddingPx, 24);
    });

    test(
      'later inspector builder handles first and later surface values win',
      () {
        var earlierBuilderCalls = 0;
        var laterBuilderCalls = 0;

        final firstViewportBehavior = _ViewportBehavior();
        final secondViewportBehavior = _ViewportBehavior();

        final firstSceneObjectPolicy = _SceneObjectPolicy();
        final secondSceneObjectPolicy = _SceneObjectPolicy();

        const firstFraming = EditorViewportFraming.artboard(paddingPx: 12);
        const secondFraming = EditorViewportFraming.contentBounds(paddingPx: 4);

        final first = EditorSurfaceFeatures(
          inspectorBuilder: (_) {
            earlierBuilderCalls++;
            return const Text('Earlier inspector');
          },
          viewportFraming: firstFraming,
          interactionPolicy: EditorInteractionPolicy(
            canMoveNode: (_) => true,
            showTransformChromeNode: (_) => true,
          ),
          viewportBehavior: firstViewportBehavior,
          selectionChromeMode: SelectionChromeMode.transformControls,
          sceneObjectPolicy: firstSceneObjectPolicy,
        );

        final second = EditorSurfaceFeatures(
          inspectorBuilder: (_) {
            laterBuilderCalls++;
            return const Text('Later inspector');
          },
          viewportFraming: secondFraming,
          interactionPolicy: EditorInteractionPolicy(
            canMoveNode: (_) => false,
            showTransformChromeNode: (_) => false,
          ),
          viewportBehavior: secondViewportBehavior,
          selectionChromeMode: SelectionChromeMode.hidden,
          sceneObjectPolicy: secondSceneObjectPolicy,
        );

        final merged = first.merge(second);
        final panel = merged.inspectorBuilder!(_InspectorContextFake());

        expect(panel, isA<Text>());
        expect((panel as Text).data, 'Later inspector');
        expect(laterBuilderCalls, 1);
        expect(earlierBuilderCalls, 0);

        expect(merged.viewportFraming, same(secondFraming));
        expect(merged.viewportBehavior, same(secondViewportBehavior));
        expect(merged.selectionChromeMode, SelectionChromeMode.hidden);
        expect(merged.sceneObjectPolicy, same(secondSceneObjectPolicy));

        final node = GroupNode(id: 'node');

        expect(merged.interactionPolicy.canMove(node), isFalse);
        expect(merged.interactionPolicy.showTransformChrome(node), isFalse);
      },
    );

    test('later null inspector delegates to earlier inspector', () {
      var earlierBuilderCalls = 0;
      var laterBuilderCalls = 0;

      final first = EditorSurfaceFeatures(
        inspectorBuilder: (_) {
          earlierBuilderCalls++;
          return const Text('Earlier inspector');
        },
      );

      final second = EditorSurfaceFeatures(
        inspectorBuilder: (_) {
          laterBuilderCalls++;
          return null;
        },
      );

      final merged = first.merge(second);
      final panel = merged.inspectorBuilder!(_InspectorContextFake());

      expect(panel, isA<Text>());
      expect((panel as Text).data, 'Earlier inspector');
      expect(laterBuilderCalls, 1);
      expect(earlierBuilderCalls, 1);
    });

    test(
      'retains earlier optional surface values when later values are absent',
      () {
        const framing = EditorViewportFraming.contentBounds(paddingPx: 8);

        final viewportBehavior = _ViewportBehavior();
        final sceneObjectPolicy = _SceneObjectPolicy();

        Widget earlierInspector(InspectorContext context) {
          return const SizedBox.shrink();
        }

        final first = EditorSurfaceFeatures(
          inspectorBuilder: earlierInspector,
          viewportFraming: framing,
          viewportBehavior: viewportBehavior,
          selectionChromeMode: SelectionChromeMode.hidden,
          sceneObjectPolicy: sceneObjectPolicy,
        );

        final merged = first.merge(const EditorSurfaceFeatures());

        expect(merged.inspectorBuilder, same(earlierInspector));
        expect(merged.viewportFraming, same(framing));
        expect(merged.viewportBehavior, same(viewportBehavior));
        expect(merged.selectionChromeMode, SelectionChromeMode.hidden);
        expect(merged.sceneObjectPolicy, same(sceneObjectPolicy));
      },
    );
  });
}
