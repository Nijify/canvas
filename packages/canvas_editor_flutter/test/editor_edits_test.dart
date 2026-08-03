// Path: oss_packages/canvas_editor_flutter/test/editor_edits_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/editor_edits.dart';
import 'package:flutter_test/flutter_test.dart';

const _textData = TextData(
  text: 'Hello',
  fontFamily: 'Inter',
  fontWeight: 700,
  fontSize: 24,
  letterSpacing: 0,
  fill: CanvasFill.solid(0xFF111111),
  shadowOffset: 0,
);

Node _text(
  String id, {
  String? name,
  bool hidden = false,
  bool locked = false,
}) {
  return Node.text(
    id: id,
    name: name,
    hidden: hidden,
    locked: locked,
    data: _textData,
  );
}

CanvasSceneDocument _scene(List<Node> children) {
  return CanvasSceneDocument(
    artboardSize: const Size2D(300, 200),
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1.0,
    children: children,
  );
}

void main() {
  test('renameElement updates node name and returns primaryId', () {
    final scene = _scene([_text('a', name: 'Old')]);

    final result = EditorEdits.renameElement('a', 'New')(scene);
    final node = findById(result.scene, 'a');

    expect(result.primaryId, 'a');
    expect(node?.name, 'New');
  });

  test('replaceNode replaces node and returns primaryId', () {
    final scene = _scene([_text('a', name: 'Old')]);

    final updated = _text('a', name: 'New');
    final result = EditorEdits.replaceNode('a', updated)(scene);
    final node = findById(result.scene, 'a');

    expect(result.primaryId, 'a');
    expect(node?.name, 'New');
  });

  test('setElementHidden updates hidden flag and returns primaryId', () {
    final scene = _scene([_text('a', hidden: false)]);

    final result = EditorEdits.setElementHidden('a', true)(scene);
    final node = findById(result.scene, 'a');

    expect(result.primaryId, 'a');
    expect(node?.hidden, true);
  });

  test('setElementLocked updates locked flag and returns primaryId', () {
    final scene = _scene([_text('a', locked: false)]);

    final result = EditorEdits.setElementLocked('a', true)(scene);
    final node = findById(result.scene, 'a');

    expect(result.primaryId, 'a');
    expect(node?.locked, true);
  });

  test('metadata edits are no-op for missing node', () {
    final scene = _scene([_text('a')]);

    final result = EditorEdits.renameElement('missing', 'Nope')(scene);

    expect(result.scene, scene);
    expect(result.primaryId, isNull);
  });
}
