// Path: packages/canvas_core/test/layout_paint_bounds_test.dart

import 'dart:math' as math;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

class _TextMeasurer implements TextMeasurer {
  @override
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required double letterSpacing,
  }) => const Size2D(100, 20);
}

class _Icons implements IconResolver {
  @override
  ResolvedIcon? resolve(String iconRef) => switch (iconRef) {
    'path' => ResolvedIcon(
      pathIR: PathIR([
        PathCmd.moveTo(const Vec2(-80, -15)),
        PathCmd.lineTo(const Vec2(80, -15)),
        PathCmd.lineTo(const Vec2(80, 15)),
        PathCmd.lineTo(const Vec2(-80, 15)),
        PathCmd.close(),
      ]),
      viewBox: const Rect2D(-80, -15, 80, 15),
      fillRule: FillRule.nonZero,
    ),
    _ => null,
  };
}

class _Images implements ImageIntrinsics {
  @override
  Size2D? intrinsicSize(ElementId id) => const Size2D(200, 100);
}

CoreServices _services() => CoreServices(
  textMeasurer: _TextMeasurer(),
  icons: _Icons(),
  images: _Images(),
);

CanvasSceneDocument _scene(List<Node> children) => CanvasSceneDocument(
  backgroundFill: const CanvasFill.none(),
  backgroundOpacity: 1,
  children: children,
);

Node _text({
  String id = 'text',
  double shadow = 0,
  CanvasFill foreground = const CanvasFill.solid(0xFF111111),
  Affine2D xf = const Affine2D.identity(),
}) => Node.text(
  id: id,
  xf: xf,
  data: TextData(
    text: 'TEXT',
    fontFamily: 'TestFont',
    fontWeight: 400,
    fontSize: 20,
    appearance: CanvasAppearance(
      foreground: foreground,
      underlays: shadow == 0
          ? const []
          : [
              ShadowEffect(
                id: 's',
                offset: Vec2(shadow, shadow),
                color: 0xFF111111,
              ),
            ],
    ),
  ),
);

void _expectRect(Rect2D? actual, Rect2D expected) {
  expect(actual, isNotNull);
  final rect = actual!;
  expect(rect.left, closeTo(expected.left, 1e-8));
  expect(rect.top, closeTo(expected.top, 1e-8));
  expect(rect.right, closeTo(expected.right, 1e-8));
  expect(rect.bottom, closeTo(expected.bottom, 1e-8));
}

