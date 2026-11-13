import 'dart:convert';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_scene_upgrade/canvas_scene_upgrade.dart';
import 'package:test/test.dart';

Map<String, Object?> _path(String id) => {
  'type': 'path',
  'id': id,
  'geometry': {'kind': 'rect', 'width': 20, 'height': 10},
  'appearance': {
    'foreground': {'type': 'solid', 'color': 0xff123456},
  },
};

Map<String, Object?> _scene(List<Map<String, Object?>> children) => {
  'sceneFormatVersion': 6,
  'artboardSize': {'w': 300, 'h': 200},
  'backgroundFill': {'type': 'none'},
  'backgroundOpacity': 1,
  'children': children,
};

void main() {
  test('resolves missing dimensions by source and prunes unused assets', () {
    final input =
        _scene([
            {
              'type': 'image',
              'id': 'image',
              'assetId': 'used',
              'size': {'w': 50, 'h': 50},
            },
          ])
          ..['assets'] = {
            'used': {'sourceRef': 'media:used'},
            'orphan': {'sourceRef': 'media:orphan'},
          };
    final before = jsonEncode(input);
    final calls = <String>[];
    expect(() => upgradeCanvasScene(input), throwsFormatException);
    final output = upgradeCanvasScene(
      input,
      resolveImageIntrinsicSize: (ref) {
        calls.add(ref);
        return const Size2D(800, 400);
      },
    );
    final scene = decodeCanvasScene(output);
    expect(calls, ['media:used']);
    expect(scene.assets.keys, ['used']);
    expect(scene.assets['used']!.intrinsicSize, const Size2D(800, 400));
    expect(jsonEncode(input), before);
    expect(
      () => upgradeCanvasScene(
        input,
        resolveImageIntrinsicSize: (_) => const Size2D(0, 10),
      ),
      throwsArgumentError,
    );
  });

  test('stored dimensions take precedence over an upgrade resolver', () {
    final input =
        _scene([
            {
              'type': 'image',
              'id': 'image',
              'assetId': 'photo',
              'size': {'w': 50, 'h': 50},
            },
          ])
          ..['assets'] = {
            'photo': {
              'sourceRef': 'media:photo',
              'intrinsicSize': {'w': 800, 'h': 400},
            },
          };
    final output = upgradeCanvasScene(
      input,
      resolveImageIntrinsicSize: (_) {
        fail('Stored dimensions should satisfy the upgrade.');
      },
    );
    expect(
      decodeCanvasScene(output).assets['photo']!.intrinsicSize,
      const Size2D(800, 400),
    );
  });

  test('projects visible ordinary layers without mutating the v6 input', () {
    final input = _scene([
      {
        'type': 'group',
        'id': 'omitted',
        'hidden': true,
        'children': [_path('child')],
      },
      {
        ..._path('kept'),
        'role': 'decoration',
        'xf': [1, .2, .3, -1, 12, 34],
      },
    ]);
    final before = jsonEncode(input);
    final output = upgradeCanvasScene(input);
    final restored = decodeCanvasScene(output);
    expect(restored.children.map((node) => node.id), ['kept']);
    expect(restored.children.single.xf.toJson(), [1, .2, .3, -1, 12, 34]);
    final node = (output['children'] as List).single as Map;
    expect(node.containsKey('role'), isFalse);
    expect(node.containsKey('hidden'), isFalse);
    (node['geometry'] as Map)['width'] = 99;
    expect(jsonEncode(input), before);
  });

  test('requires explicit host preparation for a behavior envelope', () {
    final input = _scene([
      {
        'type': 'group',
        'id': 'component',
        'behavior': {'type': 'host.component', 'version': 1, 'data': {}},
        'children': [_path('content')],
      },
    ]);
    final before = jsonEncode(input);
    expect(() => upgradeCanvasScene(input), throwsFormatException);
    expect(
      () => upgradeCanvasScene(input, prepareV6Scene: (scene) => scene),
      throwsFormatException,
    );
    final output = upgradeCanvasScene(
      input,
      prepareV6Scene: (scene) {
        final group = (scene['children'] as List).single as Map;
        group.remove('behavior');
        return scene;
      },
    );
    expect(decodeCanvasScene(output).children.single.id, 'component');
    expect(jsonEncode(input), before);
  });
}
