// Path: packages/canvas_editor_flutter/test/interaction/picking/path_hit_test_test.dart

import 'package:canvas_core/canvas_core_runtime.dart'
    show FillRule, PathCmd, PathIR, PathStyle, Vec2;
import 'package:canvas_editor_flutter/src/interaction/picking/path_hit_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pathContainsClosedArea', () {
    test('the supplied fill rule overrides compiled style metadata', () {
      final ir = PathIR([
        PathCmd.moveTo(const Vec2(-10, -10)),
        PathCmd.lineTo(const Vec2(10, -10)),
        PathCmd.lineTo(const Vec2(10, 10)),
        PathCmd.lineTo(const Vec2(-10, 10)),
        PathCmd.close(),
        PathCmd.moveTo(const Vec2(-4, -4)),
        PathCmd.lineTo(const Vec2(4, -4)),
        PathCmd.lineTo(const Vec2(4, 4)),
        PathCmd.lineTo(const Vec2(-4, 4)),
        PathCmd.close(),
      ], const PathStyle(fillRule: FillRule.nonZero));

      expect(
        pathContainsClosedArea(ir, Vec2.zero, fillRule: FillRule.evenOdd),
        isFalse,
      );
      expect(
        pathContainsClosedArea(ir, Vec2.zero, fillRule: FillRule.nonZero),
        isTrue,
      );
    });

    test('treats open triangle as implicitly closed for fill hit', () {
      final ir = PathIR([
        PathCmd.moveTo(const Vec2(0, 0)),
        PathCmd.lineTo(const Vec2(10, 0)),
        PathCmd.lineTo(const Vec2(0, 10)),
      ], const PathStyle(fill: 0xFFFFFFFF, fillRule: FillRule.nonZero));

      expect(
        pathContainsClosedArea(
          ir,
          const Vec2(2, 2),
          fillRule: FillRule.nonZero,
        ),
        isTrue,
      );
      expect(
        pathContainsClosedArea(
          ir,
          const Vec2(9, 9),
          fillRule: FillRule.nonZero,
        ),
        isFalse,
      );
    });

    test('respects even-odd holes for open contours', () {
      final ir = PathIR([
        // outer square (open)
        PathCmd.moveTo(const Vec2(-10, -10)),
        PathCmd.lineTo(const Vec2(10, -10)),
        PathCmd.lineTo(const Vec2(10, 10)),
        PathCmd.lineTo(const Vec2(-10, 10)),

        // inner square hole (open)
        PathCmd.moveTo(const Vec2(-4, -4)),
        PathCmd.lineTo(const Vec2(4, -4)),
        PathCmd.lineTo(const Vec2(4, 4)),
        PathCmd.lineTo(const Vec2(-4, 4)),
      ], const PathStyle(fill: 0xFFFFFFFF, fillRule: FillRule.evenOdd));

      expect(
        pathContainsClosedArea(
          ir,
          const Vec2(8, 0),
          fillRule: FillRule.evenOdd,
        ),
        isTrue,
      );
      expect(
        pathContainsClosedArea(
          ir,
          const Vec2(0, 0),
          fillRule: FillRule.evenOdd,
        ),
        isFalse,
      );
    });

    test('does not invent area for a 2-point open polyline', () {
      final ir = PathIR([
        PathCmd.moveTo(const Vec2(0, 0)),
        PathCmd.lineTo(const Vec2(10, 0)),
      ], const PathStyle(fill: 0xFFFFFFFF, fillRule: FillRule.nonZero));

      expect(
        pathContainsClosedArea(
          ir,
          const Vec2(5, 0),
          fillRule: FillRule.nonZero,
        ),
        isFalse,
      );
      expect(
        pathContainsClosedArea(
          ir,
          const Vec2(5, 1),
          fillRule: FillRule.nonZero,
        ),
        isFalse,
      );
    });
  });

  group('pathHitsOutline', () {
    test('hits near an open line within radius', () {
      final ir = PathIR([
        PathCmd.moveTo(const Vec2(0, 0)),
        PathCmd.lineTo(const Vec2(10, 0)),
      ], const PathStyle(stroke: 0xFF000000, strokeWidth: 1.0));

      expect(pathHitsOutline(ir, const Vec2(5, 0.4), radiusLocal: 0.5), isTrue);
    });

    test('misses when outside radius', () {
      final ir = PathIR([
        PathCmd.moveTo(const Vec2(0, 0)),
        PathCmd.lineTo(const Vec2(10, 0)),
      ], const PathStyle(stroke: 0xFF000000, strokeWidth: 1.0));

      expect(
        pathHitsOutline(ir, const Vec2(5, 0.6), radiusLocal: 0.5),
        isFalse,
      );
    });
  });
}
