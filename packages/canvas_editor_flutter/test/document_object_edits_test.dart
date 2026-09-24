// Path: packages/canvas_editor_flutter/test/document_object_edits_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/runtime/editor_runtime.dart';
import 'package:canvas_editor_flutter/src/editor_api.dart'
    show CanvasSceneDocumentAdapter, EditorDocumentAdapter;
import 'package:canvas_editor_flutter/src/editor_edits.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTextMeasurer implements TextMeasurer {
  @override
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required double letterSpacing,
  }) {
    return Size2D(text.length * fontSize * 0.6, fontSize);
  }
}

const _textData = TextData(
  text: 'Hello',
  fontFamily: 'Inter',
  fontWeight: 700,
  fontSize: 24,
  letterSpacing: 0,
  appearance: CanvasAppearance(foreground: CanvasFill.solid(0xFF111111)),
);

CanvasSceneDocument _sceneWithChildren(List<Node> children) {
  return CanvasSceneDocument(
    artboardSize: const Size2D(300, 200),
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1.0,
    children: children,
  );
}

EditorRuntime<CanvasSceneDocument> _buildRuntime(
  CanvasSceneDocument initialScene,
) {
  final renderPipeline = CanvasRenderPipeline(
    textMeasurer: _FakeTextMeasurer(),
  );

  return EditorRuntime<CanvasSceneDocument>(
    initial: initialScene,
    adapter: const CanvasSceneDocumentAdapter(),
    renderPipeline: renderPipeline,
  );
}

final class _MetadataSceneDocument {
  const _MetadataSceneDocument({required this.base, required this.metadata});

  final CanvasSceneDocument base;
  final Map<ElementId, String> metadata;

  _MetadataSceneDocument copyWith({
    CanvasSceneDocument? base,
    Map<ElementId, String>? metadata,
  }) {
    return _MetadataSceneDocument(
      base: base ?? this.base,
      metadata: metadata ?? this.metadata,
    );
  }
}

final class _MetadataSceneDocumentAdapter
    extends EditorDocumentAdapter<_MetadataSceneDocument> {
  const _MetadataSceneDocumentAdapter();

  @override
  CanvasSceneDocument getBase(_MetadataSceneDocument document) {
    return document.base;
  }

  @override
  _MetadataSceneDocument replaceBase(
    _MetadataSceneDocument document,
    CanvasSceneDocument base,
  ) {
    return document.copyWith(base: base);
  }

  @override
  CanvasSceneDocument resolve(
    _MetadataSceneDocument document,
    Object? context,
  ) {
    return document.base;
  }

  @override
  _MetadataSceneDocument onDuplicateSubtree(
    _MetadataSceneDocument document,
    Map<ElementId, ElementId> idMap,
  ) {
    final metadata = Map<ElementId, String>.of(document.metadata);

    for (final entry in idMap.entries) {
      final value = document.metadata[entry.key];

      if (value != null) {
        metadata[entry.value] = value;
      }
    }

    return document.copyWith(
      metadata: Map<ElementId, String>.unmodifiable(metadata),
    );
  }
}

EditorRuntime<_MetadataSceneDocument> _buildMetadataRuntime(
  _MetadataSceneDocument initial,
) {
  return EditorRuntime<_MetadataSceneDocument>(
    initial: initial,
    adapter: const _MetadataSceneDocumentAdapter(),
    renderPipeline: CanvasRenderPipeline(textMeasurer: _FakeTextMeasurer()),
  );
}

Node _onlyNode(EditorRuntime<CanvasSceneDocument> runtime) {
  return runtime.sourceDocument.children.single;
}

