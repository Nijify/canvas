import 'dart:convert';
import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_scene_upgrade/canvas_scene_upgrade.dart';
import 'package:test/test.dart';

Map<String, Object?> _scene(Map<String, Object?> source) => {
  'sceneFormatVersion': 3,
  'artboardSize': {'w': 300, 'h': 200},
  'backgroundFill': {'type': 'none'},
  'backgroundOpacity': 1,
  'children': [
    {
      'runtimeType': 'path',
      'id': 'shape',
      'name': 'Authored',
      'role': 'decoration',
      'xf': {
        'position': {'x': 15, 'y': 25},
        'rotationRad': .5,
        'scale': {'x': 2, 'y': 3},
      },
      'data': {
        'source': source,
        'fillRule': 'evenOdd',
        'appearance': {
          'foreground': {'type': 'solid', 'color': 0xff112233},
          'stroke': {
            'color': 0xff445566,
            'width': 3,
            'dash': [2, 1],
          },
          'underlays': [],
        },
      },
    },
  ],
};
PathSource _convert(Map<String, Object?> source) =>
    (decodeCanvasScene(upgradeCanvasScene(_scene(source))).children.single
            as PathNode)
        .data
        .source;

void main() {
  test('centered basic shapes become explicit source coordinates', () {
    final rect = _convert({'kind': 'rect', 'w': 160, 'h': 100}) as RectSource;
    expect(rect.x, -80);
    expect(rect.y, -50);
    expect(rect.width, 160);
    expect(rect.height, 100);
    final pill = _convert({'kind': 'pill', 'w': 160, 'h': 100}) as RectSource;
    expect(pill.rx, 50);
    expect(pill.ry, 50);
    final underline =
        _convert({'kind': 'underline', 'w': 100, 'thickness': 6}) as RectSource;
    expect(underline.y, -3);
    expect(underline.height, 6);
    expect(_convert({'kind': 'circle', 'r': 10}), isA<CircleSource>());
    expect(
      _convert({'kind': 'ellipse', 'rx': 10, 'ry': 5}),
      isA<EllipseSource>(),
    );
    final rounded =
        _convert({'kind': 'roundRect', 'w': 20, 'h': 10, 'rx': 3, 'ry': 4})
            as RectSource;
    expect(rounded.rx, 3);
    expect(rounded.ry, 4);
  });

  test(
    'polygons and stars retain explicit vertices without generator parameters',
    () {
      final polygon =
          _convert({'kind': 'regularPolygon', 'sides': 4, 'r': 10})
              as PolygonSource;
      expect(polygon.points, hasLength(4));
      expect(polygon.points.first, const Vec2(10, 0));
      final star =
          _convert({'kind': 'star', 'points': 5, 'rOuter': 10, 'rInner': 5})
              as PolygonSource;
      expect(star.points, hasLength(10));
      expect(star.points[1].length, closeTo(5, 1e-9));
      expect(star.toJson().keys, unorderedEquals(['kind', 'points']));
    },
  );

  test(
    'single polylines become line/polyline and contour breaks become path',
    () {
      const a = {'x': 0, 'y': 0},
          b = {'x': 10, 'y': 20},
          c = {'x': 30, 'y': 40};
      expect(
        _convert({
          'kind': 'polyline',
          'points': [a, b],
        }),
        isA<LineSource>(),
      );
      expect(
        _convert({
          'kind': 'polyline',
          'points': [a, b, c],
        }),
        isA<PolylineSource>(),
      );
      final path =
          _convert({
                'kind': 'polyline',
                'points': [a, b, null, c],
              })
              as GeneralPathSource;
      expect(path.geometry.cmds.map((command) => command.verb), [
        PathVerb.moveTo,
        PathVerb.lineTo,
        PathVerb.moveTo,
      ]);
    },
  );

  test('historical quadratic commands become cubic path data', () {
    final path =
        _convert({
              'kind': 'commands',
              'commands': [
                {
                  'verb': 'moveTo',
                  'p': {'x': 0, 'y': 0},
                },
                {
                  'verb': 'quadTo',
                  'c1': {'x': 30, 'y': 60},
                  'p': {'x': 60, 'y': 0},
                },
              ],
            })
            as GeneralPathSource;
    expect(path.geometry.cmds[1].c1, const Vec2(20, 40));
    expect(path.geometry.cmds[1].c2, const Vec2(40, 40));
    expect(path.toJson().containsKey('commands'), isFalse);
  });

  test('migration copies JSON and preserves unrelated authored content', () {
    final old = _scene({'kind': 'rect', 'w': 20, 'h': 10});
    final before = jsonEncode(old);
    final result = upgradeCanvasScene(old);
    expect(result['sceneFormatVersion'], 5);
    final oldNode = (old['children'] as List).single as Map;
    final newNode = (result['children'] as List).single as Map;
    for (final key in ['id', 'name', 'role'])
      expect(newNode[key], oldNode[key]);
    expect(
      (newNode['data'] as Map)['appearance'],
      (oldNode['data'] as Map)['appearance'],
    );
    (newNode['xf'] as List)[0] = 9;
    expect(jsonEncode(old), before);
    expect(() => decodeCanvasScene(old), throwsFormatException);
  });
}
