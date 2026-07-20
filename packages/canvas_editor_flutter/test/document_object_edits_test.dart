// Path: oss_packages/canvas_editor_flutter/test/document_object_edits_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/runtime/editor_runtime.dart';
import 'package:canvas_editor_flutter/src/editor_api.dart'
    show CanvasSceneDocumentAdapter;
import 'package:canvas_editor_flutter/src/editor_edits.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTextMeasurer implements TextMeasurer {
  @override
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required int letterSpacing,
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
  fill: CanvasFill.solid(0xFF111111),
  shadowOffset: 0,
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
    imageIntrinsics: null,
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

    test('hidden edit updates hidden and is undoable/redoable', () {
      final runtime = _buildRuntime(
        _sceneWithChildren(const [Node.text(id: 't1', data: _textData)]),
      );
      addTearDown(runtime.dispose);

      runtime.applyEdit(EditorEdits.setElementHidden('t1', true));

      expect(_onlyNode(runtime).hidden, true);

      runtime.undo();
      expect(_onlyNode(runtime).hidden, false);

      runtime.redo();
      expect(_onlyNode(runtime).hidden, true);
    });

    test('locked edit updates locked and is undoable/redoable', () {
      final runtime = _buildRuntime(
        _sceneWithChildren(const [Node.text(id: 't1', data: _textData)]),
      );
      addTearDown(runtime.dispose);

      runtime.applyEdit(EditorEdits.setElementLocked('t1', true));

      expect(_onlyNode(runtime).locked, true);

      runtime.undo();
      expect(_onlyNode(runtime).locked, false);

      runtime.redo();
      expect(_onlyNode(runtime).locked, true);
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
