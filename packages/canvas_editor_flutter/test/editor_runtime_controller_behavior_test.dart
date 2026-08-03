// Path: oss_packages/canvas_editor_flutter/test/editor_runtime_controller_behavior_test.dart

import 'package:canvas_core/canvas_core_runtime.dart' as rt;
import 'package:canvas_editor_flutter/src/editor_api.dart';
import 'package:canvas_editor_flutter/src/editor_field_codecs.dart';
import 'package:canvas_editor_flutter/src/runtime/editor_runtime.dart';
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

const _baseTextData = rt.TextData(
  text: 'Original title',
  fontFamily: 'Inter',
  fontWeight: 400,
  fontSize: 24,
  letterSpacing: 0.0,
  fill: rt.CanvasFill.solid(0xFF111111),
  shadowOffset: 0,
);

rt.CanvasSceneDocument _sceneWithText(String text) {
  return rt.CanvasSceneDocument(
    artboardSize: const rt.Size2D(300, 200),
    backgroundFill: const rt.CanvasFill.none(),
    backgroundOpacity: 1.0,
    children: <rt.Node>[
      rt.Node.text(
        id: 't1',
        xf: const rt.Transform2D(position: rt.Vec2(20, 20)),
        data: _baseTextData.copyWith(text: text),
      ),
    ],
  );
}

double _letterSpacingOf(rt.CanvasSceneDocument scene) {
  final node = rt.findById(scene, 't1');
  return (node as rt.TextNode).data.letterSpacing;
}

String _textOf(rt.CanvasSceneDocument scene) {
  final node = rt.findById(scene, 't1');
  return (node as rt.TextNode).data.text;
}

rt.CanvasSceneDocument _emptyScene() {
  return rt.CanvasSceneDocument(
    artboardSize: const rt.Size2D(300, 200),
    backgroundFill: const rt.CanvasFill.none(),
    backgroundOpacity: 1.0,
    children: const <rt.Node>[],
  );
}

rt.CanvasSceneDocument _sceneWithIcon(String iconRef) {
  return rt.CanvasSceneDocument(
    artboardSize: const rt.Size2D(300, 200),
    backgroundFill: const rt.CanvasFill.none(),
    backgroundOpacity: 1.0,
    children: <rt.Node>[
      rt.Node.icon(
        id: 'i1',
        data: rt.CanvasIconData(iconRef: iconRef),
      ),
    ],
  );
}

rt.CanvasSceneDocument _sceneWithImage({rt.Size2D? size}) {
  return rt.CanvasSceneDocument(
    artboardSize: const rt.Size2D(300, 200),
    backgroundFill: const rt.CanvasFill.none(),
    backgroundOpacity: 1.0,
    children: <rt.Node>[
      rt.Node.image(
        id: 'img1',
        data: rt.ImageData(size: size),
      ),
    ],
  );
}

String _iconRefOf(rt.CanvasSceneDocument scene) {
  final node = rt.findById(scene, 'i1');
  return (node as rt.IconNode).data.iconRef;
}

rt.Size2D? _imageSizeOf(rt.CanvasSceneDocument scene) {
  final node = rt.findById(scene, 'img1');
  return (node as rt.ImageNode).data.size;
}

EditorRuntime<rt.CanvasSceneDocument> _buildSceneRuntime(
  rt.CanvasSceneDocument initial, {
  EditorDocumentAdapter<rt.CanvasSceneDocument> adapter =
      const CanvasSceneDocumentAdapter(),
  Map<rt.CanvasFieldKey, FieldCodec> extraFieldCodecs =
      const <rt.CanvasFieldKey, FieldCodec>{},
}) {
  return EditorRuntime<rt.CanvasSceneDocument>(
    initial: initial,
    adapter: adapter,
    renderPipeline: rt.CanvasRenderPipeline(textMeasurer: _FakeTextMeasurer()),
    imageIntrinsics: null,
    extraFieldCodecs: extraFieldCodecs,
  );
}

final class _MetadataDocument {
  const _MetadataDocument({required this.base, required this.metadata});

