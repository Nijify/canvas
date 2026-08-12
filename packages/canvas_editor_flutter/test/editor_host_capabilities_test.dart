import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/canvas_editor_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakePngExportPort implements PngExportPort {
  @override
  Future<String> sharePng({
    required CanvasSceneDocument editableScene,
    required CanvasSceneDocument preparedScene,
    required EditorExportSpec spec,
    required String filename,
    String? text,
  }) async => 'shared';

  @override
  Future<String> savePng({
    required CanvasSceneDocument editableScene,
    required CanvasSceneDocument preparedScene,
    required EditorExportSpec spec,
    required String filename,
  }) async => 'saved';
}

final class _FakeJsonOutputPort extends JsonOutputPort {
  const _FakeJsonOutputPort();

  @override
  Future<String> copyJson({required String json}) async => 'copied';

  @override
  Future<String> saveJson({
    required String json,
    required String filename,
  }) async => 'saved';
}

void main() {
  group('PngExportCapability', () {
    test('enables share and save by default', () {
      final capability = PngExportCapability(port: _FakePngExportPort());

      expect(capability.canShare, isTrue);
      expect(capability.canSave, isTrue);
    });

    test('configures share and save independently', () {
      final capability = PngExportCapability(
        port: _FakePngExportPort(),
        canShare: false,
        canSave: true,
      );

      expect(capability.canShare, isFalse);
      expect(capability.canSave, isTrue);
    });
  });

  group('JsonExportCapability', () {
    test('enables copy and save with stable defaults', () {
      const capability = JsonExportCapability(output: _FakeJsonOutputPort());

      expect(capability.canCopy, isTrue);
      expect(capability.canSave, isTrue);
      expect(capability.defaultFilename, 'canvas_scene.json');
      expect(capability.pretty, isTrue);
    });

    test('configures actions and formatting independently', () {
      const capability = JsonExportCapability(
        output: _FakeJsonOutputPort(),
        canCopy: true,
        canSave: false,
        defaultFilename: 'scene.json',
        pretty: false,
      );

      expect(capability.canCopy, isTrue);
      expect(capability.canSave, isFalse);
      expect(capability.defaultFilename, 'scene.json');
      expect(capability.pretty, isFalse);
    });
  });
}
