// Path: packages/canvas_core/test/path_ir_immutability_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

class _NoTextMeasurer implements TextMeasurer {
  @override
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required double letterSpacing,
  }) => throw StateError('Ordinary path evaluation must not measure text.');
}

ComputedScene _computePath(PathData data) => computeScene(
  CanvasSceneDocument(
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1,
    children: [Node.path(id: 'path', data: data)],
  ),
  CoreServices(textMeasurer: _NoTextMeasurer()),
);

List<(PathVerb, Vec2, Vec2?, Vec2?)> _geometry(PathIR path) => [
  for (final cmd in path.cmds) (cmd.verb, cmd.p, cmd.c1, cmd.c2),
];

void main() {
  test('PathIR snapshots the caller-owned command list', () {
    final commands = <PathCmd>[
      PathCmd.moveTo(const Vec2(-4, -3)),
      PathCmd.lineTo(const Vec2(8, 5)),
      PathCmd.close(),
    ];
    final expected = List<PathCmd>.of(commands);
    final path = PathIR(commands);

    commands
      ..clear()
      ..add(PathCmd.moveTo(const Vec2(999, 999)));

    expect(path.cmds, orderedEquals(expected));
    expect(path.localBounds(), const Rect2D(-4, -3, 8, 5));
  });

  test('computed path commands cannot be appended to or replaced', () {
    final computed = _computePath(const PathData(source: RectSource(24, 12)));
    final path = computed.pathIRById['path']!;
    final originalGeometry = _geometry(path);

    expect(() => path.cmds.add(PathCmd.close()), throwsUnsupportedError);
    expect(
      () => path.cmds[0] = PathCmd.moveTo(const Vec2(999, 999)),
      throwsUnsupportedError,
    );

    expect(_geometry(path), equals(originalGeometry));
    expect(path.localBounds(), const Rect2D(-12, -6, 12, 6));
  });

  test('authored appearance preserves compiled geometry', () {
    final plain = _computePath(const PathData(source: RectSource(24, 12)));
    final painted = _computePath(
      PathData(
        source: const RectSource(24, 12),
        fillRule: FillRule.evenOdd,
        appearance: CanvasAppearance(
          foreground: const CanvasFill.solid(0x8044AAFF),
          stroke: CanvasStroke(
            color: 0xFF112233,
            width: 8,
            cap: StrokeCap.round,
            join: StrokeJoin.bevel,
            miterLimit: 6,
          ),
        ),
      ),
    );

    expect(
      _geometry(painted.pathIRById['path']!),
      equals(_geometry(plain.pathIRById['path']!)),
    );

    expect(
      painted.pathIRById['path']!.localBounds(),
      const Rect2D(-12, -6, 12, 6),
    );
  });
}