  final rt.CanvasSceneDocument base;
  final String metadata;

  _MetadataDocument copyWith({rt.CanvasSceneDocument? base, String? metadata}) {
    return _MetadataDocument(
      base: base ?? this.base,
      metadata: metadata ?? this.metadata,
    );
  }
}

final class _MetadataDocumentAdapter
    extends EditorDocumentAdapter<_MetadataDocument> {
  const _MetadataDocumentAdapter();

  @override
  rt.CanvasSceneDocument getBase(_MetadataDocument document) {
    return document.base;
  }

  @override
  _MetadataDocument replaceBase(
    _MetadataDocument document,
    rt.CanvasSceneDocument base,
  ) {
    return document.copyWith(base: base);
  }

  @override
  rt.CanvasSceneDocument resolve(_MetadataDocument document, Object? context) {
    return document.base;
  }
}

EditorRuntime<_MetadataDocument> _buildMetadataRuntime(
  _MetadataDocument initial,
) {
  return EditorRuntime<_MetadataDocument>(
    initial: initial,
    adapter: const _MetadataDocumentAdapter(),
    renderPipeline: rt.CanvasRenderPipeline(textMeasurer: _FakeTextMeasurer()),
    imageIntrinsics: null,
  );
}

final class _ResolvedTextAdapter
    extends EditorDocumentAdapter<rt.CanvasSceneDocument> {
  const _ResolvedTextAdapter();

  @override
  rt.CanvasSceneDocument getBase(rt.CanvasSceneDocument document) {
    return document;
  }

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
    final node = rt.findById(document, 't1');
    if (node is! rt.TextNode) return document;

    return rt.replaceById(
      document,
      't1',
      node.copyWith(data: node.data.copyWith(text: 'Resolved title')),
    );
  }
}

final class _OmitNodesFromRenderAdapter
    extends EditorDocumentAdapter<rt.CanvasSceneDocument> {
  const _OmitNodesFromRenderAdapter();

  @override
  rt.CanvasSceneDocument getBase(rt.CanvasSceneDocument document) {
    return document;
  }

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
    return document.copyWith(children: const <rt.Node>[]);
  }
}

final class _DerivedNodeAdapter
    extends EditorDocumentAdapter<rt.CanvasSceneDocument> {
  const _DerivedNodeAdapter();

  @override
  rt.CanvasSceneDocument getBase(rt.CanvasSceneDocument document) {
    return document;
  }

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
    return document.copyWith(
      children: <rt.Node>[
        rt.Node.text(
          id: 'derived',
          data: _baseTextData.copyWith(text: 'Derived title'),
        ),
      ],
    );
  }
}

