// Path: oss_packages/canvas_core/test/selection_geometry_test.dart
import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

void main() {
  group('selectionUnionBounds', () {
    test('returns null for empty or missing bounds', () {
      final empty = selectionUnionBounds([], getBounds: (_) => null);
      expect(empty, isNull);

      final missing = selectionUnionBounds(['a'], getBounds: (_) => null);
      expect(missing, isNull);
    });

    test('builds union across available ids only', () {
      final bounds = selectionUnionBounds(
        ['a', 'b', 'c'],
        getBounds: (id) => switch (id) {
          'a' => Rect2D.fromLTWH(0, 0, 20, 10),
          'c' => Rect2D.fromLTWH(10, -10, 5, 15),
          _ => null,
        },
      );

      expect(bounds!.left, 0);
      expect(bounds.top, -10);
      expect(bounds.right, 20);
      expect(bounds.bottom, 10);
    });
  });

  group('selectionGeometry', () {
    test('returns null when no union exists', () {
      final geo = selectionGeometry([], getBounds: (_) => null);
      expect(geo, isNull);
    });

    test('parity with single selection bounds', () {
      final geo = selectionGeometry([
        'solo',
      ], getBounds: (_) => Rect2D.fromLTWH(5, 8, 10, 12));

      expect(geo, isNotNull);
      expect(geo!.bounds.left, 5);
      expect(geo.bounds.top, 8);
      expect(geo.bounds.right, 15);
      expect(geo.bounds.bottom, 20);
      expect(geo.corners, [
        const Vec2(5, 8),
        const Vec2(15, 8),
        const Vec2(15, 20),
        const Vec2(5, 20),
      ]);
      expect(geo.pivotWorld, const Vec2(10, 14));
    });

    test('handles multi-element unions with mixed transforms', () {
      // Engine-resolved bounds can already include rotation/scale; we only
      // care about their AABB union.
      final geo = selectionGeometry(
        ['rotated', 'scaled'],
        getBounds: (id) => switch (id) {
          'rotated' => Rect2D.fromLTRB(-5, 0, 15, 25),
          'scaled' => Rect2D.fromLTRB(8, -12, 30, 6),
          _ => null,
        },
      );

      expect(geo, isNotNull);
      expect(geo!.bounds.left, -5);
      expect(geo.bounds.top, -12);
      expect(geo.bounds.right, 30);
      expect(geo.bounds.bottom, 25);
      expect(geo.corners.first, const Vec2(-5, -12));
      expect(geo.corners[2], const Vec2(30, 25));
      expect(geo.pivotWorld, const Vec2(12.5, 6.5));
      expect(geo.handles.length, 8);
      expect(geo.handles[4], const Vec2(12.5, -12)); // top-mid
    });
  });
}
