// Path: oss_packages/canvas_editor_flutter/test/editor_extensions_test.dart
import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/extensions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

RenderSnapshot _firstRenderBuilder(
  CanvasRenderPipeline pipeline,
  CanvasSceneDocument scene, {
  ContentBoundsSpec? contentBounds,
}) {
  return defaultSceneRenderBuilder(
    pipeline,
    scene,
    contentBounds: contentBounds,
  );
}

RenderSnapshot _secondRenderBuilder(
  CanvasRenderPipeline pipeline,
  CanvasSceneDocument scene, {
  ContentBoundsSpec? contentBounds,
}) {
  return defaultSceneRenderBuilder(
    pipeline,
    scene,
    contentBounds: contentBounds,
  );
}

FieldCodec _codec(String fallback) {
  return FieldCodec(fallback: fallback, commit: (_, _, _) {});
}

Widget _firstRow<T>(
  ElementId nodeId,
  EditorController controller,
  InspectorFieldSpec<T> spec,
) {
  return const SizedBox.shrink();
}

Widget _secondRow<T>(
  ElementId nodeId,
  EditorController controller,
  InspectorFieldSpec<T> spec,
) {
  return const SizedBox.shrink();
}

final class _RowBuilderExtension extends EditorExtension<Object> {
  const _RowBuilderExtension(this.builder);

  final InspectorFieldRowBuilder builder;

  @override
  InspectorFieldRowBuilder get inspectorFieldRowBuilder => builder;
}

final class _ProviderExtension extends EditorExtension<Object> {
  const _ProviderExtension(this.providers);

  final List<SingleChildWidget> providers;

  @override
  List<SingleChildWidget> buildProviders() => providers;
}

final class _LifecycleExtension extends EditorExtension<Object> {
  _LifecycleExtension({required this.name, required this.events});

  final String name;
  final List<String> events;

  @override
  void attach(EditorExtensionContext<Object> context) {
    events.add('attach:$name');
  }

  @override
  void dispose() {
    events.add('dispose:$name');
  }
}

final class _DocumentHostFake extends Fake
    implements EditorDocumentHost<Object> {}

EditorActionSpec _action(EditorActionId id) {
  return EditorActionSpec(
    id: id,
    section: EditorToolbarSection.edit,
    labelBuilder: (_) => id.value,
    iconBuilder: (_) => const IconData(0xe3af),
    isEnabled: (_) => true,
    isVisible: (_) => true,
    invoke: (_) {},
  );
}

void main() {
  group('CompositeEditorExtension construction contributions', () {
    test('uses the later non-null render builder', () {
      final extension = CompositeEditorExtension<Object>([
        StaticEditorExtension<Object>(renderBuilder: _firstRenderBuilder),
        StaticEditorExtension<Object>(renderBuilder: _secondRenderBuilder),
      ]);

      expect(extension.renderBuilder, same(_secondRenderBuilder));
    });

    test('merges codecs in order with later keys overriding earlier keys', () {
      const sharedKey = CanvasFieldKey('test.shared');
      const firstOnlyKey = CanvasFieldKey('test.first');
      const secondOnlyKey = CanvasFieldKey('test.second');

      final firstShared = _codec('first');
      final secondShared = _codec('second');
      final firstOnly = _codec('first-only');
      final secondOnly = _codec('second-only');

      final extension = CompositeEditorExtension<Object>([
        StaticEditorExtension<Object>(
          fieldCodecs: <CanvasFieldKey, FieldCodec>{
            sharedKey: firstShared,
            firstOnlyKey: firstOnly,
          },
        ),
        StaticEditorExtension<Object>(
          fieldCodecs: <CanvasFieldKey, FieldCodec>{
            sharedKey: secondShared,
            secondOnlyKey: secondOnly,
          },
        ),
      ]);

      expect(extension.fieldCodecs, hasLength(3));
      expect(extension.fieldCodecs[sharedKey], same(secondShared));
      expect(extension.fieldCodecs[firstOnlyKey], same(firstOnly));
      expect(extension.fieldCodecs[secondOnlyKey], same(secondOnly));
    });

    test('merges surface features in extension order', () {
      final extension = CompositeEditorExtension<Object>([
        const StaticEditorExtension<Object>(
          surfaceFeatures: EditorSurfaceFeatures(
            selectionChromeMode: SelectionChromeMode.transformControls,
          ),
        ),
        const StaticEditorExtension<Object>(
          surfaceFeatures: EditorSurfaceFeatures(
            selectionChromeMode: SelectionChromeMode.hidden,
          ),
        ),
      ]);

      expect(
        extension.surfaceFeatures.selectionChromeMode,
        SelectionChromeMode.hidden,
      );
    });
  });

  group('CompositeEditorExtension non-construction behavior', () {
    test('concatenates action specs in extension order', () {
      const firstId = EditorActionId('test.action.first');
      const secondId = EditorActionId('test.action.second');

      final extension = CompositeEditorExtension<Object>([
        StaticEditorExtension<Object>(
          actionSpecs: <EditorActionSpec>[_action(firstId)],
        ),
        StaticEditorExtension<Object>(
          actionSpecs: <EditorActionSpec>[_action(secondId)],
        ),
      ]);

      expect(extension.actionSpecs.map((spec) => spec.id), <EditorActionId>[
        firstId,
        secondId,
      ]);
    });

    test('uses the later custom inspector row builder', () {
      final extension = CompositeEditorExtension<Object>([
        const _RowBuilderExtension(_firstRow),
        const _RowBuilderExtension(_secondRow),
      ]);

      expect(extension.inspectorFieldRowBuilder, same(_secondRow));
    });

    test('concatenates providers in extension order', () {
      final first = Provider<Object>.value(value: Object());
      final second = Provider<Object>.value(value: Object());

      final extension = CompositeEditorExtension<Object>([
        _ProviderExtension(<SingleChildWidget>[first]),
        _ProviderExtension(<SingleChildWidget>[second]),
      ]);

      expect(extension.buildProviders(), <SingleChildWidget>[first, second]);
    });

    test('attaches in child order and disposes in reverse child order', () {
      final events = <String>[];

      final extension = CompositeEditorExtension<Object>([
        _LifecycleExtension(name: 'first', events: events),
        _LifecycleExtension(name: 'second', events: events),
      ]);

      final context = EditorExtensionContext<Object>(
        documentHost: _DocumentHostFake(),
        requestRebuild: () {},
      );

      extension.attach(context);

      expect(events, <String>['attach:first', 'attach:second']);

      extension.dispose();

      expect(events, <String>[
        'attach:first',
        'attach:second',
        'dispose:second',
        'dispose:first',
      ]);
    });
  });
}
