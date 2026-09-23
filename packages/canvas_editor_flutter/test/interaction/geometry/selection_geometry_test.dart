// Path: packages/canvas_editor_flutter/test/interaction/geometry/selection_geometry_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/interaction/geometry/selection_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

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

      expect(bounds, isNotNull);
      expect(bounds!.left, 0);
      expect(bounds.top, -10);
      expect(bounds.right, 20);
      expect(bounds.bottom, 10);
    });
  });

  group('selectionGeometry', () {
    test('returns null when no union exists', () {
      final geometry = selectionGeometry([], getBounds: (_) => null);

      expect(geometry, isNull);
    });

    test('parity with single selection bounds', () {
      final geometry = selectionGeometry([
        'solo',
      ], getBounds: (_) => Rect2D.fromLTWH(5, 8, 10, 12));

      expect(geometry, isNotNull);

      expect(geometry!.bounds.left, 5);
      expect(geometry.bounds.top, 8);
      expect(geometry.bounds.right, 15);
      expect(geometry.bounds.bottom, 20);

      expect(geometry.corners, [
        const Vec2(5, 8),
        const Vec2(15, 8),
        const Vec2(15, 20),
        const Vec2(5, 20),
      ]);

      expect(geometry.pivotWorld, const Vec2(10, 14));
    });

    test('handles multi-element unions with mixed transforms', () {
      final geometry = selectionGeometry(
        ['rotated', 'scaled'],
        getBounds: (id) => switch (id) {
          'rotated' => Rect2D.fromLTRB(-5, 0, 15, 25),
          'scaled' => Rect2D.fromLTRB(8, -12, 30, 6),
          _ => null,
        },
      );

      expect(geometry, isNotNull);

      expect(geometry!.bounds.left, -5);
      expect(geometry.bounds.top, -12);
      expect(geometry.bounds.right, 30);
      expect(geometry.bounds.bottom, 25);

      expect(geometry.corners.first, const Vec2(-5, -12));

      expect(geometry.corners[2], const Vec2(30, 25));

      expect(geometry.pivotWorld, const Vec2(12.5, 6.5));

      expect(geometry.handles.length, 8);

      expect(geometry.handles[4], const Vec2(12.5, -12));
    });
  });
}
