import 'dart:convert';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

CanvasSceneDocument _scene(List<Node> children) => CanvasSceneDocument(
  backgroundFill: const CanvasFill.none(),
  backgroundOpacity: 1,
  children: children,
);

Map<String, Object?> _wire() => encodeCanvasScene(
  _scene([
    Node.path(
      id: 'path',
      data: PathData(
        source: const RectSource(x: -10, y: -5, width: 20, height: 10),
        appearance: CanvasAppearance(
          foreground: const CanvasFill.none(),
          stroke: CanvasStroke(color: 0xFF123456, width: 2, dash: [5, 0, 3]),
        ),
      ),
    ),
  ]),
);

Map<String, Object?> _data(Map<String, Object?> scene) {
  final node = (scene['children'] as List).single as Map<String, Object?>;
  return node['data'] as Map<String, Object?>;
}

Map<String, Object?> _stroke(Map<String, Object?> scene) {
  final appearance = _data(scene)['appearance'] as Map<String, Object?>;
  return appearance['stroke'] as Map<String, Object?>;
}

void main() {
  test(
    'v4 round trips all path sources and preserves authored dash arrays',
    () {
      final sources = <PathSource>[
        const RectSource(x: -10, y: -5, width: 20, height: 10),
        const RectSource(width: 20, height: 10, rx: 3),
        const CircleSource(10, cx: 2, cy: -3),
        const EllipseSource(10, 5, cx: -4),
        const LineSource(x1: -10, y1: 5, x2: 20, y2: 5),
        PolylineSource(const [Vec2.zero, Vec2(10, 0), Vec2(20, 10)]),
        PolygonSource(const [Vec2.zero, Vec2(10, 0), Vec2(20, 10)]),
        GeneralPathSource.fromSvg('M0 0L10 0Z M20 0L30 0'),
        GeneralPathSource(PathIR([])),
      ];
      for (final source in sources) {
        final scene = _scene([
          Node.path(
            id: 'path',
            data: PathData(
              source: source,
              fillRule: FillRule.evenOdd,
              appearance: CanvasAppearance(
                foreground: const CanvasFill.none(),
                stroke: CanvasStroke(
                  color: 0x00123456,
                  width: 12,
                  dash: [5, 0, 3],
                ),
              ),
            ),
          ),
        ]);
        final json = encodeCanvasScene(scene);
        expect(json['sceneFormatVersion'], 4);
        final restored = decodeCanvasScene(
          jsonDecode(jsonEncode(json)) as Map<String, Object?>,
        );
        expect(encodeCanvasScene(restored), json);
        expect(
          (restored.children.single as PathNode).data.appearance.stroke!.dash,
          [5, 0, 3],
        );
      }
    },
  );

  for (final field in [
    'points',
    'fill',
    'strokeColor',
    'strokeWidth',
    'strokeCap',
    'strokeJoin',
    'miterLimit',
    'dash',
  ]) {
    test('v4 rejects obsolete path field $field', () {
      final json = _wire();
      _data(json)[field] = null;
      expect(() => decodeCanvasScene(json), throwsFormatException);
    });
  }

  for (final field in ['source', 'appearance']) {
    test('v4 requires path $field and rejects explicit null', () {
      final missing = _wire();
      _data(missing).remove(field);
      expect(() => decodeCanvasScene(missing), throwsFormatException);
      final absent = _wire();
      _data(absent)[field] = null;
      expect(() => decodeCanvasScene(absent), throwsFormatException);
    });
  }

  test('v4 rejects unknown source kinds and invalid command structure', () {
    final unknown = _wire();
    _data(unknown)['source'] = {'kind': 'unknown'};
    expect(() => decodeCanvasScene(unknown), throwsFormatException);
    final invalid = _wire();
    _data(invalid)['source'] = {
      'kind': 'commands',
      'commands': [
        {
          'verb': 'lineTo',
          'p': {'x': 0, 'y': 0},
        },
      ],
    };
    expect(() => decodeCanvasScene(invalid), throwsFormatException);
  });

  test('source dimensions and primitive types are checked before use', () {
    final negative = _wire();
    _data(negative)['source'] = {'kind': 'circle', 'r': -1};
    expect(() => decodeCanvasScene(negative), throwsFormatException);
    final fractional = _wire();
    _data(fractional)['source'] = {
      'kind': 'rect',
      'width': 20,
      'height': 10,
      'x': '0',
    };
    expect(() => decodeCanvasScene(fractional), throwsFormatException);
  });

  test('v4 validates inactive stroke values without numeric coercion', () {
    final cases = <(String, Object?, Matcher)>[
      ('color', 1.5, isA<FormatException>()),
      ('color', -1, isA<ArgumentError>()),
      ('color', 0x100000000, isA<ArgumentError>()),
      ('width', '2', isA<FormatException>()),
      ('width', double.infinity, isA<ArgumentError>()),
      ('width', -1, isA<ArgumentError>()),
      ('miterLimit', 0.5, isA<ArgumentError>()),
      ('miterLimit', double.nan, isA<ArgumentError>()),
      ('cap', 'invalid', isA<FormatException>()),
      ('join', 'invalid', isA<FormatException>()),
    ];
    for (final (field, value, errorType) in cases) {
      final json = _wire();
      _stroke(json)['color'] = 0;
      _stroke(json)[field] = value;
      expect(() => decodeCanvasScene(json), throwsA(errorType));
    }
    for (final (value, errorType) in [
      (-1, isA<ArgumentError>()),
      (double.infinity, isA<ArgumentError>()),
      ('3', isA<FormatException>()),
    ]) {
      final json = _wire();
      _stroke(json)['color'] = 0;
      _stroke(json)['dash'] = [5, value];
      expect(() => decodeCanvasScene(json), throwsA(errorType));
    }
  });

  test('unsupported appearance combinations fail on both boundaries', () {
    final stroke = CanvasStroke(color: 0, width: 0);
    final invalid = _scene([
      Node.icon(
        id: 'icon',
        data: CanvasIconData(
          iconRef: 'symbol',
          appearance: CanvasAppearance(stroke: stroke),
        ),
      ),
    ]);
    expect(() => encodeCanvasScene(invalid), throwsArgumentError);
    final wire = encodeCanvasScene(
      _scene([
        const Node.text(
          id: 'text',
          data: TextData(
            text: 'A',
            fontFamily: 'Test',
            fontWeight: 400,
            fontSize: 16,
          ),
        ),
      ]),
    );
    final appearance = _data(wire)['appearance'] as Map<String, Object?>;
    appearance['stroke'] = {'color': 0, 'width': 0};
    expect(() => decodeCanvasScene(wire), throwsArgumentError);

    final path = _wire();
    final pathAppearance = _data(path)['appearance'] as Map<String, Object?>;
    pathAppearance['underlays'] = [
      {
        'type': 'shadow',
        'id': 's',
        'offset': {'x': 0, 'y': 0},
        'color': 0,
      },
    ];
    expect(() => decodeCanvasScene(path), throwsArgumentError);
  });

  test('rejects unknown fields including names containing slashes', () {
    for (final name in ['zzz', 'a~/b']) {
      final json = _wire();
      _data(json)[name] = true;
      expect(() => decodeCanvasScene(json), throwsFormatException);
    }
  });

  test('historical scenes require an explicit external upgrade', () {
    for (final version in [1, 2, 3]) {
      final old = _wire()..['sceneFormatVersion'] = version;
      expect(() => decodeCanvasScene(old), throwsFormatException);
    }
  });
}
