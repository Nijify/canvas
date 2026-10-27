import 'dart:math' as math;
import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';
void main() {
  test('composition applies right-hand mapping first', () {
    final matrix = Affine2D.translation(10, 20) * Affine2D.rotation(math.pi / 2) * Affine2D.scale(2, 3);
    final point = matrix.transformPoint(const Vec2(1, 2));
    expect(point.x, closeTo(4, 1e-12)); expect(point.y, closeTo(22, 1e-12));
  });
  test('inverse is scale-aware and supports shear/reflection', () {
    for (final matrix in [Affine2D.scale(1e-200), Affine2D.scale(1e200), Affine2D(2, .5, 1, -3, 4, 8)]) {
      final inverse = matrix.tryInverse(); expect(inverse, isNotNull);
      final roundtrip = inverse! * matrix;
      for (var i = 0; i < 6; i++) expect(roundtrip.toJson()[i], closeTo(const Affine2D.identity().toJson()[i], 1e-9));
    }
    expect(Affine2D.scale(0, 1).tryInverse(), isNull);
    expect(Affine2D.scale(1, 1e-15).tryInverse(), isNull);
  });
  test('invalid and overflowing derived values are rejected', () {
    expect(() => Affine2D(double.nan, 0, 0, 1, 0, 0), throwsArgumentError);
    expect(() => Affine2D.scale(1e308) * Affine2D.scale(2), throwsArgumentError);
    expect(() => Affine2D.scale(1e308).transformPoint(const Vec2(2, 1)), throwsArgumentError);
    for (final invalid in [null, {}, [1, 0, 0, 1, 0], [1, 0, 0, 1, 0, '0']]) {
      expect(() => Affine2D.fromJson(invalid), throwsFormatException);
    }
  });
  test('serialized and framework buffers cannot mutate a value', () {
    final matrix = Affine2D(1, 2, 3, 4, 5, 6);
    final json = matrix.toJson()..[0] = 9;
    final framework = matrix.toColumnMajor4x4()..[0] = 9;
    expect(json[0], 9); expect(framework[0], 9);
    expect(matrix.a, 1);
    expect(matrix.toColumnMajor4x4(), [1, 2, 0, 0, 3, 4, 0, 0, 0, 0, 1, 0, 5, 6, 0, 1]);
  });
  test('v5 omits identity and rejects historical transform objects', () {
    final scene = CanvasSceneDocument(children: [Node.group(id: 'g', children: [])]);
    final wire = encodeCanvasScene(scene);
    expect(wire['sceneFormatVersion'], 5);
    final group = (wire['children'] as List).single as Map;
    expect(group.containsKey('xf'), isFalse);
    group['xf'] = {'position': {'x': 1, 'y': 2}};
    expect(() => decodeCanvasScene(wire), throwsFormatException);
    group['xf'] = null;
    expect(() => decodeCanvasScene(wire), throwsFormatException);
    group['xf'] = [1, 0, .4, -1, 5, 6];
    expect(decodeCanvasScene(wire).children.single.xf, Affine2D(1, 0, .4, -1, 5, 6));
  });
}
