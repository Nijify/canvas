// Path: packages/canvas_editor_flutter/test/shadow_authoring_test.dart

import 'package:canvas_core/canvas_core_runtime.dart' as rt;
import 'package:canvas_editor_flutter/src/editor_api.dart';
import 'package:canvas_editor_flutter/src/interaction/selection_controllers.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/controls.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_context.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_fields.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/shadow_editor.dart';
import 'package:canvas_editor_flutter/src/runtime/editor_runtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editor_runtime_fakes.dart';

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

rt.CanvasSceneDocument _scene({
  List<rt.CanvasSourceUnderlay> textUnderlays =
      const <rt.CanvasSourceUnderlay>[],
  List<rt.CanvasSourceUnderlay> iconUnderlays =
      const <rt.CanvasSourceUnderlay>[],
}) {
  return rt.CanvasSceneDocument(
    artboardSize: const rt.Size2D(300, 200),
    backgroundFill: const rt.CanvasFill.none(),
    backgroundOpacity: 1,
    children: <rt.Node>[
      rt.Node.text(
        id: 'text',
        data: rt.TextData(
          text: 'Shadow',
          fontFamily: 'TestFont',
          fontWeight: 400,
          fontSize: 24,
          letterSpacing: 0,
          appearance: rt.CanvasAppearance(
            foreground: const rt.CanvasFill.solid(0xFF111111),
            underlays: textUnderlays,
          ),
        ),
      ),
      rt.Node.icon(
        id: 'icon',
        data: rt.CanvasIconData(
          iconRef: 'icon:test',
          sizePx: 48,
          appearance: rt.CanvasAppearance(
            foreground: const rt.CanvasFill.solid(0xFF111111),
            underlays: iconUnderlays,
          ),
        ),
      ),
    ],
  );
}

List<rt.CanvasSourceUnderlay> _underlaysOf(
  rt.CanvasSceneDocument scene,
  rt.ElementId nodeId,
) {
  final node = rt.findById(scene, nodeId);

  return switch (node) {
    rt.TextNode text => text.data.appearance.underlays,
    rt.IconNode icon => icon.data.appearance.underlays,
    _ => throw StateError('Expected text or icon node: $nodeId'),
  };
}

rt.ShadowEffect _shadowOf(
  rt.CanvasSceneDocument scene,
  rt.ElementId nodeId,
  String shadowId,
) {
  return _underlaysOf(
    scene,
    nodeId,
  ).whereType<rt.ShadowEffect>().singleWhere((shadow) => shadow.id == shadowId);
}

EditorRuntime<rt.CanvasSceneDocument> _runtime(
  rt.CanvasSceneDocument initial, {
  EditorDocumentAdapter<rt.CanvasSceneDocument> adapter =
      const CanvasSceneDocumentAdapter(),
}) {
  return EditorRuntime<rt.CanvasSceneDocument>(
    initial: initial,
    adapter: adapter,
    renderPipeline: rt.CanvasRenderPipeline(textMeasurer: _FakeTextMeasurer()),
  );
}

