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
      expect(() => requireCanvasSceneIntegrity(_scene()), returnsNormally);
    });

    test('rejects a dangling image asset reference', () {
      expect(
        () => requireCanvasSceneIntegrity(_scene(assetId: 'missing')),
        throwsArgumentError,
      );
    });

    test('rejects a blank image asset source', () {
      expect(() => requireCanvasSceneIntegrity(
        _scene(
          assets: const <CanvasAssetId, CanvasImageAsset>{
            'asset-1': CanvasImageAsset(sourceRef: '   '),
          },
          assetId: 'asset-1',
        ),
      ), throwsArgumentError);
    });

    test('checks asset IDs and intrinsic dimensions even when unreferenced', () {
      for (final assets in const <Map<CanvasAssetId, CanvasImageAsset>>[
        {' ': CanvasImageAsset(sourceRef: 'media:image')},
        {'asset': CanvasImageAsset(sourceRef: 'media:image', intrinsicSize: Size2D(0, 10))},
        {'asset': CanvasImageAsset(sourceRef: 'media:image', intrinsicSize: Size2D(10, double.infinity))},
      ]) {
        expect(
          () => requireCanvasSceneIntegrity(_scene(assets: assets)),
          throwsArgumentError,
        );
      }
    });
  });
}
