import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter_example/unsplash/unsplash_attribution_session.dart';
import 'package:canvas_editor_flutter_example/unsplash/unsplash_photo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final photo = UnsplashPhoto(
    id: 'photo-1',
    label: 'Photo',
    width: 1200,
    height: 800,
    thumbnailUrl: Uri.parse('https://images.unsplash.com/thumb?ixid=thumb'),
    imageUrl: Uri.parse('https://images.unsplash.com/photo?ixid=image'),
    credit: UnsplashCredit(
      photographerName: 'Jane Doe',
      photographerUrl: Uri.parse('https://unsplash.com/@jane'),
    ),
    downloadLocation: Uri.parse(
      'https://api.unsplash.com/photos/photo-1/download?ixid=track',
    ),
  );

  test('uses image-node references instead of all registered assets', () {
    final session = UnsplashAttributionSession()..register(photo);
    final scene = CanvasSceneDocument(
      artboardSize: const Size2D(800, 600),
      backgroundFill: const CanvasFill.solid(0xFFFFFFFF),
      backgroundOpacity: 1,
      assets: <CanvasAssetId, CanvasImageAsset>{
        'used': CanvasImageAsset(sourceRef: photo.sourceRef),
        'orphan': CanvasImageAsset(sourceRef: photo.sourceRef),
      },
      children: const <Node>[
        ImageNode(
          id: 'image',
          data: ImageData(assetId: 'used', size: Size2D(200, 120)),
          xf: Transform2D(position: Vec2(100, 100)),
        ),
      ],
    );

    expect(session.visibleCreditsForScene(scene).keys, <String>[
      photo.sourceRef,
    ]);
  });

  test('deduplicates duplicate nodes that share the same source', () {
    final session = UnsplashAttributionSession()..register(photo);
    final scene = CanvasSceneDocument(
      artboardSize: const Size2D(800, 600),
      backgroundFill: const CanvasFill.solid(0xFFFFFFFF),
      backgroundOpacity: 1,
      assets: <CanvasAssetId, CanvasImageAsset>{
        'a': CanvasImageAsset(sourceRef: photo.sourceRef),
        'b': CanvasImageAsset(sourceRef: photo.sourceRef),
      },
      children: const <Node>[
        ImageNode(
          id: 'image-a',
          data: ImageData(assetId: 'a', size: Size2D(200, 120)),
          xf: Transform2D(position: Vec2(100, 100)),
        ),
        ImageNode(
          id: 'image-b',
          data: ImageData(assetId: 'b', size: Size2D(200, 120)),
          xf: Transform2D(position: Vec2(300, 100)),
        ),
      ],
    );

    expect(session.visibleCreditsForScene(scene), hasLength(1));
  });

  test('does not attribute hidden image subtrees', () {
    final session = UnsplashAttributionSession()..register(photo);
    final scene = CanvasSceneDocument(
      artboardSize: const Size2D(800, 600),
      backgroundFill: const CanvasFill.solid(0xFFFFFFFF),
      backgroundOpacity: 1,
      assets: <CanvasAssetId, CanvasImageAsset>{
        'image': CanvasImageAsset(sourceRef: photo.sourceRef),
      },
      children: const <Node>[
        ImageNode(
          id: 'hidden-image',
          hidden: true,
          data: ImageData(assetId: 'image', size: Size2D(200, 120)),
          xf: Transform2D(position: Vec2(100, 100)),
        ),
      ],
    );

    expect(session.visibleCreditsForScene(scene), isEmpty);
  });
}
