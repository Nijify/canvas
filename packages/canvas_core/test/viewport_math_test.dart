import 'package:canvas_core/canvas_core_runtime.dart'
    show CanvasViewportTransform, Rect2D, computeViewport;
import 'package:test/test.dart';

void main() {
  group('computeViewport', () {
    test('centres a source rect with contain fitting', () {
      final t = computeViewport(
        sourceBounds: Rect2D.fromLTWH(0, 0, 100, 50),
        targetW: 200,
        targetH: 200,
      );

      expect(t.scale, 2);
      expect(t.translateX, 0);
      expect(t.translateY, 50);
    });

    test('accounts for off-origin source bounds', () {
      final t = computeViewport(
        sourceBounds: Rect2D.fromLTWH(10, 20, 100, 50),
        targetW: 200,
        targetH: 200,
      );

      expect(t.scale, 2);
      expect(t.translateX, -20);
      expect(t.translateY, 10);
    });

    test('minimum scale clamp recentres the source', () {
      final t = computeViewport(
        sourceBounds: Rect2D.fromLTWH(0, 0, 100, 100),
        targetW: 50,
        targetH: 50,
        minUniformScale: 1,
      );

      expect(t.scale, 1);
      expect(t.translateX, -25);
      expect(t.translateY, -25);
    });

    test('maximum scale clamp recentres the source', () {
      final t = computeViewport(
        sourceBounds: Rect2D.fromLTWH(0, 0, 100, 100),
        targetW: 1000,
        targetH: 1000,
        maxUniformScale: 2,
      );

      expect(t.scale, 2);
      expect(t.translateX, 400);
      expect(t.translateY, 400);
    });

    test('returns an identity transform for nonpositive source dimensions', () {
      final t = computeViewport(
        sourceBounds: Rect2D.fromLTWH(10, 20, 0, 50),
        targetW: 200,
        targetH: 100,
      );

      expect(t.scale, 1);
      expect(t.translateX, 0);
      expect(t.translateY, 0);
    });
  });

  test('snapTranslation rounds translation to the device-pixel grid', () {
    const t = CanvasViewportTransform(
      scale: 1.5,
      translateX: 0.26,
      translateY: 0.74,
    );

    final snapped = t.snapTranslation(2);

    expect(snapped.scale, 1.5);
    expect(snapped.translateX, 0.5);
    expect(snapped.translateY, 0.5);
  });
}
