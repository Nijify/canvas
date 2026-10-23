import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_core/src/adapters/path_compile_scene.dart';
import 'package:test/test.dart';

PathIR _compile(PathSource source) => compilePath(PathData(source: source));

void main() {
  test(
    'all seven kinds use one geometry pipeline and canonical persistence',
    () {
      final sources = <PathSource>[
        const RectSource(x: 10, y: 20, width: 100, height: 50),
        const CircleSource(10, cx: 30, cy: -5),
        const EllipseSource(10, 5, cx: -20, cy: 40),
        const LineSource(x1: -10, y1: 2, x2: 10, y2: 2),
        PolylineSource(const [Vec2.zero, Vec2(10, 5), Vec2(20, 0)]),
        PolygonSource(const [Vec2.zero, Vec2(10, 5), Vec2(20, 0)]),
        GeneralPathSource.fromSvg('M0 0L10 0L10 10Z'),
      ];
      expect(sources.map((source) => source.toJson()['kind']), [
        'rect',
        'circle',
        'ellipse',
        'line',
        'polyline',
        'polygon',
        'path',
      ]);
      for (final source in sources) {
        final restored = PathSource.fromJson(source.toJson());
        expect(restored.toJson(), source.toJson());
        expect(_compile(restored).hasSegments, isTrue);
      }
      expect(_compile(sources[0]).localBounds(), const Rect2D(10, 20, 110, 70));
      expect(_compile(sources[3]).cmds.last.verb, PathVerb.lineTo);
      expect(_compile(sources[4]).cmds.last.verb, PathVerb.lineTo);
      expect(_compile(sources[5]).cmds.last.verb, PathVerb.close);
    },
  );

  test(
    'rectangle radii preserve omission, fallback before clamping, and zero',
    () {
      const source = RectSource(width: 20, height: 100, rx: 30);
      expect(source.toJson().containsKey('ry'), isFalse);
      final rounded = _compile(source);
      expect(rounded.cmds.first.p, const Vec2(10, 0));
      // ry falls back to authored rx=30, independently of rx's width clamp to 10.
      expect(rounded.cmds[2].p, const Vec2(20, 30));
      expect(
        _compile(
          const RectSource(width: 20, height: 100, rx: 0, ry: 30),
        ).cmds.where((command) => command.verb == PathVerb.cubicTo),
        isEmpty,
      );
      expect(
        _compile(const RectSource(width: 20, height: 100, ry: 30)).cmds[2].p,
        const Vec2(20, 30),
      );
    },
  );

  test('zero dimensions and radii disable basic-shape geometry', () {
    for (final source in <PathSource>[
      const RectSource(width: 0, height: 20),
      const RectSource(width: 20, height: 0, rx: 5),
      const CircleSource(0, cx: 100),
      const EllipseSource(0, 10),
      const EllipseSource(10, 0),
    ]) {
      expect(_compile(source).cmds, isEmpty);
    }
    expect(_compile(const LineSource()).hasSegments, isTrue);
    expect(parseSvgPathData('M10 20').hasSegments, isFalse);
  });

  test(
    'points freeze inputs, support compact numbers, and reject malformed lists',
    () {
      final points = [const Vec2(1, 2), const Vec2(3, 4)];
      final source = PolygonSource(points);
      points.clear();
      expect(source.points, hasLength(2));
      expect(() => source.points.clear(), throwsUnsupportedError);
      expect(parseSvgPoints(' .5,-2 1e2,+3 '), const [
        Vec2(.5, -2),
        Vec2(100, 3),
      ]);
      expect(parseSvgPoints(''), isEmpty);
      for (final bad in ['0', '0,0,', ',0,0', '0,,0', '0 nope', '1e999 0']) {
        expect(() => parseSvgPoints(bad), throwsFormatException, reason: bad);
      }
      expect(
        () => PolylineSource(const [Vec2(double.nan, 0)]),
        throwsArgumentError,
      );
    },
  );

  test('v4 rejects obsolete, mixed, nonfinite, and malformed source data', () {
    for (final json in <Map<String, Object?>>[
      {'kind': 'rect', 'w': 20, 'h': 10},
      {'kind': 'rect', 'width': 20, 'height': 10, 'rx': null},
      {'kind': 'rect', 'width': -1, 'height': 10},
      {'kind': 'circle', 'r': double.infinity},
      {'kind': 'roundRect', 'w': 20, 'h': 10, 'rx': 2, 'ry': 2},
      {'kind': 'commands', 'commands': []},
      {
        'kind': 'polyline',
        'points': [null],
      },
      {'kind': 'path', 'd': 'M0 0', 'commands': []},
    ]) {
      expect(() => PathSource.fromJson(json), throwsFormatException);
    }
  });

  test(
    'general paths and icons reuse immutable prepared geometry by identity',
    () {
      final input = [
        PathCmd.moveTo(Vec2.zero),
        PathCmd.lineTo(const Vec2(10, 0)),
      ];
      final geometry = PathIR(input);
      input.clear();
      final source = GeneralPathSource(geometry);
      expect(identical(_compile(source), geometry), isTrue);
      expect(() => geometry.cmds.clear(), throwsUnsupportedError);
      final icon = ResolvedIcon(
        pathIR: geometry,
        viewBox: const Rect2D(0, 0, 20, 10),
        fillRule: FillRule.nonZero,
      );
      expect(identical(ComputedIcon.fit(icon, 24).pathIR, geometry), isTrue);
      expect(identical(ComputedIcon.fit(icon, 96).pathIR, geometry), isTrue);
      expect(() => PathIR([PathCmd.lineTo(Vec2.zero)]), throwsArgumentError);
      expect(
        () => PathIR([PathCmd.moveTo(const Vec2(double.nan, 0))]),
        throwsArgumentError,
      );
      expect(
        () => PathIR([
          PathCmd.moveTo(Vec2.zero),
          PathCmd.close(),
          PathCmd.lineTo(Vec2.zero),
        ]),
        throwsArgumentError,
      );
    },
  );
}
