// Path: oss_packages/canvas_editor_flutter/test/scene_object_tree_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/presentation/layers/scene_object_tree.dart';
import 'package:flutter_test/flutter_test.dart';

const _textData = TextData(
  text: 'Hello world',
  fontFamily: 'Inter',
  fontWeight: 700,
  fontSize: 24,
  letterSpacing: 0,
  fill: CanvasFill.solid(0xFF111111),
  shadowOffset: 0,
);

const _imageData = ImageData(assetId: 'asset-1', size: Size2D(100, 100));

PathData _rectData() {
  return const PathData(
    points: <Vec2?>[],
    fill: CanvasFill.solid(0xFF111111),
    strokeColor: 0x00000000,
    strokeWidth: 0,
    source: RectSource(100, 60),
  );
}

Node _text(
  String id, {
  String text = 'Hello world',
  String? name,
  bool hidden = false,
  bool locked = false,
}) {
  return Node.text(
    id: id,
    name: name,
    hidden: hidden,
    locked: locked,
    data: _textData.copyWith(text: text),
  );
}

Node _image(String id, {String? name}) {
  return Node.image(id: id, name: name, data: _imageData);
}

Node _rect(String id, {String? name}) {
  return Node.path(id: id, name: name, data: _rectData());
}

Node _icon(String id, {String? name}) {
  return Node.icon(
    id: id,
    name: name,
    data: const CanvasIconData(
      iconRef: 'icon:test',
      sizePx: 32,
      fill: CanvasFill.solid(0xFF111111),
      shadowOffset: 0,
    ),
  );
}

CanvasSceneDocument _scene(List<Node> children) {
  return CanvasSceneDocument(
    artboardSize: const Size2D(300, 200),
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1.0,
    assets: const <CanvasAssetId, CanvasImageAsset>{
      'asset-1': CanvasImageAsset(sourceRef: 'media:1'),
    },
    children: children,
  );
}

List<String> _rowIds(List<SceneObjectRow> rows) {
  return [for (final row in rows) row.id];
}

class _SelectionMappingPolicy extends SceneObjectPresentationPolicy {
  const _SelectionMappingPolicy();

  @override
  String selectionIdForNode(CanvasSceneDocument scene, Node node) {
    if (node.id == 'leaf') {
      return 'root';
    }

    return node.id;
  }
}

class _LabelOverridePolicy extends SceneObjectPresentationPolicy {
  const _LabelOverridePolicy();

  @override
  String labelForNode(CanvasSceneDocument scene, Node node) {
    if (node.id == 'a') return 'Overridden';
    return super.labelForNode(scene, node);
  }
}

void main() {
  group('SceneObjectTreeBuilder', () {
    test('builds rows front-to-back from root children', () {
      final doc = _scene([_text('back'), _text('middle'), _text('front')]);

      final rows = const SceneObjectTreeBuilder().build(scene: doc);

      expect(_rowIds(rows), ['front', 'middle', 'back']);
      expect(rows.map((row) => row.depth), [0, 0, 0]);
    });

    test(
      'includes group children with increased depth in front-to-back order',
      () {
        final group = Node.group(
          id: 'group',
          children: [_text('child-back'), _text('child-front')],
        );

        final doc = _scene([_text('root-back'), group, _text('root-front')]);

        final rows = const SceneObjectTreeBuilder().build(scene: doc);

        expect(_rowIds(rows), [
          'root-front',
          'group',
          'child-front',
          'child-back',
          'root-back',
        ]);

        expect(rows.map((row) => row.depth), [0, 0, 1, 1, 0]);
      },
    );

    test('uses explicit node name as label', () {
      final doc = _scene([_text('a', name: 'Hero Title')]);

      final rows = const SceneObjectTreeBuilder().build(scene: doc);

      expect(rows.single.label, 'Hero Title');
    });

    test('falls back to useful generic labels', () {
      final doc = _scene([
        _text('text', text: 'Welcome to Canvas Editor'),
        _image('image'),
        _rect('rect'),
        _icon('icon'),
        Node.group(id: 'group', children: const <Node>[]),
      ]);

      final rows = const SceneObjectTreeBuilder().build(scene: doc);

      final labelsById = {for (final row in rows) row.id: row.label};

      expect(labelsById['text'], 'Welcome to Canvas Editor');
      expect(labelsById['image'], 'Image');
      expect(labelsById['rect'], 'Rectangle');
      expect(labelsById['icon'], 'Icon');
      expect(labelsById['group'], 'Group');
    });

    test('long text fallback is truncated', () {
      final doc = _scene([
        _text(
          'text',
          text: 'This is a very long text layer name that should be truncated',
        ),
      ]);

      final rows = const SceneObjectTreeBuilder().build(scene: doc);

      expect(rows.single.label, startsWith('This is a very long text layer'));
      expect(rows.single.label, endsWith('…'));
    });

    test('copies hidden and locked flags into rows', () {
      final doc = _scene([_text('a', hidden: true, locked: true)]);

      final rows = const SceneObjectTreeBuilder().build(scene: doc);
      final row = rows.single;

      expect(row.hidden, true);
      expect(row.locked, true);
    });

    test('policy can override labels', () {
      final doc = _scene([_text('a')]);

      final rows = const SceneObjectTreeBuilder(
        policy: _LabelOverridePolicy(),
      ).build(scene: doc);

      expect(rows.single.label, 'Overridden');
    });

    test('policy can remap selection id', () {
      final doc = _scene([
        Node.group(id: 'root', children: [_text('leaf')]),
      ]);

      final rows = const SceneObjectTreeBuilder(
        policy: _SelectionMappingPolicy(),
      ).build(scene: doc);

      final leafRow = rows.singleWhere((row) => row.id == 'leaf');

      expect(leafRow.selectionId, 'root');
    });

    test('kindForNode maps supported node variants', () {
      expect(kindForNode(_text('text')), SceneObjectKind.text);
      expect(kindForNode(_image('image')), SceneObjectKind.image);
      expect(kindForNode(_rect('rect')), SceneObjectKind.path);
      expect(kindForNode(_icon('icon')), SceneObjectKind.icon);
      expect(
        kindForNode(Node.group(id: 'group', children: const <Node>[])),
        SceneObjectKind.group,
      );
    });
  });
}
