import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

CanvasSceneDocument _scene({
  Map<CanvasAssetId, CanvasImageAsset> assets =
      const <CanvasAssetId, CanvasImageAsset>{},
  CanvasAssetId? assetId,
}) {
  return CanvasSceneDocument(
    artboardSize: const Size2D(300, 200),
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1,
    assets: assets,
    children: <Node>[
      Node.image(
        id: 'image-1',
        data: ImageData(assetId: assetId, size: const Size2D(100, 80)),
      ),
    ],
  );
}

void main() {
  group('image asset registry validation', () {
    test('accepts an intentionally unfilled image frame', () {
      expect(validateCanvasSceneDocument(_scene()), isEmpty);
    });

    test('rejects a dangling image asset reference', () {
      final issues = validateCanvasSceneDocument(_scene(assetId: 'missing'));

      expect(issues, hasLength(1));
      expect(issues.single.code, CanvasSceneValidationCode.missingImageAsset);
      expect(issues.single.path, '/children/0/data/assetId');
    });

    test('rejects a blank image asset source', () {
      final issues = validateCanvasSceneDocument(
        _scene(
          assets: const <CanvasAssetId, CanvasImageAsset>{
            'asset-1': CanvasImageAsset(sourceRef: '   '),
          },
          assetId: 'asset-1',
        ),
      );

      expect(issues, hasLength(1));
      expect(issues.single.code, CanvasSceneValidationCode.blankAssetSourceRef);
      expect(issues.single.path, '/assets/asset-1/sourceRef');
    });
  });
}