void main() {
  test(
    'source-only metadata update notifies source without publishing document',
    () async {
      final runtime = _buildMetadataRuntime(
        _MetadataDocument(
          base: _sceneWithText('Original title'),
          metadata: 'before',
        ),
      );
      addTearDown(runtime.dispose);

      var sourceNotifications = 0;
      var documentNotifications = 0;

      runtime.source.addListener(() {
        sourceNotifications += 1;
      });

      runtime.document.addListener(() {
        documentNotifications += 1;
      });

      runtime.updateSourceDocument(
        (document) => document.copyWith(metadata: 'after'),
      );

      expect(runtime.sourceDocument.metadata, 'after');
      expect(runtime.source.value.metadata, 'after');
      expect(sourceNotifications, 1);
      expect(documentNotifications, 0);
    },
  );

  test('value-equal scene edit is a complete no-op', () {
    final initialDocument = _MetadataDocument(
      base: _sceneWithText('Original title'),
      metadata: 'unchanged',
    );

    final runtime = _buildMetadataRuntime(initialDocument);
    addTearDown(runtime.dispose);

    final initialRender = runtime.render.value;

    var sourceNotifications = 0;
    var documentNotifications = 0;
    var renderNotifications = 0;

    runtime.source.addListener(() {
      sourceNotifications += 1;
    });

    runtime.document.addListener(() {
      documentNotifications += 1;
    });

    runtime.render.addListener(() {
      renderNotifications += 1;
    });

    runtime.applyEdit((scene) => EditorEditResult(scene: scene.copyWith()));

    expect(runtime.sourceDocument, same(initialDocument));
    expect(runtime.source.value, same(initialDocument));
    expect(runtime.render.value, same(initialRender));

    expect(sourceNotifications, 0);
    expect(documentNotifications, 0);
    expect(renderNotifications, 0);

    expect(runtime.canUndo.value, isFalse);
  });

  test('unchanged field commit does not publish render', () {
    final runtime = _buildSceneRuntime(_sceneWithText('Original title'));
    addTearDown(runtime.dispose);

    final initialRender = runtime.render.value;
    var renderNotifications = 0;

    runtime.render.addListener(() {
      renderNotifications += 1;
    });

    runtime.commitField<String>(
      't1',
      rt.CanvasFields.textContent,
      'Original title',
    );

    expect(runtime.render.value, same(initialRender));
    expect(renderNotifications, 0);
    expect(runtime.canUndo.value, isFalse);
  });

  testWidgets(
    'ephemeral gesture updates publish source only after scheduled snapshot',
    (tester) async {
      final runtime = _buildSceneRuntime(_sceneWithText('Original title'));
      addTearDown(runtime.dispose);

      final initialSource = runtime.sourceDocument;
      final initialRender = runtime.render.value;
      var sourceNotifications = 0;

      runtime.source.addListener(() {
        sourceNotifications += 1;
      });

      final endSession = runtime.beginEditSession();

      runtime.updateDragMany({'t1'}, const rt.Vec2(10, 0));

      expect(runtime.sourceDocument, same(initialSource));
      expect(runtime.source.value, same(initialSource));
      expect(sourceNotifications, 0);
      expect(runtime.render.value, same(initialRender));

      await tester.pump();

      final movedNode =
          rt.findById(runtime.sourceDocument, 't1') as rt.TextNode;

      expect(movedNode.xf.position, const rt.Vec2(30, 20));
      expect(sourceNotifications, 1);
      expect(identical(runtime.render.value, initialRender), isFalse);

      endSession();

      expect(runtime.canUndo.value, isTrue);

      runtime.undo();
      await tester.pump();

      final restoredNode =
          rt.findById(runtime.sourceDocument, 't1') as rt.TextNode;

      expect(restoredNode.xf.position, const rt.Vec2(20, 20));
      expect(runtime.canRedo.value, isTrue);
    },
  );

  testWidgets('zero drag does not schedule publication', (tester) async {
    final runtime = _buildSceneRuntime(_sceneWithText('Original title'));
    addTearDown(runtime.dispose);

    final initialRender = runtime.render.value;

    var renderNotifications = 0;
    var sourceNotifications = 0;
    var documentNotifications = 0;

    runtime.render.addListener(() {
      renderNotifications += 1;
    });

    runtime.source.addListener(() {
      sourceNotifications += 1;
    });

    runtime.document.addListener(() {
      documentNotifications += 1;
    });

    final endSession = runtime.beginEditSession();

    runtime.updateDragMany({'t1'}, rt.Vec2.zero);
    await tester.pump();

    endSession();

    expect(runtime.render.value, same(initialRender));
    expect(renderNotifications, 0);
    expect(sourceNotifications, 0);
    expect(documentNotifications, 0);
    expect(runtime.canUndo.value, isFalse);
  });

  test('dispose closes an owned edit session and is idempotent', () {
    final runtime = _buildSceneRuntime(_sceneWithText('Original title'));

    var observedCanUndo = false;

    runtime.canUndo.addListener(() {
      observedCanUndo = runtime.canUndo.value;
    });

    final endSession = runtime.beginEditSession();

    runtime.commitField<String>(
      't1',
      rt.CanvasFields.textContent,
      'Updated title',
    );

    expect(_textOf(runtime.sourceDocument), 'Updated title');
    expect(runtime.canUndo.value, isFalse);

    runtime.dispose();

    expect(
      observedCanUndo,
      isTrue,
      reason: 'Disposal should close and commit the owned transaction.',
    );

    expect(endSession, returnsNormally);
    expect(() => runtime.dispose(), returnsNormally);
  });

  test('edit session coalesces changes into one undo entry', () {
    final runtime = _buildSceneRuntime(_sceneWithText('Original title'));
    addTearDown(runtime.dispose);

    final endSession = runtime.beginEditSession();
    final repeatedEndSession = runtime.beginEditSession();

    expect(repeatedEndSession, same(endSession));

    runtime.commitField<String>(
      't1',
      rt.CanvasFields.textContent,
      'First value',
    );

    runtime.commitField<String>(
      't1',
      rt.CanvasFields.textContent,
      'Final value',
    );

    expect(
      runtime.canUndo.value,
      isFalse,
      reason: 'The active edit session should not publish history yet.',
    );

    expect(_textOf(runtime.sourceDocument), 'Final value');

    endSession();

    expect(runtime.canUndo.value, isTrue);
    expect(_textOf(runtime.sourceDocument), 'Final value');

    runtime.undo();

    expect(_textOf(runtime.sourceDocument), 'Original title');
    expect(runtime.canRedo.value, isTrue);
  });

  test('letter spacing edit session creates one undo entry', () {
    final runtime = _buildSceneRuntime(_sceneWithText('Original title'));
    addTearDown(runtime.dispose);

    final endSession = runtime.beginEditSession();

    runtime.commitField<double>('t1', rt.CanvasFields.textLetterSpacing, 0.25);

    runtime.commitField<double>('t1', rt.CanvasFields.textLetterSpacing, 0.75);

    runtime.commitField<double>('t1', rt.CanvasFields.textLetterSpacing, 1.25);

    expect(_letterSpacingOf(runtime.sourceDocument), 1.25);

    expect(
      runtime.canUndo.value,
      isFalse,
      reason: 'The active slider transaction should not publish history yet.',
    );

    endSession();

    expect(runtime.canUndo.value, isTrue);
    expect(_letterSpacingOf(runtime.sourceDocument), 1.25);

    runtime.undo();

    expect(
      _letterSpacingOf(runtime.sourceDocument),
      0.0,
      reason: 'One undo should revert the complete slider transaction.',
    );
    expect(runtime.canUndo.value, isFalse);
    expect(runtime.canRedo.value, isTrue);

    runtime.redo();

    expect(_letterSpacingOf(runtime.sourceDocument), 1.25);
  });

  test('fractional letter spacing survives commit undo and redo', () {
    final runtime = _buildSceneRuntime(_sceneWithText('Original title'));
    addTearDown(runtime.dispose);

    expect(_letterSpacingOf(runtime.sourceDocument), 0.0);

    runtime.commitField<double>('t1', rt.CanvasFields.textLetterSpacing, 1.25);

    expect(_letterSpacingOf(runtime.sourceDocument), 1.25);
    expect(runtime.canUndo.value, isTrue);

    runtime.undo();

    expect(_letterSpacingOf(runtime.sourceDocument), 0.0);
    expect(runtime.canRedo.value, isTrue);

    runtime.redo();

    expect(_letterSpacingOf(runtime.sourceDocument), 1.25);
  });

  test('unchanged fractional letter spacing commit is a no-op', () {
    final initial = _sceneWithText('Original title');
    final textNode = rt.findById(initial, 't1') as rt.TextNode;

    final scene = rt.replaceById(
      initial,
      't1',
      textNode.copyWith(data: textNode.data.copyWith(letterSpacing: 1.25)),
    );

    final runtime = _buildSceneRuntime(scene);
    addTearDown(runtime.dispose);

    final initialRender = runtime.render.value;
    var renderNotifications = 0;

    runtime.render.addListener(() {
      renderNotifications += 1;
    });

    runtime.commitField<double>('t1', rt.CanvasFields.textLetterSpacing, 1.25);

    expect(_letterSpacingOf(runtime.sourceDocument), 1.25);
    expect(runtime.render.value, same(initialRender));
    expect(renderNotifications, 0);
    expect(runtime.canUndo.value, isFalse);
  });

  test('edit-session close callback is idempotent', () {
    final runtime = _buildSceneRuntime(_sceneWithText('Original title'));
    addTearDown(runtime.dispose);

    final endSession = runtime.beginEditSession();

    runtime.commitField<String>(
      't1',
      rt.CanvasFields.textContent,
      'Updated title',
    );

    expect(runtime.canUndo.value, isFalse);

    endSession();

    expect(runtime.canUndo.value, isTrue);
    expect(_textOf(runtime.sourceDocument), 'Updated title');

    expect(endSession, returnsNormally);
    expect(runtime.canUndo.value, isTrue);

    runtime.undo();

    expect(_textOf(runtime.sourceDocument), 'Original title');
    expect(runtime.canUndo.value, isFalse);
    expect(runtime.canRedo.value, isTrue);
  });

  test('stale close callback cannot close a newer edit session', () {
    final runtime = _buildSceneRuntime(_sceneWithText('Original title'));
    addTearDown(runtime.dispose);

    final closeFirst = runtime.beginEditSession();

    runtime.commitField<String>(
      't1',
      rt.CanvasFields.textContent,
      'First value',
    );

    expect(runtime.canUndo.value, isFalse);

    closeFirst();

    expect(runtime.canUndo.value, isTrue);
    expect(_textOf(runtime.sourceDocument), 'First value');

    final closeSecond = runtime.beginEditSession();

    runtime.commitField<String>(
      't1',
      rt.CanvasFields.textContent,
      'Second value',
    );

    // This callback belongs to the completed first session. It must not close
    // the newer session.
    closeFirst();

    runtime.commitField<String>(
      't1',
      rt.CanvasFields.textContent,
      'Final value',
    );

    expect(_textOf(runtime.sourceDocument), 'Final value');

    closeSecond();

    runtime.undo();

    expect(
      _textOf(runtime.sourceDocument),
      'First value',
      reason: 'Both newer edits must be coalesced into the second session.',
    );

    runtime.undo();

    expect(_textOf(runtime.sourceDocument), 'Original title');
    expect(runtime.canUndo.value, isFalse);
    expect(runtime.canRedo.value, isTrue);
  });

  test(
    'extra field codecs override built-in text codecs for read and commit',
    () {
      const originalText = 'Original title';
      const overrideReadValue = 'Custom codec read value';
      const commitValue = 'Custom codec commit value';

      var readCalls = 0;
      var commitCalls = 0;
      rt.ElementId? committedNodeId;
      Object? committedValue;

      final overrideCodec = FieldCodec(
        fallback: 'Custom codec fallback',
        readNode: (node) {
          readCalls += 1;
          expect(node, isA<rt.TextNode>());
          return overrideReadValue;
        },
        commit: (_, nodeId, value) {
          commitCalls += 1;
          committedNodeId = nodeId;
          committedValue = value;
        },
      );

      final runtime = _buildSceneRuntime(
        _sceneWithText(originalText),
        extraFieldCodecs: <rt.CanvasFieldKey, FieldCodec>{
          rt.CanvasFields.textContent: overrideCodec,
        },
      );
      addTearDown(runtime.dispose);

      final field = runtime.getField<String>('t1', rt.CanvasFields.textContent);

      expect(field.value, overrideReadValue);
      expect(field.disabledReason, isNull);
      expect(readCalls, 1);

      runtime.commitField<String>(
        't1',
        rt.CanvasFields.textContent,
        commitValue,
      );

      expect(commitCalls, 1);
      expect(committedNodeId, 't1');
      expect(committedValue, commitValue);

      expect(_textOf(runtime.sourceDocument), originalText);
    },
  );

  test(
    'fields read the resolved scene and commit the canonical base document',
    () async {
      final runtime = _buildSceneRuntime(
        _sceneWithText('Base title'),
        adapter: const _ResolvedTextAdapter(),
      );
      addTearDown(runtime.dispose);

      final field = runtime.getField<String>('t1', rt.CanvasFields.textContent);

      expect(field.value, 'Resolved title');
      expect(field.disabledReason, isNull);

      runtime.commitField<String>(
        't1',
        rt.CanvasFields.textContent,
        'Saved title',
      );

      expect(_textOf(runtime.sourceDocument), 'Saved title');

      runtime.commitField<String>(
        'missing',
        rt.CanvasFields.textContent,
        'Ignored',
      );

      expect(_textOf(runtime.sourceDocument), 'Saved title');
    },
  );

  test('icon reference is read, committed, undone, and redone as a field', () {
    final runtime = _buildSceneRuntime(_sceneWithIcon('heart'));
    addTearDown(runtime.dispose);

    final field = runtime.getField<String>('i1', rt.CanvasFields.iconRef);

    expect(field.value, 'heart');
    expect(field.disabledReason, isNull);

    runtime.commitField<String>('i1', rt.CanvasFields.iconRef, 'star');

    expect(_iconRefOf(runtime.sourceDocument), 'star');
    expect(runtime.canUndo.value, isTrue);

    runtime.undo();

    expect(_iconRefOf(runtime.sourceDocument), 'heart');
    expect(runtime.canRedo.value, isTrue);

    runtime.redo();

    expect(_iconRefOf(runtime.sourceDocument), 'star');
  });

  test('image dimension fields preserve the canonical opposite dimension', () {
    final runtime = _buildSceneRuntime(
      _sceneWithImage(size: const rt.Size2D(320, 180)),
    );
    addTearDown(runtime.dispose);

    runtime.commitField<double>('img1', rt.CanvasFields.imageWidthPx, 400);

    expect(_imageSizeOf(runtime.sourceDocument), const rt.Size2D(400, 180));

    runtime.commitField<double>('img1', rt.CanvasFields.imageHeightPx, 240);
    expect(_imageSizeOf(runtime.sourceDocument), const rt.Size2D(400, 240));

    runtime.undo();

    expect(_imageSizeOf(runtime.sourceDocument), const rt.Size2D(400, 180));

    runtime.undo();

    expect(_imageSizeOf(runtime.sourceDocument), const rt.Size2D(320, 180));
  });

  test(
    'unchanged effective image fallback does not materialize nullable size',
    () {
      final runtime = _buildSceneRuntime(_sceneWithImage());
      addTearDown(runtime.dispose);

      expect(_imageSizeOf(runtime.sourceDocument), isNull);
      expect(runtime.canUndo.value, isFalse);

      runtime.commitField<double>('img1', rt.CanvasFields.imageWidthPx, 200);

      expect(_imageSizeOf(runtime.sourceDocument), isNull);
      expect(runtime.canUndo.value, isFalse);
    },
  );

  test('field editability and commits use canonical nodes', () {
    final omittedRuntime = _buildSceneRuntime(
      _sceneWithText('Base title'),
      adapter: const _OmitNodesFromRenderAdapter(),
    );
    addTearDown(omittedRuntime.dispose);

    expect(rt.findById(omittedRuntime.render.value.scene, 't1'), isNull);

    omittedRuntime.commitField<String>(
      't1',
      rt.CanvasFields.textContent,
      'Saved while omitted',
    );

    expect(_textOf(omittedRuntime.sourceDocument), 'Saved while omitted');

    final derivedRuntime = _buildSceneRuntime(
      _emptyScene(),
      adapter: const _DerivedNodeAdapter(),
    );
    addTearDown(derivedRuntime.dispose);

    final derivedField = derivedRuntime.getField<String>(
      'derived',
      rt.CanvasFields.textContent,
    );

    expect(derivedField.value, 'Derived title');
    expect(derivedField.disabledReason, 'Missing canonical node');

    derivedRuntime.commitField<String>(
      'derived',
      rt.CanvasFields.textContent,
      'Cannot persist this',
    );

    expect(derivedRuntime.sourceDocument.children, isEmpty);
    expect(derivedRuntime.canUndo.value, isFalse);
  });
}
