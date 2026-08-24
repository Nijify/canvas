// Path: test/scene_json_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

CanvasSceneDocument _scene({double backgroundOpacity = 0.5}) {
  return CanvasSceneDocument(
    artboardSize: const Size2D(640, 480),
    backgroundFill: const CanvasFill.gradient(
      LinearGradientSpec(
        color1: 0xFF112233,
        color2: 0x80445566,
        angle: 45,
        width: 20,
      ),
    ),
    backgroundOpacity: backgroundOpacity,
    children: const <Node>[
      Node.text(
        id: 'headline',
        xf: Transform2D(position: Vec2(32, 48)),
        data: TextData(
          text: 'Scene JSON',
          fontFamily: 'Inter',
          fontWeight: 700,
          fontSize: 32,
        ),
      ),
    ],
  );
}

void main() {
  group('scene JSON boundary', () {
    test('preserves the generated scene wire format', () {
      final scene = _scene();

      final json = encodeCanvasScene(scene);

      expect(json, equals(scene.toJson()));
      expect(
        json['backgroundFill'],
        equals({
          'type': 'gradient',
          'grad': {
            'color1': 0xFF112233,
            'color2': 0x80445566,
            'angle': 45.0,
            'width': 20.0,
          },
        }),
      );
      expect(json['backgroundOpacity'], 0.5);
      expect(json.containsKey('bgGradient'), isFalse);
      expect(json.containsKey('bgOpacity'), isFalse);
    });

    test('preserves generated scene decoding', () {
      final json = encodeCanvasScene(_scene());

      final decoded = decodeCanvasScene(json);
      final generated = CanvasSceneDocument.fromJson(
        Map<String, dynamic>.from(json),
      );

      expect(decoded, generated);
    });

    test('round-trips a scene', () {
      final scene = _scene();
      final restored = decodeCanvasScene(encodeCanvasScene(scene));

      expect(restored, scene);
      expect(
        restored.copyWith(
          backgroundFill: const CanvasFill.none(),
          backgroundOpacity: 0.8,
        ),
        isNot(scene),
      );
    });

    test('rejects missing required background fields', () {
      final base = encodeCanvasScene(_scene());
      final missingFill = Map<String, Object?>.from(base)
        ..remove('backgroundFill');
      final missingOpacity = Map<String, Object?>.from(base)
        ..remove('backgroundOpacity');

      expect(() => decodeCanvasScene(missingFill), throwsA(anything));
      expect(() => decodeCanvasScene(missingOpacity), throwsA(anything));
    });

    test('rejects a legacy-only background payload', () {
      final legacy = <String, Object?>{
        'artboardSize': {'w': 740.0, 'h': 360.0},
        'bgGradient': {
          'color1': 0,
          'color2': 0,
          'angle': 0.0,
          'width': 0.0,
        },
        'bgOpacity': 0.0,
        'children': <Object?>[],
      };

      expect(() => decodeCanvasScene(legacy), throwsA(anything));
    });

    test('keeps decoding separate from semantic validation', () {
      final json = encodeCanvasScene(_scene(backgroundOpacity: 2));

      final scene = decodeCanvasScene(json);
      final issues = validateCanvasSceneDocument(scene);

      expect(scene.backgroundOpacity, 2);
      expect(
        issues.map((issue) => issue.code),
        contains(CanvasSceneValidationCode.valueOutOfRange),
      );
    });
  });
}
