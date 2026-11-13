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
      geometry: const RectSource(x: -10, y: -5, width: 20, height: 10),
      appearance: CanvasAppearance(
        foreground: const CanvasFill.none(),
        stroke: CanvasStroke(color: 0xFF123456, width: 2, dash: [5, 0, 3]),
      ),
    ),
  ]),
);

Map<String, Object?> _node(Map<String, Object?> scene) {
  return (scene['children'] as List).single as Map<String, Object?>;
}

Map<String, Object?> _stroke(Map<String, Object?> scene) {
  final appearance = _node(scene)['appearance'] as Map<String, Object?>;
  return appearance['stroke'] as Map<String, Object?>;
}

void main() {
  test('v7 rejects host and visibility fields on every node kind', () {
    final nodes = <Node>[
      const Node.group(id: 'group'),
      const Node.text(
        id: 'text',
        text: '',
        fontFamily: 'Inter',
        fontWeight: 400,
        fontSize: 16,
      ),
      const Node.image(id: 'image', size: Size2D(20, 10)),
      const Node.icon(id: 'icon', iconRef: 'symbol'),
      Node.path(id: 'path', geometry: const CircleSource(5)),
    ];
    for (final node in nodes) {
      for (final field in ['hidden', 'role', 'behavior']) {
        final wire = encodeCanvasScene(_scene([node]));
        _node(wire)[field] = null;
        expect(() => decodeCanvasScene(wire), throwsFormatException);
      }
    }
    final old = _wire()..['sceneFormatVersion'] = 6;
    expect(() => decodeCanvasScene(old), throwsFormatException);
  });

  test('v7 requires explicit artboard dimensions and omits empty assets', () {
    final wire = _wire();
    expect(wire.containsKey('assets'), isFalse);
    wire.remove('artboardSize');
    expect(() => decodeCanvasScene(wire), throwsFormatException);
  });

  test('v7 omits node defaults and retains explicit authored settings', () {
    final scene = _scene([
      Node.group(
        id: 'group',
        children: [
          const Node.text(
            id: 'text',
            text: 'Hello',
            fontFamily: 'Inter',
            fontWeight: 400,
            fontSize: 16,
          ),
          const Node.image(id: 'image', size: Size2D(20, 10)),
          const Node.icon(id: 'icon', iconRef: 'symbol'),
          Node.path(
            id: 'path',
            geometry: const CircleSource(5),

            appearance: CanvasAppearance(
              foreground: const CanvasFill.none(),
              stroke: CanvasStroke(color: 0, width: 0),
            ),
          ),
        ],
      ),
    ]);
    final wire = encodeCanvasScene(scene);
    final group = _node(wire);
    expect(group.keys, unorderedEquals(['type', 'id', 'children']));
    final children = (group['children'] as List).cast<Map<String, Object?>>();
    expect(
      children[0].keys,
      unorderedEquals([
        'type',
        'id',
        'text',
        'fontFamily',
        'fontWeight',
        'fontSize',
        'appearance',
      ]),
    );
    expect(children[1], {
      'type': 'image',
      'id': 'image',
      'size': {'w': 20, 'h': 10},
    });
    expect(
      children[2].keys,
      unorderedEquals(['type', 'id', 'iconRef', 'appearance']),
    );
    expect(children[3].containsKey('hidden'), isFalse);
    expect(children[3].containsKey('fillRule'), isFalse);
    expect(children[3]['appearance'], {
      'foreground': {'type': 'none'},
      'stroke': {'color': 0, 'width': 0},
    });
    expect(encodeCanvasScene(decodeCanvasScene(wire)), wire);
  });

  test('v7 preserves nondefault image alignment and fit', () {
    const image = ImageNode(
      id: 'image',
      size: Size2D(20, 10),
      fit: ImageFit.cover,
      align: Vec2(0.25, 0.75),
    );
    final wire = encodeCanvasScene(_scene([image]));
    expect(decodeCanvasScene(wire).children.single, image);
  });

  test(
    'v7 round trips all path sources and preserves authored dash arrays',
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
            geometry: source,
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
        ]);
        final json = encodeCanvasScene(scene);
        expect(json['sceneFormatVersion'], 7);
        final restored = decodeCanvasScene(
          jsonDecode(jsonEncode(json)) as Map<String, Object?>,
        );
        expect(encodeCanvasScene(restored), json);
        expect((restored.children.single as PathNode).appearance.stroke!.dash, [
          5,
          0,
          3,
        ]);
      }
    },
  );

  for (final field in [
    'hidden',
    'role',
    'behavior',
    'points',
    'runtimeType',
    'data',
    'source',
    'fill',
    'strokeColor',
    'strokeWidth',
    'strokeCap',
    'strokeJoin',
    'miterLimit',
    'dash',
  ]) {
    test('v7 rejects obsolete path field $field', () {
      final json = _wire();
      _node(json)[field] = null;
      expect(() => decodeCanvasScene(json), throwsFormatException);
    });
  }

  for (final field in ['geometry', 'appearance']) {
    test('v7 requires path $field and rejects explicit null', () {
      final missing = _wire();
      _node(missing).remove(field);
      expect(() => decodeCanvasScene(missing), throwsFormatException);
      final absent = _wire();
      _node(absent)[field] = null;
      expect(() => decodeCanvasScene(absent), throwsFormatException);
    });
  }

  test('v7 rejects unknown source kinds and invalid command structure', () {
    final unknown = _wire();
    _node(unknown)['geometry'] = {'kind': 'unknown'};
    expect(() => decodeCanvasScene(unknown), throwsFormatException);
    final invalid = _wire();
    _node(invalid)['geometry'] = {
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
    _node(negative)['geometry'] = {'kind': 'circle', 'r': -1};
    expect(() => decodeCanvasScene(negative), throwsFormatException);
    final fractional = _wire();
    _node(fractional)['geometry'] = {
      'kind': 'rect',
      'width': 20,
      'height': 10,
      'x': '0',
    };
    expect(() => decodeCanvasScene(fractional), throwsFormatException);
  });

  test('v7 validates inactive stroke values without numeric coercion', () {
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
        iconRef: 'symbol',
        appearance: CanvasAppearance(stroke: stroke),
      ),
    ]);
    expect(() => encodeCanvasScene(invalid), throwsArgumentError);
    final wire = encodeCanvasScene(
      _scene([
        const Node.text(
          id: 'text',
          text: 'A',
          fontFamily: 'Test',
          fontWeight: 400,
          fontSize: 16,
        ),
      ]),
    );
    final appearance = _node(wire)['appearance'] as Map<String, Object?>;
    appearance['stroke'] = {'color': 0, 'width': 0};
    expect(() => decodeCanvasScene(wire), throwsArgumentError);

    final path = _wire();
    final pathAppearance = _node(path)['appearance'] as Map<String, Object?>;
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
      _node(json)[name] = true;
      expect(() => decodeCanvasScene(json), throwsFormatException);
    }
  });

  test('historical scenes require an explicit external upgrade', () {
    for (final version in [1, 2, 3, 4, 5]) {
      final old = _wire()..['sceneFormatVersion'] = version;
      expect(() => decodeCanvasScene(old), throwsFormatException);
    }
  });
}
