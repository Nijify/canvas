// Path: test/canvas_field_key_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

void main() {
  group('CanvasFieldKey', () {
    test('compares by stable string value', () {
      expect(
        const CanvasFieldKey('text.content'),
        equals(const CanvasFieldKey('text.content')),
      );

      expect(
        const CanvasFieldKey('text.content'),
        isNot(equals(const CanvasFieldKey('image.source'))),
      );
    });

    test('built-in fields expose stable string values', () {
      expect(CanvasFields.textContent.toString(), 'text.content');
      expect(CanvasFields.iconRef.toString(), 'icon.ref');
    });
  });

  group('CanvasFieldKeyConverter', () {
    const converter = CanvasFieldKeyConverter();

    test('serializes to stable string value', () {
      expect(converter.toJson(CanvasFields.imageSource), 'image.source');
    });

    test('deserializes from stable string value', () {
      expect(
        converter.fromJson('scene.backgroundFill'),
        CanvasFields.sceneBackgroundFill,
      );
    });
  });
}