void main() {
  group('EditorRuntime object edits', () {
    test('document listenable exposes canonical base scene', () {
      final runtime = _buildRuntime(
        _sceneWithChildren(const [Node.text(id: 't1', data: _textData)]),
      );
      addTearDown(runtime.dispose);

      expect(runtime.document.value.children.single.id, 't1');
    });

    test('rename edit updates node name and is undoable/redoable', () {
      final runtime = _buildRuntime(
        _sceneWithChildren(const [Node.text(id: 't1', data: _textData)]),
      );
      addTearDown(runtime.dispose);

      runtime.applyEdit(EditorEdits.renameElement('t1', 'Hero Title'));

      expect(_onlyNode(runtime).name, 'Hero Title');
      expect(runtime.document.value.children.single.name, 'Hero Title');

      runtime.undo();
      expect(_onlyNode(runtime).name, isNull);

      runtime.redo();
      expect(_onlyNode(runtime).name, 'Hero Title');
    });

    test('rename edit normalizes empty value to null', () {
      final runtime = _buildRuntime(
        _sceneWithChildren(const [
          Node.text(id: 't1', name: 'Existing', data: _textData),
        ]),
      );
      addTearDown(runtime.dispose);

      runtime.applyEdit(EditorEdits.renameElement('t1', '   '));

      expect(_onlyNode(runtime).name, isNull);
    });

    test('duplicate edit preserves node name on copy', () {
      final runtime = _buildRuntime(
        _sceneWithChildren(const [
          Node.text(id: 't1', name: 'Hero Title', data: _textData),
        ]),
      );
      addTearDown(runtime.dispose);

      final createdId = runtime.applyEdit(EditorEdits.duplicateSubtree('t1'));

      expect(createdId, isNotNull);

      final copied = runtime.sourceDocument.children.singleWhere(
        (node) => node.id == createdId,
      );

      expect(copied.name, 'Hero Title');
    });

    test('applyEdit addNode updates document and is undoable/redoable', () {
      final runtime = _buildRuntime(_sceneWithChildren(const <Node>[]));
      addTearDown(runtime.dispose);

      final node = Node.text(id: 't1', data: _textData);
      final primaryId = runtime.applyEdit(EditorEdits.addNode(node));

      expect(primaryId, 't1');
      expect(runtime.sourceDocument.children.single.id, 't1');
      expect(runtime.document.value.children.single.id, 't1');

      runtime.undo();
      expect(runtime.sourceDocument.children, isEmpty);

      runtime.redo();
      expect(runtime.sourceDocument.children.single.id, 't1');
    });

    test(
      'applyEdit deleteSubtree updates document and is undoable/redoable',
      () {
        final runtime = _buildRuntime(
          _sceneWithChildren(const [Node.text(id: 't1', data: _textData)]),
        );
        addTearDown(runtime.dispose);

        runtime.applyEdit(EditorEdits.deleteSubtree('t1'));

        expect(runtime.sourceDocument.children, isEmpty);

        runtime.undo();
        expect(runtime.sourceDocument.children.single.id, 't1');

        runtime.redo();
        expect(runtime.sourceDocument.children, isEmpty);
      },
    );

    test('applyEdit duplicateSubtree returns primaryId and is undoable', () {
      final runtime = _buildRuntime(
        _sceneWithChildren(const [
          Node.text(id: 't1', name: 'Hero Title', data: _textData),
        ]),
      );
      addTearDown(runtime.dispose);

      final primaryId = runtime.applyEdit(EditorEdits.duplicateSubtree('t1'));

      expect(primaryId, isNotNull);
      expect(runtime.sourceDocument.children, hasLength(2));

      final copied = runtime.sourceDocument.children.singleWhere(
        (node) => node.id == primaryId,
      );

      expect(copied.name, 'Hero Title');

      runtime.undo();
      expect(runtime.sourceDocument.children, hasLength(1));
      expect(runtime.sourceDocument.children.single.id, 't1');
    });

    test('duplicate undo redo preserves IDs and adapter remapping', () {
      final initial = _MetadataSceneDocument(
        base: _sceneWithChildren(const <Node>[
          Node.text(id: 't1', data: _textData),
        ]),
        metadata: const <ElementId, String>{'t1': 'metadata-for-t1'},
      );

      final runtime = _buildMetadataRuntime(initial);
      addTearDown(runtime.dispose);

      final primaryId = runtime.applyEdit(EditorEdits.duplicateSubtree('t1'));

      expect(primaryId, 't1_copy_1');

      expect(
        runtime.sourceDocument.base.children.map((node) => node.id),
        <String>['t1', 't1_copy_1'],
      );

      expect(runtime.sourceDocument.metadata, <ElementId, String>{
        't1': 'metadata-for-t1',
        't1_copy_1': 'metadata-for-t1',
      });

      runtime.undo();

      expect(
        runtime.sourceDocument.base.children.map((node) => node.id),
        <String>['t1'],
      );

      expect(runtime.sourceDocument.metadata, <ElementId, String>{
        't1': 'metadata-for-t1',
      });

      runtime.redo();

      expect(
        runtime.sourceDocument.base.children.map((node) => node.id),
        <String>['t1', 't1_copy_1'],
      );

      expect(runtime.sourceDocument.metadata, <ElementId, String>{
        't1': 'metadata-for-t1',
        't1_copy_1': 'metadata-for-t1',
      });
    });

    test('failed ID-guard edits do not publish or create undo history', () {
      final initial = _sceneWithChildren(const <Node>[
        Node.text(id: 't1', data: _textData),
      ]);

      final runtime = _buildRuntime(initial);
      addTearDown(runtime.dispose);

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

      expect(
        () => runtime.applyEdit(
          EditorEdits.addNode(const Node.text(id: 't1', data: _textData)),
        ),
        throwsArgumentError,
      );

      expect(runtime.sourceDocument, same(initial));
      expect(runtime.document.value, same(initial));
      expect(runtime.canUndo.value, false);

      expect(sourceNotifications, 0);
      expect(documentNotifications, 0);
      expect(renderNotifications, 0);

      expect(
        () => runtime.applyEdit(
          EditorEdits.replaceNode(
            't1',
            const Node.text(id: 'different', data: _textData),
          ),
        ),
        throwsArgumentError,
      );

      expect(runtime.sourceDocument, same(initial));
      expect(runtime.document.value, same(initial));
      expect(runtime.canUndo.value, false);

      expect(sourceNotifications, 0);
      expect(documentNotifications, 0);
      expect(renderNotifications, 0);
    });

    test('applyEdit arrange operations are undoable', () {
      final runtime = _buildRuntime(
        _sceneWithChildren(const [
          Node.text(id: 'a', data: _textData),
          Node.text(id: 'b', data: _textData),
        ]),
      );
      addTearDown(runtime.dispose);

      runtime.applyEdit(EditorEdits.bringToFront('a'));

      expect(runtime.sourceDocument.children.map((node) => node.id), [
        'b',
        'a',
      ]);

      runtime.undo();

      expect(runtime.sourceDocument.children.map((node) => node.id), [
        'a',
        'b',
      ]);
    });
  });
}
