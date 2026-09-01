import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

final class _RecordingImageAssetResolver implements CanvasImageAssetResolver {
  final List<String> requestedIntrinsicRefs = <String>[];

  @override
  Future<Map<String, String>> resolveSources(List<String> sourceRefs) async {
    return <String, String>{for (final ref in sourceRefs) ref: ref};
  }

  @override
  Future<Map<String, Size2D>> resolveIntrinsicSizes(
    List<String> sourceRefs,
  ) async {
    requestedIntrinsicRefs.addAll(sourceRefs);

    return <String, Size2D>{
      for (final ref in sourceRefs) ref: const Size2D(640, 480),
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persisted intrinsic size is preferred over host metadata', () async {
    final resolver = _RecordingImageAssetResolver();

    final pool = FlutterImagePool(resolver: resolver);

    const scene = CanvasSceneDocument(
      artboardSize: Size2D(300, 200),
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

    await pool.resolveSceneIntrinsics(scene);

    expect(resolver.requestedIntrinsicRefs, isEmpty);

    expect(pool.intrinsicSize('image-1'), const Size2D(1600, 900));

    pool.dispose();
  });
}
