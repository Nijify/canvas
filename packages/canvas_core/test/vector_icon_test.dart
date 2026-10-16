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
  }) => throw StateError('Vector icons must not measure text.');
}

class _Icons implements IconResolver {
  _Icons(this.icon);
  final ResolvedIcon? icon;
  int calls = 0;
  @override
  ResolvedIcon? resolve(String ref) {
    calls++;
    return icon;
  }
}

CommandPathSource _rect(Rect2D box) => CommandPathSource([
  PathCmd.moveTo(Vec2(box.left, box.top)),
  PathCmd.lineTo(Vec2(box.right, box.top)),
  PathCmd.lineTo(Vec2(box.right, box.bottom)),
  PathCmd.lineTo(Vec2(box.left, box.bottom)),
  PathCmd.close(),
]);

ResolvedIcon _icon({
  CommandPathSource? source,
  Rect2D viewBox = const Rect2D(0, 0, 24, 24),
  FillRule fillRule = FillRule.nonZero,
}) => ResolvedIcon(
  source: source ?? _rect(viewBox),
  viewBox: viewBox,
  fillRule: fillRule,
);

ComputedScene _compute(
  _Icons? icons, {
  double size = 96,
  CanvasAppearance appearance = const CanvasAppearance(),
}) => computeScene(
  CanvasSceneDocument(
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1,
    children: [
      Node.icon(
        id: 'icon',
        data: CanvasIconData(
          iconRef: 'test',
          sizePx: size,
          appearance: appearance,
        ),
      ),
    ],
  ),
  CoreServices(textMeasurer: _NoText(), icons: icons),
);

void _expectRect(Rect2D? actual, Rect2D expected) {
  expect(actual, isNotNull);
  expect(actual!.left, closeTo(expected.left, 1e-9));
  expect(actual.top, closeTo(expected.top, 1e-9));
  expect(actual.right, closeTo(expected.right, 1e-9));
  expect(actual.bottom, closeTo(expected.bottom, 1e-9));
}

void main() {
  test('rejects invalid viewBoxes', () {
    final source = _rect(const Rect2D(0, 0, 24, 24));
    for (final box in [
      const Rect2D(0, 0, 0, 24),
      const Rect2D(24, 0, 0, 24),
      const Rect2D(0, 0, 24, 0),
      const Rect2D(0, double.nan, 24, 24),
      const Rect2D(0, 0, double.infinity, 24),
      const Rect2D(-1e308, 0, 1e308, 24),
    ]) {
      expect(() => _icon(source: source, viewBox: box), throwsArgumentError);
    }
  });

  test('24-square source fits to 96 without changing its commands', () {
    final icon = _icon(fillRule: FillRule.evenOdd);
    final original = icon.source.toJson();
    final icons = _Icons(icon);
    final computed = _compute(icons);
    final result = computed.iconById['icon']!;
    expect(icons.calls, 1);
    expect(result.fillRule, FillRule.evenOdd);
    expect(result.pathIR.cmds, orderedEquals(icon.source.commands));
    expect(icon.source.toJson(), original);
    expect(result.pathIR.cmds.first.p, const Vec2(0, 0));
    _expectRect(
      aabbOfTransformedRect(result.pathIR.localBounds(), result.sourceToLocal),
      const Rect2D(-48, -48, 48, 48),
    );
    _expectRect(
      computed.layoutBoundsLocalById['icon'],
      const Rect2D(-48, -48, 48, 48),
    );
    _expectRect(
      computed.paintBoundsLocalById['icon'],
      const Rect2D(-48, -48, 48, 48),
    );
  });

  test('non-square fitting preserves source origins and authored margins', () {
    const box = Rect2D(10, -8, 42, 8); // 32 by 16
    for (final (geometry, expected) in [
      (box, const Rect2D(-48, -24, 48, 24)),
      (const Rect2D(14, -4, 38, 4), const Rect2D(-36, -12, 36, 12)),
    ]) {
      final icon = _icon(source: _rect(geometry), viewBox: box);
      final computed = _compute(_Icons(icon));
      _expectRect(
        computed.layoutBoundsLocalById['icon'],
        const Rect2D(-48, -48, 48, 48),
      );
      _expectRect(computed.paintBoundsLocalById['icon'], expected);
    }
  });

  test('shadow offset and blur stay local when source fitting changes', () {
    final icon = _icon();
    const appearance = CanvasAppearance(
      foreground: CanvasFill.none(),
      underlays: [
        ShadowEffect(
          id: 's',
          offset: Vec2(100, 20),
          blurSigma: 2,
          color: 0xff123456,
        ),
      ],
    );
    _expectRect(
      _compute(
        _Icons(icon),
        size: 96,
        appearance: appearance,
      ).paintBoundsLocalById['icon'],
      const Rect2D(44, -36, 156, 76),
    );
    _expectRect(
      _compute(
        _Icons(icon),
        size: 48,
        appearance: appearance,
      ).paintBoundsLocalById['icon'],
      const Rect2D(68, -12, 132, 52),
    );
  });

  test('the layout square does not clip overflowing source geometry', () {
    final computed = _compute(
      _Icons(
        _icon(
          source: _rect(const Rect2D(-24, -24, 24, 24)),
          viewBox: const Rect2D(-12, -12, 12, 12),
        ),
      ),
    );
    _expectRect(
      computed.layoutBoundsLocalById['icon'],
      const Rect2D(-48, -48, 48, 48),
    );
    _expectRect(
      computed.paintBoundsLocalById['icon'],
      const Rect2D(-96, -96, 96, 96),
    );
  });

  test('empty and unresolved icons retain layout without paint', () {
    for (final icons in <_Icons?>[
      _Icons(_icon(source: CommandPathSource([]))),
      _Icons(null),
      null,
    ]) {
      final computed = _compute(
        icons,
        appearance: const CanvasAppearance(
          underlays: [
            ShadowEffect(id: 's', offset: Vec2(100, 100), color: 0xff000000),
          ],
        ),
      );
      _expectRect(
        computed.layoutBoundsLocalById['icon'],
        const Rect2D(-48, -48, 48, 48),
      );
      expect(computed.paintBoundsLocalById, isEmpty);
      expect(computed.iconById.containsKey('icon'), icons?.icon != null);
    }
  });

  test('invalid instance sizes fail instead of producing unusable fitting', () {
    for (final size in [
      0.0,
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(() => ComputedIcon.fit(_icon(), size), throwsArgumentError);
    }
  });

  test('scene rejects invalid sizes before any icon lookup', () {
    for (final size in [
      0.0,
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      for (final icon in <ResolvedIcon?>[null, _icon()]) {
        final icons = _Icons(icon);
        expect(() => _compute(icons, size: size), throwsArgumentError);
        expect(icons.calls, 0);
      }
      expect(() => _compute(null, size: size), throwsArgumentError);
    }
  });
}
