import 'package:canvas_scene_upgrade/src/formats/scene_v2.dart';
import 'package:test/test.dart';

Map<String, Object?> _scene(Map<String, Object?> gradient) => {
  'sceneFormatVersion': 2,
  'backgroundFill': {'type': 'gradient', 'grad': gradient},
  'backgroundOpacity': 1,
  'children': [],
};

Map<String, Object?> _gradient() => {
  'start': {'x': 0, 'y': 0},
  'end': {'x': 100, 'y': 0},
  'stops': [
    {'offset': 0.5, 'color': 0xff112233},
    {'offset': 0.5, 'color': 0xff445566},
  ],
};

void main() {
  test('frozen v2 validation preserves duplicate gradient stops', () {
    final gradient = _gradient();
    validateSceneV2Json(_scene(gradient));
    expect((gradient['stops'] as List).length, 2);
  });

  test('frozen v2 validation rejects invalid gradient endpoints', () {
    for (final end in [
      {'x': 0, 'y': 0},
      {'x': double.infinity, 'y': 0},
      {'x': '100', 'y': 0},
      {'x': 100},
      {'x': 100, 'y': 0, 'extra': true},
    ]) {
      final gradient = _gradient()..['end'] = end;
      expect(
        () => validateSceneV2Json(_scene(gradient)),
        throwsFormatException,
      );
    }
  });

  test('frozen v2 validation rejects malformed or unusable stops', () {
    for (final stops in <Object?>[
      null,
      [],
      [
        {'offset': 0, 'color': 0xff112233},
      ],
      [
        {'offset': 0.75, 'color': 0xff112233},
        {'offset': 0.25, 'color': 0xff445566},
      ],
      [
        {'offset': -0.1, 'color': 0xff112233},
        {'offset': 1, 'color': 0xff445566},
      ],
      [
        {'offset': double.nan, 'color': 0xff112233},
        {'offset': 1, 'color': 0xff445566},
      ],
      [
        {'offset': 0, 'color': 1.5},
        {'offset': 1, 'color': 0xff445566},
      ],
      [
        {'offset': 0, 'color': -1},
        {'offset': 1, 'color': 0xff445566},
      ],
      [
        {'offset': 0, 'color': 0xff112233, 'extra': true},
        {'offset': 1, 'color': 0xff445566},
      ],
    ]) {
      final gradient = _gradient()..['stops'] = stops;
      expect(
        () => validateSceneV2Json(_scene(gradient)),
        throwsFormatException,
      );
    }
  });
}
