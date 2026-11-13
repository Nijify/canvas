import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

const _asset = CanvasImageAsset(
  sourceRef: 'media:shared',
  intrinsicSize: Size2D(800, 400),
);

CanvasSceneDocument _scene() => CanvasSceneDocument(
  artboardSize: const Size2D(300, 200),
  backgroundFill: const CanvasFill.none(),
  backgroundOpacity: 1,
  assets: const {'shared': _asset, 'unused': _asset},
  children: [
    Node.image(id: 'first', assetId: 'shared', size: const Size2D(100, 50)),
    Node.group(
      id: 'group',
      children: [
        Node.image(
          id: 'nested',
          assetId: 'shared',
          size: const Size2D(100, 50),
        ),
        Node.image(id: 'empty', size: const Size2D(100, 50)),
      ],
    ),
  ],
);

void main() {
  test(
    'prunes by asset ID across nested shared references without mutation',
    () {
      final original = _scene();
      final pruned = pruneUnusedImageAssets(original);
      expect(pruned.assets, {'shared': _asset});
      expect(original.assets.keys, ['shared', 'unused']);
      expect(pruned.children, original.children);
      expect(identical(pruned.children.first, original.children.first), isTrue);
      expect(identical(pruneUnusedImageAssets(pruned), pruned), isTrue);

      final empty = pruneUnusedImageAssets(original.copyWith(children: []));
      expect(empty.assets, isEmpty);
      expect(encodeCanvasScene(empty).containsKey('assets'), isFalse);
    },
  );

  test('loading and saving normalize assets without mutating their input', () {
    final original = _scene();
    final saved = encodeCanvasScene(original);
    expect((saved['assets'] as Map).keys, ['shared']);
    expect(original.assets.keys, ['shared', 'unused']);

    final wire = original.toJson()..['sceneFormatVersion'] = 7;
    final loaded = decodeCanvasScene(wire);
    expect(loaded.assets.keys, ['shared']);
    expect((wire['assets'] as Map).keys, ['shared', 'unused']);
    expect(encodeCanvasScene(loaded), saved);
  });

  test('pruning rejects dangling references and cyclic graphs', () {
    final dangling = _scene().copyWith(assets: {});
    expect(() => pruneUnusedImageAssets(dangling), throwsArgumentError);

    final children = <Node>[];
    final group = Node.group(id: 'cycle', children: children);
    children.add(group);
    final cyclic = _scene().copyWith(children: [group]);
    expect(() => pruneUnusedImageAssets(cyclic), throwsArgumentError);
  });
}
