import 'package:canvas_core/canvas_core_runtime.dart' as rt;
import 'package:canvas_editor_flutter/extensions.dart';
import 'package:canvas_editor_flutter/src/editor_api.dart'
    show CanvasSceneDocumentAdapter;
import 'package:canvas_editor_flutter/src/runtime/editor_runtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

const _textData = rt.TextData(
  text: 'Original title',
  fontFamily: 'Inter',
  fontWeight: 400,
  fontSize: 24,
  letterSpacing: 0,
  fill: rt.CanvasFill.solid(0xFF111111),
  shadowOffset: 0,
);

rt.CanvasSceneDocument _scene() {
  return rt.CanvasSceneDocument(
    artboardSize: const rt.Size2D(300, 200),
    backgroundFill: const rt.CanvasFill.none(),
    backgroundOpacity: 1,
    children: <rt.Node>[
      rt.Node.text(
        id: 't1',
        xf: const rt.Transform2D(position: rt.Vec2(20, 20)),
        data: _textData,
      ),
    ],
  );
}

String _textOf(rt.CanvasSceneDocument scene) {
  return (rt.findById(scene, 't1') as rt.TextNode).data.text;
}

double _xOf(rt.CanvasSceneDocument scene) {
  return (rt.findById(scene, 't1') as rt.TextNode).xf.position.x;
}

final class _PolicyDocument {
  const _PolicyDocument({
    required this.base,
    this.denyText = false,
    this.denyScene = false,
    this.denyTextWhenMoved = false,
  });

  final rt.CanvasSceneDocument base;
  final bool denyText;
  final bool denyScene;
  final bool denyTextWhenMoved;

  _PolicyDocument copyWith({
    rt.CanvasSceneDocument? base,
    bool? denyText,
    bool? denyScene,
    bool? denyTextWhenMoved,
  }) {
    return _PolicyDocument(
      base: base ?? this.base,
      denyText: denyText ?? this.denyText,
      denyScene: denyScene ?? this.denyScene,
      denyTextWhenMoved: denyTextWhenMoved ?? this.denyTextWhenMoved,
    );
  }
}

final class _PolicyAdapter extends EditorDocumentAdapter<_PolicyDocument> {
  const _PolicyAdapter();

  @override
  rt.CanvasSceneDocument getBase(_PolicyDocument document) => document.base;

  @override
  _PolicyDocument replaceBase(
    _PolicyDocument document,
    rt.CanvasSceneDocument base,
  ) {
    return document.copyWith(base: base);
  }

  @override
  rt.CanvasSceneDocument resolve(_PolicyDocument document, Object? context) {
    return document.base;
  }

  @override
  String? fieldEditDisabledReason(
    _PolicyDocument document,
    rt.ElementId nodeId,
    rt.CanvasFieldKey fieldKey,
  ) {
    if (nodeId == kSceneFieldsId &&
        fieldKey == rt.CanvasFields.sceneBackgroundOpacity &&
        document.denyScene) {
      return 'Scene field is source-locked';
    }

    if (fieldKey != rt.CanvasFields.textContent) return null;

    if (document.denyText) {
      return 'Field is source-locked';
    }

    if (document.denyTextWhenMoved) {
      final node = rt.findById(document.base, nodeId);
      if (node is rt.TextNode && node.xf.position.x > 20) {
        return 'Moved field is source-locked';
      }
    }

    return null;
  }
}

EditorRuntime<_PolicyDocument> _buildPolicyRuntime(
  _PolicyDocument initial, {
  Map<rt.CanvasFieldKey, FieldCodec> extraFieldCodecs =
      const <rt.CanvasFieldKey, FieldCodec>{},
}) {
  return EditorRuntime<_PolicyDocument>(
    initial: initial,
    adapter: const _PolicyAdapter(),
    renderPipeline: rt.CanvasRenderPipeline(textMeasurer: _FakeTextMeasurer()),
    extraFieldCodecs: extraFieldCodecs,
  );
}

EditorRuntime<rt.CanvasSceneDocument> _buildSceneRuntime() {
  return EditorRuntime<rt.CanvasSceneDocument>(
    initial: _scene(),
    adapter: const CanvasSceneDocumentAdapter(),
    renderPipeline: rt.CanvasRenderPipeline(textMeasurer: _FakeTextMeasurer()),
  );
}