final class _ResolvedShadowAdapter
    extends EditorDocumentAdapter<rt.CanvasSceneDocument> {
  const _ResolvedShadowAdapter();

  @override
  rt.CanvasSceneDocument getBase(rt.CanvasSceneDocument document) => document;

  @override
  rt.CanvasSceneDocument replaceBase(
    rt.CanvasSceneDocument document,
    rt.CanvasSceneDocument base,
  ) {
    return base;
  }

  @override
  rt.CanvasSceneDocument resolve(
    rt.CanvasSceneDocument document,
    Object? context,
  ) {
    final node = rt.findById(document, 'text');

    if (node is! rt.TextNode) {
      return document;
    }

    return rt.replaceById(
      document,
      'text',
      node.copyWith(
        data: node.data.copyWith(
          appearance: node.data.appearance.copyWith(
            underlays: const <rt.CanvasSourceUnderlay>[
              rt.CanvasSourceUnderlay.shadow(
                id: 'resolved',
                offset: rt.Vec2(99, 99),
                blurSigma: 20,
                color: 0xAAFF0000,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _DeniedShadowAdapter
    extends EditorDocumentAdapter<rt.CanvasSceneDocument> {
  const _DeniedShadowAdapter();

  @override
  rt.CanvasSceneDocument getBase(rt.CanvasSceneDocument document) => document;

  @override
  rt.CanvasSceneDocument replaceBase(
    rt.CanvasSceneDocument document,
    rt.CanvasSceneDocument base,
  ) {
    return base;
  }

  @override
  rt.CanvasSceneDocument resolve(
    rt.CanvasSceneDocument document,
    Object? context,
  ) {
    return document;
  }

  @override
  String? fieldEditDisabledReason(
    rt.CanvasSceneDocument document,
    rt.ElementId nodeId,
    rt.CanvasFieldKey fieldKey,
  ) {
    if (nodeId == 'text' && fieldKey == rt.CanvasFields.textUnderlays) {
      return 'Shadow editing is disabled';
    }

    return null;
  }
}

Widget _unusedFieldRowBuilder<T>(
  rt.ElementId nodeId,
  EditorController controller,
  InspectorFieldSpec<T> spec,
) {
  return const SizedBox.shrink();
}

Widget _shadowHarness({
  required EditorRuntime<rt.CanvasSceneDocument> runtime,
  required SelectionController selection,
  required rt.ElementId nodeId,
  required rt.CanvasFieldKey fieldKey,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ValueListenableBuilder<rt.CanvasSceneDocument>(
          valueListenable: runtime.document,
          builder: (context, editableScene, child) {
            final inspector = InspectorContext(
              selectedId: nodeId,
              selection: selection,
              controller: runtime,
              editableScene: editableScene,
              renderedScene: runtime.render.value.scene,
              resources: canvasRuntimeResourcesForTest(),
              fieldRowBuilder: _unusedFieldRowBuilder,
            );

            return ShadowEditor(
              key: ValueKey<String>('shadow-editor:$nodeId:${fieldKey.value}'),
              nodeId: nodeId,
              inspector: inspector,
              fieldKey: fieldKey,
            );
          },
        ),
      ),
    ),
  );
}

Finder _numberField(String shadowId, String field) {
  return find.descendant(
    of: find.byKey(ValueKey<String>('$shadowId:$field')),
    matching: find.byType(TextFormField),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('underlay field identities are stable', () {
    expect(rt.CanvasFields.textUnderlays.value, 'text.underlays');
    expect(rt.CanvasFields.iconUnderlays.value, 'icon.underlays');
  });

  test('text and icon underlay codecs update the matching appearance', () {
    final runtime = _runtime(_scene());
    addTearDown(runtime.dispose);

    runtime.commitField<List<rt.CanvasSourceUnderlay>>(
      'text',
      rt.CanvasFields.textUnderlays,
      const <rt.CanvasSourceUnderlay>[
        rt.CanvasSourceUnderlay.shadow(
          id: 'text-shadow',
          offset: rt.Vec2(1, 2),
          blurSigma: 3,
          color: 0x66000000,
        ),
      ],
    );

    runtime.commitField<List<rt.CanvasSourceUnderlay>>(
      'icon',
      rt.CanvasFields.iconUnderlays,
      const <rt.CanvasSourceUnderlay>[
        rt.CanvasSourceUnderlay.shadow(
          id: 'icon-shadow',
          offset: rt.Vec2(4, 5),
          blurSigma: 6,
          color: 0x77000000,
        ),
      ],
    );

    expect(
      _underlaysOf(
        runtime.sourceDocument,
        'text',
      ).map((underlay) => underlay.id),
      <String>['text-shadow'],
    );

    expect(
      _underlaysOf(
        runtime.sourceDocument,
        'icon',
      ).map((underlay) => underlay.id),
      <String>['icon-shadow'],
    );

    final text = rt.findById(runtime.sourceDocument, 'text') as rt.TextNode;
    final icon = rt.findById(runtime.sourceDocument, 'icon') as rt.IconNode;

    expect(
      text.data.appearance.foreground,
      const rt.CanvasFill.solid(0xFF111111),
    );
    expect(
      icon.data.appearance.foreground,
      const rt.CanvasFill.solid(0xFF111111),
    );
  });

  test(
    'functional shadow update starts from canonical underlays when resolved differs',
    () {
      final runtime = _runtime(
        _scene(
          textUnderlays: const <rt.CanvasSourceUnderlay>[
            rt.CanvasSourceUnderlay.shadow(
              id: 'canonical',
              offset: rt.Vec2(1, 2),
              blurSigma: 3,
              color: 0x66000000,
            ),
          ],
        ),
        adapter: const _ResolvedShadowAdapter(),
      );
      addTearDown(runtime.dispose);

      final presentation = runtime
          .getField<List<rt.CanvasSourceUnderlay>>(
            'text',
            rt.CanvasFields.textUnderlays,
          )
          .value;

      expect(presentation.single.id, 'resolved');

      var observedCanonicalId = '';

      runtime.updateField<List<rt.CanvasSourceUnderlay>>(
        'text',
        rt.CanvasFields.textUnderlays,
        (current) {
          observedCanonicalId = current.single.id;

          final shadow = current.single as rt.ShadowEffect;

          return <rt.CanvasSourceUnderlay>[shadow.copyWith(blurSigma: 8)];
        },
      );

      expect(observedCanonicalId, 'canonical');

      final canonical = _shadowOf(runtime.sourceDocument, 'text', 'canonical');

      expect(canonical.blurSigma, 8);
      expect(canonical.offset, const rt.Vec2(1, 2));
    },
  );

  test('missing wrong-kind and denied targets do not invoke updater', () {
    final normalRuntime = _runtime(_scene());
    addTearDown(normalRuntime.dispose);

    var updaterCalls = 0;

    normalRuntime.updateField<List<rt.CanvasSourceUnderlay>>(
      'missing',
      rt.CanvasFields.textUnderlays,
      (current) {
        updaterCalls += 1;
        return current;
      },
    );

    normalRuntime.updateField<List<rt.CanvasSourceUnderlay>>(
      'icon',
      rt.CanvasFields.textUnderlays,
      (current) {
        updaterCalls += 1;
        return current;
      },
    );

    expect(updaterCalls, 0);
    expect(normalRuntime.canUndo.value, isFalse);

    final deniedRuntime = _runtime(
      _scene(),
      adapter: const _DeniedShadowAdapter(),
    );
    addTearDown(deniedRuntime.dispose);

    final state = deniedRuntime.getField<List<rt.CanvasSourceUnderlay>>(
      'text',
      rt.CanvasFields.textUnderlays,
    );

    expect(state.disabledReason, 'Shadow editing is disabled');

    deniedRuntime.updateField<List<rt.CanvasSourceUnderlay>>(
      'text',
      rt.CanvasFields.textUnderlays,
      (current) {
        updaterCalls += 1;
        return current;
      },
    );

    expect(updaterCalls, 0);
    expect(deniedRuntime.canUndo.value, isFalse);
  });

  test('reorder and edit preserve IDs through undo redo and JSON', () {
    final original = _scene(
      textUnderlays: const <rt.CanvasSourceUnderlay>[
        rt.CanvasSourceUnderlay.shadow(
          id: 'a',
          offset: rt.Vec2(1, 1),
          blurSigma: 2,
          color: 0x66000000,
        ),
        rt.CanvasSourceUnderlay.shadow(
          id: 'b',
          offset: rt.Vec2(2, 2),
          blurSigma: 4,
          color: 0x77000000,
        ),
      ],
    );

    final runtime = _runtime(original);
    addTearDown(runtime.dispose);

    final endSession = runtime.beginEditSession();

    runtime.updateField<List<rt.CanvasSourceUnderlay>>(
      'text',
      rt.CanvasFields.textUnderlays,
      (current) => <rt.CanvasSourceUnderlay>[current[1], current[0]],
    );

    runtime.updateField<List<rt.CanvasSourceUnderlay>>(
      'text',
      rt.CanvasFields.textUnderlays,
      (current) {
        final next = List<rt.CanvasSourceUnderlay>.of(current);
        final index = next.indexWhere((underlay) => underlay.id == 'a');

        final shadow = next[index] as rt.ShadowEffect;
        next[index] = shadow.copyWith(blurSigma: 9);

        return next;
      },
    );

    endSession();

    expect(
      _underlaysOf(
        runtime.sourceDocument,
        'text',
      ).map((underlay) => underlay.id),
      <String>['b', 'a'],
    );
    expect(_shadowOf(runtime.sourceDocument, 'text', 'a').blurSigma, 9);

    final encoded = rt.encodeCanvasScene(runtime.sourceDocument);
    final restored = rt.decodeCanvasScene(encoded);

    expect(
      _underlaysOf(restored, 'text').map((underlay) => underlay.id),
      <String>['b', 'a'],
    );
    expect(_shadowOf(restored, 'text', 'a').blurSigma, 9);

    runtime.undo();

    expect(
      _underlaysOf(
        runtime.sourceDocument,
        'text',
      ).map((underlay) => underlay.id),
      <String>['a', 'b'],
    );
    expect(_shadowOf(runtime.sourceDocument, 'text', 'a').blurSigma, 2);

    runtime.redo();

    expect(
      _underlaysOf(
        runtime.sourceDocument,
        'text',
      ).map((underlay) => underlay.id),
      <String>['b', 'a'],
    );
    expect(_shadowOf(runtime.sourceDocument, 'text', 'a').blurSigma, 9);
  });

  testWidgets(
    'shadow editor adds exact defaults rejects invalid numbers and preserves alpha',
    (tester) async {
      final runtime = _runtime(_scene());
      addTearDown(runtime.dispose);

      final selection = SelectionController()..selectItem('text');
      addTearDown(selection.dispose);

      await tester.pumpWidget(
        _shadowHarness(
          runtime: runtime,
          selection: selection,
          nodeId: 'text',
          fieldKey: rt.CanvasFields.textUnderlays,
        ),
      );

      await tester.tap(find.text('Add Shadow'));
      await tester.pump();

      final underlays = _underlaysOf(runtime.sourceDocument, 'text');

      expect(underlays, hasLength(1));

      final added = underlays.single as rt.ShadowEffect;

      expect(added.id.trim(), isNotEmpty);
      expect(added.enabled, isTrue);
      expect(added.offset, const rt.Vec2(4, 4));
      expect(added.blurSigma, 4);
      expect(added.color, 0x66000000);

      final colorPicker = tester.widget<SwatchPickerRow>(
        find.byType(SwatchPickerRow),
      );

      colorPicker.onPick(0xFFEF4444);
      await tester.pump();

      expect(
        _shadowOf(runtime.sourceDocument, 'text', added.id).color,
        0x66EF4444,
        reason: 'Picking an RGB swatch must preserve authored alpha.',
      );

      await tester.enterText(_numberField(added.id, 'blur'), '-1');
      await tester.pump();

      expect(find.text('Enter a finite number ≥ 0'), findsOneWidget);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(
        _shadowOf(runtime.sourceDocument, 'text', added.id).blurSigma,
        4,
        reason: 'Invalid blur drafts must not be committed.',
      );

      await tester.enterText(_numberField(added.id, 'offset-x'), '-12.5');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(
        _shadowOf(runtime.sourceDocument, 'text', added.id).offset.x,
        -12.5,
      );
    },
  );

  testWidgets('reorder uses IDs and stale removed-shadow callback is a no-op', (
    tester,
  ) async {
    final runtime = _runtime(
      _scene(
        textUnderlays: const <rt.CanvasSourceUnderlay>[
          rt.CanvasSourceUnderlay.shadow(
            id: 'a',
            offset: rt.Vec2(1, 1),
            blurSigma: 2,
            color: 0x66000000,
          ),
          rt.CanvasSourceUnderlay.shadow(
            id: 'b',
            offset: rt.Vec2(2, 2),
            blurSigma: 4,
            color: 0x77000000,
          ),
        ],
      ),
    );
    addTearDown(runtime.dispose);

    final selection = SelectionController()..selectItem('text');
    addTearDown(selection.dispose);

    await tester.pumpWidget(
      _shadowHarness(
        runtime: runtime,
        selection: selection,
        nodeId: 'text',
        fieldKey: rt.CanvasFields.textUnderlays,
      ),
    );

    final aCard = find.byKey(const ValueKey<String>('shadow:a'));

    final staleToggle = tester
        .widget<Switch>(
          find.descendant(of: aCard, matching: find.byType(Switch)),
        )
        .onChanged!;

    await tester.tap(
      find.descendant(of: aCard, matching: find.byTooltip('Move forward')),
    );
    await tester.pump();

    expect(
      _underlaysOf(
        runtime.sourceDocument,
        'text',
      ).map((underlay) => underlay.id),
      <String>['b', 'a'],
    );

    final movedACard = find.byKey(const ValueKey<String>('shadow:a'));

    await tester.tap(
      find.descendant(
        of: movedACard,
        matching: find.byTooltip('Remove shadow'),
      ),
    );
    await tester.pump();

    expect(
      _underlaysOf(
        runtime.sourceDocument,
        'text',
      ).map((underlay) => underlay.id),
      <String>['b'],
    );

    staleToggle(false);
    await tester.pump();

    expect(
      _underlaysOf(
        runtime.sourceDocument,
        'text',
      ).map((underlay) => underlay.id),
      <String>['b'],
      reason: 'A callback for a removed shadow must not touch another entry.',
    );

    runtime.undo();

    expect(
      _underlaysOf(
        runtime.sourceDocument,
        'text',
      ).map((underlay) => underlay.id),
      <String>['b', 'a'],
    );

    runtime.undo();

    expect(
      _underlaysOf(
        runtime.sourceDocument,
        'text',
      ).map((underlay) => underlay.id),
      <String>['a', 'b'],
      reason: 'The stale no-op must not create an extra history entry.',
    );
  });
}
