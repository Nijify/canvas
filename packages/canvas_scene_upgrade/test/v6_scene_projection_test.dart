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
