// Path: oss_packages/canvas_editor_flutter/test/editor_runtime_test.dart

import 'dart:async';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/runtime/editor_runtime.dart';
import 'package:canvas_editor_flutter/src/editor_api.dart';
import 'package:canvas_editor_flutter/src/editor_edits.dart';
import 'package:flutter_test/flutter_test.dart';

// Tiny fake measurer so layout/ops can be computed deterministically.
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

CanvasSceneDocument _sceneWithChildren(List<Node> children) {
  return CanvasSceneDocument(
    artboardSize: const Size2D(300, 200),
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1.0,
    children: children,
  );
}

List<String> _rootIds(CanvasSceneDocument scene) {
  return [for (final n in scene.children) n.id];
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

Future<RenderSnapshot> _waitForRenderPublication(
  EditorRuntime<CanvasSceneDocument> runtime,
  RenderSnapshot previous,
) async {
  final current = runtime.render.value;

  if (!identical(current, previous)) {
    return current;
  }

  final completer = Completer<RenderSnapshot>();

  void listener() {
    final next = runtime.render.value;

    if (!identical(next, previous)) {
      runtime.render.removeListener(listener);
      completer.complete(next);
    }
  }

  runtime.render.addListener(listener);
  return completer.future;
}

void main() {
  test('CanvasFieldKey uses value-based equality and hashing', () {
    const keyA = CanvasFieldKey('x');
    const keyB = CanvasFieldKey('x');

    expect(keyA, keyB);
    expect(keyA.hashCode, keyB.hashCode);

    final map = <CanvasFieldKey, int>{keyA: 1};
    expect(map[keyB], 1);
  });

  test(
    'add edit appends to frontmost position and recomputes scene flow',
    () async {
      final runtime = _buildRuntime(_sceneWithChildren(const []));
      final initialRender = runtime.render.value;

      const node = Node.text(
        id: 't1',
        xf: Transform2D(position: Vec2(10, 10)),
        data: TextData(
          text: 'Hello',
          fontFamily: 'Inter',
          fontWeight: 700,
          fontSize: 24,
          letterSpacing: 0,
          fill: CanvasFill.solid(0xFF111111),
          shadowOffset: 0,
        ),
      );

      final primaryId = runtime.applyEdit(EditorEdits.addNode(node));

      expect(primaryId, 't1');

      final scene = runtime.sourceDocument;
      final snapshot = await _waitForRenderPublication(runtime, initialRender);
      final ops = snapshot.ops;

      expect(_rootIds(scene), ['t1']);
      expect(scene.children.single, isA<TextNode>());
      expect(ops.isNotEmpty, true);
    },
  );

  test('duplicate edit returns createdId for reselection', () {
    final initialScene = _sceneWithChildren([
      const Node.text(
        id: 't1',
        xf: Transform2D(position: Vec2(10, 10)),
        data: TextData(
          text: 'Hello',
          fontFamily: 'Inter',
          fontWeight: 700,
          fontSize: 24,
          letterSpacing: 0,
          fill: CanvasFill.solid(0xFF111111),
          shadowOffset: 0,
        ),
      ),
    ]);

    final runtime = _buildRuntime(initialScene);

    final createdId = runtime.applyEdit(EditorEdits.duplicateSubtree('t1'));

    expect(createdId, isNotNull);
    expect(createdId, isNot('t1'));

    final newIds = {for (final e in runtime.sourceDocument.children) e.id};
    expect(newIds.contains(createdId), true);
  });

  test('duplicate edit inserts copy above original', () {
    final initialScene = _sceneWithChildren([
      const Node.text(
        id: 't1',
        xf: Transform2D(position: Vec2(10, 10)),
        data: TextData(
          text: 'Hello',
          fontFamily: 'Inter',
          fontWeight: 700,
          fontSize: 24,
          letterSpacing: 0,
          fill: CanvasFill.solid(0xFF111111),
          shadowOffset: 0,
        ),
      ),
      const Node.text(
        id: 't2',
        xf: Transform2D(position: Vec2(20, 20)),
        data: TextData(
          text: 'World',
          fontFamily: 'Inter',
          fontWeight: 700,
          fontSize: 24,
          letterSpacing: 0,
          fill: CanvasFill.solid(0xFF111111),
          shadowOffset: 0,
        ),
      ),
    ]);

    final runtime = _buildRuntime(initialScene);

    final createdId = runtime.applyEdit(EditorEdits.duplicateSubtree('t1'));

    expect(createdId, isNotNull);
    expect(createdId, isNot('t1'));

    final copiedId = createdId!;
    expect(_rootIds(runtime.sourceDocument), ['t1', copiedId, 't2']);
  });

  test(
    'duplicate group edit returns createdId and inserts copy above original',
    () {
      const child1 = Node.text(
        id: 't1',
        xf: Transform2D(position: Vec2(0, 0)),
        data: TextData(
          text: 'One',
          fontFamily: 'Inter',
          fontWeight: 700,
          fontSize: 16,
          letterSpacing: 0,
          fill: CanvasFill.solid(0xFF000000),
          shadowOffset: 0,
        ),
      );

      const child2 = Node.text(
        id: 't2',
        xf: Transform2D(position: Vec2(10, 10)),
        data: TextData(
          text: 'Two',
          fontFamily: 'Inter',
          fontWeight: 700,
          fontSize: 16,
          letterSpacing: 0,
          fill: CanvasFill.solid(0xFF000000),
          shadowOffset: 0,
        ),
      );

      const group = Node.group(id: 'g1', children: [child1, child2]);

      final initialScene = _sceneWithChildren([group]);
      final runtime = _buildRuntime(initialScene);

      final primaryId = runtime.applyEdit(EditorEdits.duplicateSubtree('g1'));

      expect(primaryId, isNotNull);
      expect(primaryId, isNot('g1'));

      final copiedId = primaryId!;
      expect(_rootIds(runtime.sourceDocument), ['g1', copiedId]);
    },
  );

  test('stack-order edits delegate to SceneTreeOps helpers', () {
    final initialScene = _sceneWithChildren(const [
      Node.text(
        id: 't1',
        xf: Transform2D(position: Vec2(0, 0)),
        data: TextData(
          text: 'One',
          fontFamily: 'Inter',
          fontWeight: 700,
          fontSize: 16,
          letterSpacing: 0,
          fill: CanvasFill.solid(0xFF000000),
          shadowOffset: 0,
        ),
      ),
      Node.text(
        id: 't2',
        xf: Transform2D(position: Vec2(0, 0)),
        data: TextData(
          text: 'Two',
          fontFamily: 'Inter',
          fontWeight: 700,
          fontSize: 16,
          letterSpacing: 0,
          fill: CanvasFill.solid(0xFF000000),
          shadowOffset: 0,
        ),
      ),
    ]);

    final runtime = _buildRuntime(initialScene);

    runtime.applyEdit(EditorEdits.bringForward('t1'));

    var scene = runtime.sourceDocument;
    expect(_rootIds(scene), ['t2', 't1']);

    runtime.applyEdit(EditorEdits.sendToBack('t1'));

    scene = runtime.sourceDocument;
    expect(_rootIds(scene), ['t1', 't2']);
  });

  test('bringToFront and sendBackward edits update sibling order', () {
    final initialScene = _sceneWithChildren(const [
      Node.text(
        id: 't1',
        xf: Transform2D(position: Vec2(0, 0)),
        data: TextData(
          text: 'One',
          fontFamily: 'Inter',
          fontWeight: 700,
          fontSize: 16,
          letterSpacing: 0,
          fill: CanvasFill.solid(0xFF000000),
          shadowOffset: 0,
        ),
      ),
      Node.text(
        id: 't2',
        xf: Transform2D(position: Vec2(0, 0)),
        data: TextData(
          text: 'Two',
          fontFamily: 'Inter',
          fontWeight: 700,
          fontSize: 16,
          letterSpacing: 0,
          fill: CanvasFill.solid(0xFF000000),
          shadowOffset: 0,
        ),
      ),
      Node.text(
        id: 't3',
        xf: Transform2D(position: Vec2(0, 0)),
        data: TextData(
          text: 'Three',
          fontFamily: 'Inter',
          fontWeight: 700,
          fontSize: 16,
          letterSpacing: 0,
          fill: CanvasFill.solid(0xFF000000),
          shadowOffset: 0,
        ),
      ),
    ]);

    final runtime = _buildRuntime(initialScene);

    runtime.applyEdit(EditorEdits.bringToFront('t1'));

    var scene = runtime.sourceDocument;
    expect(_rootIds(scene), ['t2', 't3', 't1']);

    runtime.applyEdit(EditorEdits.sendBackward('t1'));

    scene = runtime.sourceDocument;
    expect(_rootIds(scene), ['t2', 't1', 't3']);
  });

  test('undo redo capability listenables track history state', () {
    final runtime = _buildRuntime(_sceneWithChildren(const []));

    expect(runtime.canUndo.value, false);
    expect(runtime.canRedo.value, false);

    runtime.applyEdit(
      EditorEdits.addNode(
        const Node.text(
          id: 't1',
          xf: Transform2D(position: Vec2(10, 10)),
          data: TextData(
            text: 'Hello',
            fontFamily: 'Inter',
            fontWeight: 700,
            fontSize: 24,
            letterSpacing: 0,
            fill: CanvasFill.solid(0xFF111111),
            shadowOffset: 0,
          ),
        ),
      ),
    );

    expect(runtime.canUndo.value, true);
    expect(runtime.canRedo.value, false);

    runtime.undo();

    expect(runtime.canUndo.value, false);
    expect(runtime.canRedo.value, true);

    runtime.redo();

    expect(runtime.canUndo.value, true);
    expect(runtime.canRedo.value, false);
  });
}