void main() {
  const layout = Rect2D(-50, -10, 50, 10);

  for (final sample in <(double, Rect2D)>[
    (0, layout),
    (10, const Rect2D(-50, -10, 60, 20)),
    (-12, const Rect2D(-62, -22, 50, 10)),
  ]) {
    test('shadow ${sample.$1} changes content bounds, not layout', () {
      final scene = _scene([_text(shadow: sample.$1)]);
      final computed = computeScene(scene, _services());
      _expectRect(computed.layoutBoundsLocalById['text'], layout);
      _expectRect(computed.paintBoundsLocalById['text'], sample.$2);
      _expectRect(
        computePaddedContentBounds(scene: scene, computed: computed),
        sample.$2,
      );
    });
  }

  for (final extra in [const Affine2D.identity(), Affine2D.shear(.6, -.2)]) {
    test('shadow preserves nested layout and transforms: $extra', () {
      CanvasSceneDocument makeScene(double shadow) => _scene([
        Node.group(
          id: 'outer',
          xf: extra * (Affine2D.translation(80, 40) * Affine2D.rotation(0.4) * Affine2D.scale(1.4, 0.8)),
          children: [
            Node.group(
              id: 'inner',
              xf: (Affine2D.translation(15, -20) * Affine2D.rotation(-0.7) * Affine2D.scale(0.8, 1.6)),
              children: [
                _text(
                  shadow: shadow,
                  xf: (Affine2D.translation(7, -3) * Affine2D.rotation(0.3) * Affine2D.scale(-2, 0.5) * Affine2D.translation(-(7), -(-3))),
                ),
                _text(
                  id: 'sibling',
                  xf: Affine2D.translation(150, 30),
                ),
              ],
            ),
          ],
        ),
      ]);

      final beforeScene = makeScene(0);
      final afterScene = makeScene(200);
      final before = computeScene(beforeScene, _services());
      final after = computeScene(afterScene, _services());
      for (final id in ['text', 'sibling', 'inner', 'outer']) {
        expect(
          after.layoutBoundsLocalById[id],
          before.layoutBoundsLocalById[id],
        );
        expect(
          after.worldById[id]!.toJson(),
          orderedEquals(before.worldById[id]!.toJson()),
        );
      }
      expect(
        after.paintBoundsWorldById['outer'],
        isNot(before.paintBoundsWorldById['outer']),
      );
    });
  }

  test('world paint bounds include rotated nonuniform shadow extent', () {
    final computed = computeScene(
      _scene([
        _text(
          shadow: 10,
          xf: (Affine2D.rotation(math.pi / 2) * Affine2D.scale(2, 3)),
        ),
      ]),
      _services(),
    );
    _expectRect(
      computed.paintBoundsWorldById['text'],
      const Rect2D(-60, -100, 30, 120),
    );
  });
  test('counter-rotated groups do not inflate child-world paint unions', () {
    final computed = computeScene(
      _scene([
        Node.group(
          id: 'outer',
          xf: Affine2D.rotation(math.pi / 4),
          children: [
            Node.group(
              id: 'inner',
              xf: Affine2D.rotation(-math.pi / 4),
              children: [_text(shadow: 10)],
            ),
          ],
        ),
      ]),
      _services(),
    );
    for (final id in ['text', 'inner', 'outer']) {
      _expectRect(
        computed.paintBoundsWorldById[id],
        const Rect2D(-50, -10, 60, 20),
      );
    }
  });

  test(
    'icon layout stays square while paint follows fitted vector geometry',
    () {
      final computed = computeScene(
        _scene([
          const Node.icon(
            id: 'icon',
            data: CanvasIconData(
              iconRef: 'path',
              sizePx: 96,
              appearance: CanvasAppearance(
                underlays: [
                  ShadowEffect(id: 's', offset: Vec2(8, 8), color: 0xFF111111),
                ],
              ),
            ),
          ),
        ]),
        _services(),
      );
      _expectRect(
        computed.layoutBoundsLocalById['icon'],
        const Rect2D(-48, -48, 48, 48),
      );
      _expectRect(
        computed.paintBoundsLocalById['icon'],
        const Rect2D(-48, -9, 56, 17),
      );
    },
  );

  test('path icon shadows expand paint without changing layout', () {
    ComputedScene build(bool withShadow) => computeScene(
      _scene([
        Node.icon(
          id: 'icon',
          data: CanvasIconData(
            iconRef: 'path',
            sizePx: 96,
            appearance: CanvasAppearance(
              underlays: withShadow
                  ? const [
                      ShadowEffect(
                        id: 's',
                        offset: Vec2(40, -10),
                        blurSigma: 2,
                        color: 0x80000000,
                      ),
                    ]
                  : const [],
            ),
          ),
        ),
      ]),
      _services(),
    );
    final before = build(false);
    final after = build(true);
    final base = before.paintBoundsLocalById['icon']!;
    // Four sigma = 8. Union source with its (40, -10) translated blur.
    _expectRect(
      after.paintBoundsLocalById['icon'],
      Rect2D.fromLTRB(base.left, base.top - 18, base.right + 48, base.bottom),
    );
    expect(
      after.layoutBoundsLocalById['icon'],
      before.layoutBoundsLocalById['icon'],
    );
    expect(
      after.worldById['icon']!.toJson(),
      orderedEquals(before.worldById['icon']!.toJson()),
    );
    expect(after.layoutBoundsLocalById['icon']!.width, 96);
  });

  for (final foreground in const [
    CanvasFill.none(),
    CanvasFill.solid(0x00112233),
    CanvasFill.gradient(LinearGradientSpec.transparent),
  ]) {
    test('shadow-only text excludes unpainted foreground: $foreground', () {
      final computed = computeScene(
        _scene([_text(shadow: 40, foreground: foreground)]),
        _services(),
      );

      _expectRect(computed.layoutBoundsLocalById['text'], layout);

      // Source is (-50,-10)-(50,10). The only visible paint is the shadow
      // translated by (+40,+40).
      _expectRect(
        computed.paintBoundsLocalById['text'],
        const Rect2D(-10, 30, 90, 50),
      );
    });
  }

  test('contain-fit image retains its existing destination geometry', () {
    final computed = computeScene(
      _scene([
        const Node.image(
          id: 'image',
          data: ImageData(
            size: Size2D(100, 100),
            fit: ImageFit.contain,
            align: Vec2.zero,
          ),
        ),
      ]),
      _services(),
    );
    _expectRect(
      computed.layoutBoundsLocalById['image'],
      const Rect2D(-50, -50, 50, 0),
    );
    _expectRect(
      computed.paintBoundsLocalById['image'],
      const Rect2D(-50, -50, 50, 0),
    );
  });

  test('hidden subtrees and empty groups do not add content bounds', () {
    final scene = _scene([
      Node.group(
        id: 'hidden',
        hidden: true,
        children: [_text(id: 'hidden-text', shadow: 500)],
      ),
      const Node.group(id: 'empty'),
      const Node.icon(
        id: 'unresolved',
        data: CanvasIconData(iconRef: 'missing'),
      ),
      _text(),
    ]);
    final computed = computeScene(scene, _services());
    expect(computed.nodeById.containsKey('hidden-text'), isFalse);
    expect(computed.layoutBoundsLocalById.containsKey('empty'), isFalse);
    expect(computed.paintBoundsWorldById.containsKey('empty'), isFalse);
    expect(computed.layoutBoundsLocalById.containsKey('unresolved'), isTrue);
    expect(computed.paintBoundsWorldById.containsKey('unresolved'), isFalse);
    _expectRect(
      computePaddedContentBounds(scene: scene, computed: computed),
      layout,
    );
  });
}
