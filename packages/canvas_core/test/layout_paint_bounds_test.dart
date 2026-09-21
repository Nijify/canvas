import 'dart:math' as math;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_core/src/algorithms/snapping/snap_index_scene.dart';
import 'package:test/test.dart';

class _TextMeasurer implements TextMeasurer {
  @override
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required double letterSpacing,
  }) =>
      fontFamily == 'IconFont' ? const Size2D(140, 120) : const Size2D(100, 20);
}

class _Icons implements IconResolver {
  @override
  ResolvedIcon? resolve(String iconRef) => switch (iconRef) {
    'glyph' => const ResolvedIconText(glyph: 'X', fontFamily: 'IconFont'),
    'path' => const ResolvedIconPath(
      PathData(source: RectSource(160, 30), strokeWidth: 0),
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
  Transform2D xf = const Transform2D(),
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
      _expectRect(computed.layoutBoundsWorldById['text'], layout);
      _expectRect(computed.paintBoundsLocalById['text'], sample.$2);
      _expectRect(
        computePaddedContentBounds(scene: scene, computed: computed),
        sample.$2,
      );
    });
  }

  for (final origin in OriginKind.values) {
    test('shadow preserves nested transforms and interaction: $origin', () {
      CanvasSceneDocument makeScene(double shadow) => _scene([
        Node.group(
          id: 'outer',
          xf: const Transform2D(
            position: Vec2(80, 40),
            rotationRad: 0.4,
            scale: Vec2(1.4, 0.8),
          ),
          children: [
            Node.group(
              id: 'inner',
              xf: const Transform2D(
                position: Vec2(15, -20),
                rotationRad: -0.7,
                scale: Vec2(0.8, 1.6),
              ),
              children: [
                _text(
                  shadow: shadow,
                  xf: Transform2D(
                    origin: origin,
                    customPivotPx: const Vec2(7, -3),
                    rotationRad: 0.3,
                    scale: const Vec2(-2, 0.5),
                  ),
                ),
                _text(
                  id: 'sibling',
                  xf: const Transform2D(position: Vec2(150, 30)),
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
          after.layoutBoundsWorldById[id],
          before.layoutBoundsWorldById[id],
        );
        expect(
          after.worldById[id]!.storage,
          orderedEquals(before.worldById[id]!.storage),
        );
        expect(
          after.inverseWorldById[id]!.storage,
          orderedEquals(before.inverseWorldById[id]!.storage),
        );
      }
      expect(
        after.paintBoundsWorldById['outer'],
        isNot(before.paintBoundsWorldById['outer']),
      );

      final beforeSelection = selectionGeometry([
        'text',
        'sibling',
      ], getBounds: (id) => before.layoutBoundsWorldById[id])!;
      final afterSelection = selectionGeometry([
        'text',
        'sibling',
      ], getBounds: (id) => after.layoutBoundsWorldById[id])!;
      expect(afterSelection.bounds, beforeSelection.bounds);
      expect(afterSelection.pivotWorld, beforeSelection.pivotWorld);

      final beforeSnaps = sceneObjectKeylines(beforeScene, before);
      final afterSnaps = sceneObjectKeylines(afterScene, after);
      expect(
        afterSnaps.map((c) => (c.kind, c.axis, c.pos)),
        orderedEquals(beforeSnaps.map((c) => (c.kind, c.axis, c.pos))),
      );
    });
  }

  test('world paint bounds include rotated nonuniform shadow extent', () {
    final computed = computeScene(
      _scene([
        _text(
          shadow: 10,
          xf: Transform2D(rotationRad: math.pi / 2, scale: const Vec2(2, 3)),
        ),
      ]),
      _services(),
    );
    _expectRect(
      computed.paintBoundsWorldById['text'],
      const Rect2D(-60, -100, 30, 120),
    );
  });

  test('counter-rotated groups do not inflate child-world unions', () {
    final computed = computeScene(
      _scene([
        Node.group(
          id: 'outer',
          xf: Transform2D(rotationRad: math.pi / 4),
          children: [
            Node.group(
              id: 'inner',
              xf: Transform2D(rotationRad: -math.pi / 4),
              children: [_text(shadow: 10)],
            ),
          ],
        ),
      ]),
      _services(),
    );
    for (final id in ['text', 'inner', 'outer']) {
      _expectRect(computed.layoutBoundsWorldById[id], layout);
      _expectRect(
        computed.paintBoundsWorldById[id],
        const Rect2D(-50, -10, 60, 20),
      );
    }
  });

  test('glyph layout stays square while paint follows glyph measurements', () {
    final computed = computeScene(
      _scene([
        const Node.icon(
          id: 'icon',
          data: CanvasIconData(
            iconRef: 'glyph',
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
      const Rect2D(-70, -60, 78, 68),
    );
  });

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
      after.worldById['icon']!.storage,
      orderedEquals(before.worldById['icon']!.storage),
    );
    expect(after.layoutBoundsLocalById['icon']!.width, 96);
  });

  test('shadow-only text excludes unpainted foreground from paint bounds', () {
    final computed = computeScene(
      _scene([_text(shadow: 40, foreground: const CanvasFill.none())]),
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
      _text().copyWith(locked: true),
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
    expect(
      sceneObjectKeylines(scene, computed, ignoreIds: {'unresolved'}),
      isEmpty,
    );
  });
}
