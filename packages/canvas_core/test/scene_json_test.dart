// Path: packages/canvas_core/test/scene_json_test.dart

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

CanvasSceneDocument _imageScene() {
  return const CanvasSceneDocument(
    artboardSize: Size2D(640, 480),
    backgroundFill: CanvasFill.none(),
    backgroundOpacity: 1,
    assets: <CanvasAssetId, CanvasImageAsset>{
      'asset-1': CanvasImageAsset(
        sourceRef: 'media:image-1',
        intrinsicSize: Size2D(1600, 900),
      ),
    },
    children: <Node>[
      Node.image(
        id: 'image-1',
        data: ImageData(assetId: 'asset-1', size: Size2D(320, 180)),
      ),
    ],
  );
}

void main() {
  group('scene JSON boundary', () {
    test('encodes the current persisted scene wire format', () {
      final scene = _scene();

      final json = encodeCanvasScene(scene);

      expect(json['sceneFormatVersion'], currentCanvasSceneFormatVersion);

      final generatedPayload = Map<String, Object?>.from(json)
        ..remove('sceneFormatVersion');

      expect(generatedPayload, equals(scene.toJson()));

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

    test('keeps sceneFormatVersion out of the runtime model', () {
      final scene = _scene();

      expect(scene.toJson().containsKey('sceneFormatVersion'), isFalse);

      final restored = decodeCanvasScene(encodeCanvasScene(scene));

      expect(restored, scene);
      expect(restored.toJson().containsKey('sceneFormatVersion'), isFalse);
    });

    test('uses the image asset registry wire shape', () {
      final json = encodeCanvasScene(_imageScene());
      final assets = json['assets'] as Map<String, dynamic>;
      final asset = assets['asset-1'] as Map<String, dynamic>;
      final children = json['children'] as List<dynamic>;
      final image = children.single as Map<String, dynamic>;
      final data = image['data'] as Map<String, dynamic>;

      expect(asset['sourceRef'], 'media:image-1');
      expect(asset['intrinsicSize'], <String, dynamic>{
        'w': 1600.0,
        'h': 900.0,
      });
      expect(data['assetId'], 'asset-1');
      expect(data['size'], <String, dynamic>{'w': 320.0, 'h': 180.0});
      expect(data.containsKey('sourcePath'), isFalse);

      expect(decodeCanvasScene(json), _imageScene());
    });

    test('requires image frame size when decoding', () {
      final json = encodeCanvasScene(_imageScene());
      final children = json['children'] as List<dynamic>;
      final image = children.single as Map<String, dynamic>;
      final data = image['data'] as Map<String, dynamic>;
      data.remove('size');

      expect(() => decodeCanvasScene(json), throwsA(anything));
    });

    test(
      'decodes the generated runtime payload after removing wire metadata',
      () {
        final json = encodeCanvasScene(_scene());

        final decoded = decodeCanvasScene(json);

        final payload = Map<String, dynamic>.from(json)
          ..remove('sceneFormatVersion');

        final generated = CanvasSceneDocument.fromJson(payload);

        expect(decoded, generated);
      },
    );

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

    test('rejects a missing sceneFormatVersion', () {
      final json = encodeCanvasScene(_scene())..remove('sceneFormatVersion');

      expect(() => decodeCanvasScene(json), throwsA(isA<FormatException>()));
    });

    test('rejects a non-integer sceneFormatVersion', () {
      final json = encodeCanvasScene(_scene())..['sceneFormatVersion'] = 1.0;

      expect(() => decodeCanvasScene(json), throwsA(isA<FormatException>()));
    });

    test('rejects an unknown sceneFormatVersion', () {
      final json = encodeCanvasScene(_scene())..['sceneFormatVersion'] = 999;

      expect(() => decodeCanvasScene(json), throwsA(isA<FormatException>()));
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

    test('rejects unversioned scenes instead of guessing their format', () {
      final unversioned = Map<String, Object?>.from(_scene().toJson());

      expect(
        () => decodeCanvasScene(unversioned),
        throwsA(isA<FormatException>()),
      );
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