void main() {
  test('public extensions entrypoint exposes the scene-field sentinel', () {
    expect(kSceneFieldsId, '__scene__');
  });

  test('default document adapter keeps registered fields editable', () {
    final runtime = _buildSceneRuntime();
    addTearDown(runtime.dispose);

    expect(
      runtime
          .getField<String>('t1', rt.CanvasFields.textContent)
          .disabledReason,
      isNull,
    );

    runtime.commitField<String>(
      't1',
      rt.CanvasFields.textContent,
      'Updated title',
    );

    expect(_textOf(runtime.sourceDocument), 'Updated title');
    expect(runtime.canUndo.value, isTrue);
  });

  test('denial is exposed and denied commit is a complete no-op', () {
    var codecCommitCalls = 0;

    final runtime = _buildPolicyRuntime(
      _PolicyDocument(base: _scene(), denyText: true),
      extraFieldCodecs: <rt.CanvasFieldKey, FieldCodec>{
        rt.CanvasFields.textContent: FieldCodec(
          fallback: '',
          readNode: (_, node) => (node as rt.TextNode).data.text,
          commit: (controller, nodeId, value) {
            codecCommitCalls += 1;
          },
        ),
      },
    );
    addTearDown(runtime.dispose);

    var sourceNotifications = 0;
    var documentNotifications = 0;
    var renderNotifications = 0;

    runtime.source.addListener(() => sourceNotifications += 1);
    runtime.document.addListener(() => documentNotifications += 1);
    runtime.render.addListener(() => renderNotifications += 1);

    final state = runtime.getField<String>('t1', rt.CanvasFields.textContent);

    expect(state.value, 'Original title');
    expect(state.disabledReason, 'Field is source-locked');

    runtime.commitField<String>(
      't1',
      rt.CanvasFields.textContent,
      'Rejected title',
    );

    expect(codecCommitCalls, 0);
    expect(_textOf(runtime.sourceDocument.base), 'Original title');
    expect(runtime.canUndo.value, isFalse);
    expect(sourceNotifications, 0);
    expect(documentNotifications, 0);
    expect(renderNotifications, 0);
  });

  test(
    'intrinsic invalid-target reason takes precedence over adapter denial',
    () {
      final runtime = _buildPolicyRuntime(
        _PolicyDocument(base: _scene(), denyText: true),
      );
      addTearDown(runtime.dispose);

      final state = runtime.getField<String>(
        'missing',
        rt.CanvasFields.textContent,
      );

      expect(state.disabledReason, 'Missing canonical node');
    },
  );

  test('scene-level registered fields can be denied', () {
    final runtime = _buildPolicyRuntime(
      _PolicyDocument(base: _scene(), denyScene: true),
    );
    addTearDown(runtime.dispose);

    final state = runtime.getField<double>(
      kSceneFieldsId,
      rt.CanvasFields.sceneBackgroundOpacity,
    );

    expect(state.value, 1);
    expect(state.disabledReason, 'Scene field is source-locked');

    runtime.commitField<double>(
      kSceneFieldsId,
      rt.CanvasFields.sceneBackgroundOpacity,
      0.5,
    );

    expect(runtime.sourceDocument.base.backgroundOpacity, 1);
    expect(runtime.canUndo.value, isFalse);
  });

  test('source-only metadata changes editability and follows undo/redo', () {
    final initial = _PolicyDocument(base: _scene());
    final runtime = _buildPolicyRuntime(initial);
    addTearDown(runtime.dispose);

    final initialBase = runtime.sourceDocument.base;
    var documentNotifications = 0;
    var renderNotifications = 0;

    runtime.document.addListener(() => documentNotifications += 1);
    runtime.render.addListener(() => renderNotifications += 1);

    expect(
      runtime
          .getField<String>('t1', rt.CanvasFields.textContent)
          .disabledReason,
      isNull,
    );

    runtime.updateSourceDocument(
      (document) => document.copyWith(denyText: true),
    );

    expect(runtime.sourceDocument.base, same(initialBase));
    expect(documentNotifications, 0);
    expect(renderNotifications, 1);
    expect(
      runtime
          .getField<String>('t1', rt.CanvasFields.textContent)
          .disabledReason,
      'Field is source-locked',
    );

    runtime.undo();

    expect(
      runtime
          .getField<String>('t1', rt.CanvasFields.textContent)
          .disabledReason,
      isNull,
    );

    runtime.redo();

    expect(
      runtime
          .getField<String>('t1', rt.CanvasFields.textContent)
          .disabledReason,
      'Field is source-locked',
    );
  });

  testWidgets(
    'field policy uses transaction-present state before deferred publication',
    (tester) async {
      final runtime = _buildPolicyRuntime(
        _PolicyDocument(base: _scene(), denyTextWhenMoved: true),
      );
      addTearDown(runtime.dispose);

      final endSession = runtime.beginEditSession();

      runtime.updateDragMany({'t1'}, const rt.Vec2(10, 0));

      expect(
        _xOf(runtime.sourceDocument.base),
        20,
        reason:
            'Published source should still lag the scheduled gesture frame.',
      );
      expect(
        runtime
            .getField<String>('t1', rt.CanvasFields.textContent)
            .disabledReason,
        'Moved field is source-locked',
      );

      runtime.commitField<String>(
        't1',
        rt.CanvasFields.textContent,
        'Rejected title',
      );

      await tester.pump();
      endSession();

      expect(_xOf(runtime.sourceDocument.base), 30);
      expect(_textOf(runtime.sourceDocument.base), 'Original title');
    },
  );

  testWidgets(
    'source-only denial rebuild disables row and closes active edit session',
    (tester) async {
      final runtime = _buildPolicyRuntime(_PolicyDocument(base: _scene()));
      addTearDown(runtime.dispose);

      final spec = InspectorFieldSpec<String>(
        fieldKey: rt.CanvasFields.textContent,
        title: 'Content',
        commitMode: CommitMode.debounced,
        debounce: const Duration(hours: 1),
        control:
            (
              context, {
              required enabled,
              required value,
              required commit,
              begin,
              end,
              flush,
            }) {
              return TextButton(
                onPressed: enabled ? () => commit('Edited title') : null,
                child: Text(enabled ? 'enabled' : 'disabled'),
              );
            },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<rt.RenderSnapshot>(
            valueListenable: runtime.render,
            builder: (context, snapshot, child) {
              return Material(
                child: InspectorFieldRow<String>(
                  nodeId: 't1',
                  controller: runtime,
                  spec: spec,
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('enabled'), findsOneWidget);

      await tester.tap(find.text('enabled'));
      await tester.pump();

      expect(_textOf(runtime.sourceDocument.base), 'Edited title');
      expect(runtime.canUndo.value, isFalse);

      runtime.updateSourceDocument(
        (document) => document.copyWith(denyText: true),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('disabled'), findsOneWidget);
      expect(find.text('Field is source-locked'), findsOneWidget);
      expect(runtime.canUndo.value, isTrue);
    },
  );
}
