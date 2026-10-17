import 'dart:math' as math;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

class _NoText implements TextMeasurer {
  @override
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required double letterSpacing,
  }) => throw StateError('Path layout must not measure text.');
}

ComputedScene _compute(List<Node> children) => computeScene(
  CanvasSceneDocument(
    backgroundFill: const CanvasFill.none(),
    children: children,
  ),
  CoreServices(textMeasurer: _NoText()),
);

void main() {
  test('paint bounds account for square caps and miter limits', () {
    final source = PolylineSource(const [Vec2(-10, -10), Vec2(10, 10)]);
    for (final (stroke, outset) in <(CanvasStroke, double)>[
      (
        const CanvasStroke(
          color: 0xFF111111,
          width: 6,
          cap: StrokeCap.round,
          join: StrokeJoin.round,
        ),
        3,
      ),
      (
        const CanvasStroke(
          color: 0xFF111111,
          width: 6,
          cap: StrokeCap.square,
          join: StrokeJoin.bevel,
        ),
        3 * math.sqrt2,
      ),
      (const CanvasStroke(color: 0xFF111111, width: 6, miterLimit: 5), 15),
      (
        const CanvasStroke(
          color: 0xFF111111,
          width: 6,
          join: StrokeJoin.bevel,
          miterLimit: 100,
        ),
        3,
      ),
    ]) {
      final computed = _compute([
        Node.path(
          id: 'path',
          data: PathData(
            source: source,
            appearance: CanvasAppearance(
              foreground: const CanvasFill.none(),
              stroke: stroke,
            ),
          ),
        ),
      ]);
      expect(
        computed.layoutBoundsLocalById['path'],
        const Rect2D(-10, -10, 10, 10),
      );
      expect(
        computed.paintBoundsLocalById['path'],
        Rect2D(-10 - outset, -10 - outset, 10 + outset, 10 + outset),
      );
    }
  });

  test('unpainted paths retain layout without contributing content', () {
    for (final appearance in const [
      CanvasAppearance(foreground: CanvasFill.none()),
      CanvasAppearance(foreground: CanvasFill.solid(0x00112233)),
      CanvasAppearance(
        foreground: CanvasFill.gradient(LinearGradientSpec.transparent),
      ),
      CanvasAppearance(
        foreground: CanvasFill.none(),
        stroke: CanvasStroke(color: 0x00112233, width: 100),
      ),
      CanvasAppearance(
        foreground: CanvasFill.none(),
        stroke: CanvasStroke(color: 0xFF111111, width: 0),
      ),
    ]) {
      final scene = CanvasSceneDocument(
        children: [
          Node.path(
            id: 'path',
            data: PathData(
              source: const RectSource(20, 10),
              appearance: appearance,
            ),
          ),
        ],
      );
      final computed = computeScene(
        scene,
        CoreServices(textMeasurer: _NoText()),
      );
      expect(
        computed.layoutBoundsLocalById['path'],
        const Rect2D(-10, -5, 10, 5),
      );
      expect(computed.pathIRById['path'], isNotNull);
      expect(computed.paintBoundsLocalById, isEmpty);
      expect(computed.paintBoundsWorldById, isEmpty);
      expect(
        computePaddedContentBounds(scene: scene, computed: computed),
        isNull,
      );
    }

    final filled = _compute([
      const Node.path(
        id: 'path',
        data: PathData(
          source: RectSource(20, 10),
          appearance: CanvasAppearance(
            foreground: CanvasFill.solid(0xFF112233),
            stroke: CanvasStroke(color: 0x00112233, width: 100),
          ),
        ),
      ),
    ]);
    expect(filled.paintBoundsLocalById['path'], const Rect2D(-10, -5, 10, 5));
  });

  test('zero-area line geometry has stroke paint and content bounds', () {
    for (final points in const [
      [Vec2(-10, 0), Vec2(10, 0)],
      [Vec2(0, -10), Vec2(0, 10)],
      [Vec2.zero, Vec2.zero],
    ]) {
      final scene = CanvasSceneDocument(
        children: [
          Node.path(
            id: 'path',
            data: PathData(
              source: PolylineSource(points),
              appearance: const CanvasAppearance(
                foreground: CanvasFill.none(),
                stroke: CanvasStroke(
                  color: 0xFF112233,
                  width: 6,
                  cap: StrokeCap.round,
                  join: StrokeJoin.round,
                ),
              ),
            ),
          ),
        ],
      );
      final computed = computeScene(
        scene,
        CoreServices(textMeasurer: _NoText()),
      );
      final layout = computed.layoutBoundsLocalById['path']!;
      expect(layout.width == 0 || layout.height == 0, isTrue);
      expect(computed.paintBoundsLocalById['path'], layout.inflate(3));
      expect(
        computePaddedContentBounds(scene: scene, computed: computed),
        layout.inflate(3),
      );
    }
  });

  test('empty and move-only paths have no paint', () {
    for (final source in [
      CommandPathSource([]),
      CommandPathSource([PathCmd.moveTo(const Vec2(10, 20))]),
    ]) {
      final computed = _compute([
        Node.path(
          id: 'path',
          data: PathData(
            source: source,
            appearance: const CanvasAppearance(
              stroke: CanvasStroke(color: 0xFF111111, cap: StrokeCap.round),
            ),
          ),
        ),
      ]);
      expect(computed.layoutBoundsLocalById.containsKey('path'), isTrue);
      expect(computed.paintBoundsLocalById, isEmpty);
      expect(computed.paintBoundsWorldById, isEmpty);
    }
  });

  for (final origin in OriginKind.values) {
    test(
      'path appearance preserves nested geometry and transforms: $origin',
      () {
        final source = PolylineSource(const [
          Vec2(10, 20),
          Vec2(40, 20),
          Vec2(40, 70),
        ]);
        ComputedScene build(CanvasAppearance appearance) => _compute([
          Node.group(
            id: 'outer',
            xf: const Transform2D(rotationRad: 0.4, scale: Vec2(1.4, 0.8)),
            children: [
              Node.group(
                id: 'inner',
                xf: const Transform2D(
                  position: Vec2(15, -20),
                  rotationRad: -0.7,
                ),
                children: [
                  Node.path(
                    id: 'path',
                    xf: Transform2D(
                      origin: origin,
                      customPivotPx: const Vec2(7, -3),
                      rotationRad: 0.3,
                      scale: const Vec2(-2, 0.5),
                    ),
                    data: PathData(source: source, appearance: appearance),
                  ),
                  const Node.path(
                    id: 'sibling',
                    xf: Transform2D(position: Vec2(150, 30)),
                    data: PathData(source: RectSource(20, 10)),
                  ),
                ],
              ),
            ],
          ),
        ]);
        final before = build(
          const CanvasAppearance(foreground: CanvasFill.none()),
        );
        final after = build(
          const CanvasAppearance(
            foreground: CanvasFill.solid(0xFF112233),
            stroke: CanvasStroke(
              color: 0xFF112233,
              width: 40,
              cap: StrokeCap.square,
              miterLimit: 8,
            ),
          ),
        );
        expect(after.pathIRById['path'], same(before.pathIRById['path']));
        for (final id in ['path', 'sibling', 'inner', 'outer']) {
          expect(
            after.layoutBoundsLocalById[id],
            before.layoutBoundsLocalById[id],
          );
          expect(
            after.worldById[id]!.storage,
            orderedEquals(before.worldById[id]!.storage),
          );
        }
        expect(before.paintBoundsWorldById, isEmpty);
        expect(after.paintBoundsWorldById.containsKey('outer'), isTrue);
      },
    );
  }
}
