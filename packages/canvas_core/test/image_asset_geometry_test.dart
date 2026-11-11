import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

final class _NoText implements TextMeasurer {
  const _NoText();
  @override
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required double letterSpacing,
  }) => throw StateError('No text in this scene');
}

CanvasSceneDocument _scene(ImageFit fit) => CanvasSceneDocument(
  artboardSize: const Size2D(300, 300),
  backgroundFill: const CanvasFill.none(),
  backgroundOpacity: 1,
  assets: const {
    'photo': CanvasImageAsset(
      sourceRef: 'media:photo',
      intrinsicSize: Size2D(1600, 900),
    ),
  },
  children: [
    Node.image(
      id: 'image',
      assetId: 'photo',
      size: const Size2D(300, 300),
      fit: fit,
    ),
  ],
);

void main() {
  test('stored dimensions determine fit without loading image resources', () {
    const services = CoreServices(textMeasurer: _NoText());
    final contain = computeScene(_scene(ImageFit.contain), services);
    final cover = computeScene(_scene(ImageFit.cover), services);
    final contained = contain.imagePlacementById['image']!;
    final covered = cover.imagePlacementById['image']!;
    expect(contained.src, const Rect2D(0, 0, 1600, 900));
    expect(contained.dst.width, 300);
    expect(contained.dst.height, 168.75);
    expect(covered.src, const Rect2D(350, 0, 1250, 900));
    expect(covered.dst, const Rect2D(-150, -150, 150, 150));
  });

  test('v7 rejects absent and null natural dimensions before decoding', () {
    for (final absent in [true, false]) {
      final wire = encodeCanvasScene(_scene(ImageFit.contain));
      final asset = (wire['assets'] as Map)['photo'] as Map;
      if (absent) {
        asset.remove('intrinsicSize');
      } else {
        asset['intrinsicSize'] = null;
      }
      expect(() => decodeCanvasScene(wire), throwsFormatException);
    }
  });
}
