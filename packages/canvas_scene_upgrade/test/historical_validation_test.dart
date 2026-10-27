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
        File.fromUri(
          root.uri.resolve('test/fixtures/$name'),
        ).readAsStringSync(),
      )
      as Map<String, Object?>;
}

List<Map<String, Object?>> _nested(Map<String, Object?> scene) {
  final group = (scene['children'] as List).single as Map<String, Object?>;
  return (group['children'] as List).cast<Map<String, Object?>>();
}

Map<String, Object?> _wire() => _fixture('v4_paths.json');

void main() {
  test('v2 fixture migrates without mutation or shared containers', () {
    final v2 = _fixture('v2_paths.json');
    final before = jsonEncode(v2);
    final upgraded = upgradeCanvasScene(v2);
    expect(upgraded, _fixture('v4_paths.json'));
    expect(jsonEncode(v2), before);
    final canonical = encodeCanvasScene(decodeCanvasScene(upgraded));
    expect(encodeCanvasScene(decodeCanvasScene(canonical)), canonical);

    final children = _nested(upgraded);
    final points = children[1]['data'] as Map<String, Object?>;
    final source = points['source'] as Map<String, Object?>;
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
