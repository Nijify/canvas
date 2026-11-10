import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_scene_upgrade/canvas_scene_upgrade.dart';
import 'package:test/test.dart';

Map<String, Object?> _fixture(String name) {
  final runtime = Isolate.resolvePackageUriSync(
    Uri.parse('package:canvas_scene_upgrade/canvas_scene_upgrade.dart'),
  )!;
  final root = File.fromUri(runtime).parent.parent;
  return jsonDecode(
    File.fromUri(root.uri.resolve('test/fixtures/$name')).readAsStringSync(),
  ) as Map<String, Object?>;
}

List<Map<String, Object?>> _nested(Map<String, Object?> scene) {
  final group = (scene['children'] as List).single as Map<String, Object?>;
  return (group['children'] as List).cast<Map<String, Object?>>();
}

Map<String, Object?> _wire() => _fixture('v4_paths.json');

void main() {
  test('v5 flattens all node kinds and preserves placement and payloads', () {
    final input = _fixture('v5_paths.json');
    final inputGroup = (input['children'] as List).single as Map;
    final behavior = inputGroup['behavior'] as Map;
    (behavior['data'] as Map)['nested'] = {
      'runtimeType': 'extension-owned',
      'data': [1, 2],
    };
    final before = jsonEncode(input);
    final output = upgradeCanvasScene(input);
    final group = (output['children'] as List).single as Map;
    final children = _nested(output);
    expect(output['sceneFormatVersion'], 6);
    expect(group['type'], 'group');
    expect(group['xf'], inputGroup['xf']);
    expect(group['behavior'], behavior);
    expect(children.map((node) => node['type']).toSet(), {
      'path',
      'text',
      'icon',
      'image',
    });
    for (final node in children) {
      expect(node.keys, isNot(contains('runtimeType')));
      expect(node.keys, isNot(contains('data')));
    }
    expect(children.first['geometry'], isA<Map>());
    expect(children[4]['text'], 'Kept');
    expect(children[5]['iconRef'], 'test.symbol');
    expect(children[6]['assetId'], 'asset');
    expect(encodeCanvasScene(decodeCanvasScene(output)), output);
    ((group['behavior'] as Map)['data'] as Map).clear();
    expect(jsonEncode(input), before);
  });

  test('v5 rejects malformed affine coefficients and misplaced fields', () {
    final input = _fixture('v5_paths.json');
    final group = (input['children'] as List).single as Map;
    group['xf'] = [1, 0, 0, 1, 0, '0'];
    expect(() => upgradeCanvasScene(input), throwsFormatException);
    group.remove('xf');
    (_nested(input).first['data'] as Map)['id'] = 'shadowed';
    expect(() => upgradeCanvasScene(input), throwsFormatException);
  });

  test('v2 fixture migrates without mutation or shared containers', () {
    final v2 = _fixture('v2_paths.json');
    final before = jsonEncode(v2);
    final upgraded = upgradeCanvasScene(v2);
    expect(upgraded, upgradeCanvasScene(_fixture('v5_paths.json')));
    expect(jsonEncode(v2), before);
    final canonical = encodeCanvasScene(decodeCanvasScene(upgraded));
    expect(encodeCanvasScene(decodeCanvasScene(canonical)), canonical);

    final children = _nested(upgraded);
    final source = children[1]['geometry'] as Map<String, Object?>;
    source['points'] = 'changed';
    final asset = (upgraded['assets'] as Map)['asset'] as Map;
    asset['sourceRef'] = 'changed';
    expect(jsonEncode(v2), before);
  });

  test(
    'v2 rejects invalid inactive metadata and malformed selected geometry',
    () {
      final v2 = _fixture('v2_paths.json');
      final inactive = _nested(v2)[3]['data'] as Map<String, Object?>;
      inactive['dash'] = [5, -1];
      expect(() => upgradeCanvasScene(v2), throwsArgumentError);
      inactive['dash'] = [];
      inactive['miterLimit'] = double.infinity;
      expect(() => upgradeCanvasScene(v2), throwsArgumentError);
      inactive.remove('miterLimit');
      final selected = _nested(v2)[0]['data'] as Map<String, Object?>;
      selected['source'] = {'kind': 'unknown'};
      expect(() => upgradeCanvasScene(v2), throwsFormatException);
    },
  );

  test(
    'historical versions require explicit upgrade and unknown versions fail',
    () {
      final old = _fixture('v2_paths.json');
      expect(() => decodeCanvasScene(old), throwsFormatException);
      for (final version in <Object?>[null, 1.0, 3.0, 99]) {
        final json = _wire()..['sceneFormatVersion'] = version;
        expect(() => upgradeCanvasScene(json), throwsFormatException);
      }
    },
  );
}
