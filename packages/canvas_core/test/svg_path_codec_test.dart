import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

void main() {
  test(
    'relative, repeated, horizontal, vertical, and compact numbers normalize',
    () {
      final ir = parseSvgPathData('m1 2 3 4h5v-2l.5-.5z');
      expect(ir.cmds.map((command) => command.verb), [
        PathVerb.moveTo,
        PathVerb.lineTo,
        PathVerb.lineTo,
        PathVerb.lineTo,
        PathVerb.lineTo,
        PathVerb.close,
      ]);
      expect(ir.cmds[1].p, const Vec2(4, 6));
      expect(ir.cmds[2].p, const Vec2(9, 6));
      expect(ir.cmds[3].p, const Vec2(9, 4));
      expect(ir.cmds[4].p, const Vec2(9.5, 3.5));
    },
  );

  test('quadratic and smooth curves become cubics with reflected controls', () {
    final ir = parseSvgPathData('M0 0Q30 60 60 0T120 0');
    expect(ir.cmds[1].verb, PathVerb.cubicTo);
    expect(ir.cmds[1].c1, const Vec2(20, 40));
    expect(ir.cmds[1].c2, const Vec2(40, 40));
    expect(ir.cmds[2].c1, const Vec2(80, -40));
    expect(ir.cmds[2].c2, const Vec2(100, -40));
    final smooth = parseSvgPathData('M0 0C10 10 20 10 30 0S50 -10 60 0');
    expect(smooth.cmds.last.c1, const Vec2(40, -10));
  });

  test('elliptical arcs normalize to finite cubic segments', () {
    final ir = parseSvgPathData('M10 0A10 10 0 0 1 0 10');
    expect(
      ir.cmds.skip(1).every((command) => command.verb == PathVerb.cubicTo),
      isTrue,
    );
    expect(ir.cmds.last.p.x, closeTo(0, 1e-5));
    expect(ir.cmds.last.p.y, closeTo(10, 1e-5));
    expect(
      parseSvgPathData('M0 0A0 10 0 0 1 10 10').cmds.last.verb,
      PathVerb.lineTo,
    );
    expect(parseSvgPathData('M0 0A10 10 0 0 1 0 0').hasSegments, isFalse);
  });

  test('drawing after close starts at the closed contour origin', () {
    final ir = parseSvgPathData('M10 20L30 20Zl5 7zZ');
    expect(ir.cmds.map((command) => command.verb), [
      PathVerb.moveTo,
      PathVerb.lineTo,
      PathVerb.close,
      PathVerb.moveTo,
      PathVerb.lineTo,
      PathVerb.close,
    ]);
    expect(ir.cmds[3].p, const Vec2(10, 20));
    expect(ir.cmds[4].p, const Vec2(15, 27));
    expect(
      writeSvgPathData(parseSvgPathData(writeSvgPathData(ir))),
      writeSvgPathData(ir),
    );
  });

  test('empty and move-only input stays nonpainting', () {
    for (final d in ['', '  \n', 'M0 0', 'M0 0Z']) {
      expect(parseSvgPathData(d).hasSegments, isFalse);
    }
  });

  test(
    'malformed input and nonfinite coordinates fail without partial geometry',
    () {
      for (final d in [
        'L0 0',
        'M0',
        'M0 0L',
        'M0 0X1 2',
        'M0 0,',
        'M0 0,L1 1',
        'M0 0A10 10 0 2 0 1 1',
        'M1e999 0',
        'MNaN 0',
      ]) {
        expect(() => parseSvgPathData(d), throwsFormatException, reason: d);
      }
    },
  );

  test(
    'writer uses absolute M/L/C/Z, preserves contours, and normalizes negative zero',
    () {
      final ir = PathIR([
        PathCmd.moveTo(const Vec2(-0.0, 0)),
        PathCmd.lineTo(const Vec2(10, 20)),
        PathCmd.close(),
        PathCmd.moveTo(const Vec2(30, 40)),
        PathCmd.cubicTo(
          const Vec2(40, 50),
          const Vec2(60, 70),
          const Vec2(80, 90),
        ),
      ]);
      final d = writeSvgPathData(ir);
      expect(d, 'M0 0 L10.0 20.0 Z M30.0 40.0 C40.0 50.0 60.0 70.0 80.0 90.0');
      expect(writeSvgPathData(parseSvgPathData(d)), d);
      expect(writeSvgPathData(ir), d);
    },
  );

  test('fractional paths stay stable across repeated JSON save/load', () {
    List<Vec2> points(PathIR path) => [
      for (final command in path.cmds) ...[
        command.p,
        if (command.c1 != null) command.c1!,
        if (command.c2 != null) command.c2!,
      ],
    ];

    for (final d in [
      'M0.3 0.29L12.345 -6.789Z',
      'M0.1 0.2Q30.7 60.4 60.3 0.6T120.9 0.8',
      'M10.3 0.7A10.1 15.2 30 0 1 0.9 10.4Z',
    ]) {
      final original = GeneralPathSource.fromSvg(d);
      var restored = original;
      for (var cycle = 0; cycle < 100; cycle++) {
        restored = PathSource.fromJson(restored.toJson()) as GeneralPathSource;
      }

      expect(
        restored.geometry.cmds.map((command) => command.verb),
        original.geometry.cmds.map((command) => command.verb),
      );
      final expected = points(original.geometry);
      final actual = points(restored.geometry);
      expect(actual, hasLength(expected.length));
      for (var i = 0; i < expected.length; i++) {
        expect(actual[i].x, closeTo(expected[i].x, 1e-9), reason: d);
        expect(actual[i].y, closeTo(expected[i].y, 1e-9), reason: d);
      }
    }
  });
}
