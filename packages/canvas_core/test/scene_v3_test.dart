import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

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
        source: const RectSource(20, 10),
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

Map<String, Object?> _fixture(String name) {
  final runtime = Isolate.resolvePackageUriSync(
    Uri.parse('package:canvas_core/canvas_core_runtime.dart'),
  )!;
  final root = File.fromUri(runtime).parent.parent;
  return jsonDecode(
        File.fromUri(
          root.uri.resolve('test/fixtures/scene_migration/$name'),
        ).readAsStringSync(),
      )
      as Map<String, Object?>;
}

List<Map<String, Object?>> _nested(Map<String, Object?> scene) {
  final group = (scene['children'] as List).single as Map<String, Object?>;
  return (group['children'] as List).cast<Map<String, Object?>>();
}

void main() {
  test(
    'v3 round trips all path sources and preserves authored dash arrays',
    () {
      final sources = <PathSource>[
        const RectSource(20, 10),
        const RoundRectSource(20, 10, 2, 3),
        const PillSource(20, 10),
        const UnderlineSource(20, 2),
        const EllipseSource(10, 5),
        const CircleSource(10),
        const RegularPolygonSource(5, 10, rotation: 30),
        const StarSource(5, 10, 5, rotation: 30),
        PolylineSource(const [Vec2.zero, Vec2(10, 0), null, Vec2(20, 10)]),
        CommandPathSource([
          PathCmd.moveTo(Vec2.zero),
          PathCmd.quadTo(const Vec2(5, 10), const Vec2(10, 0)),
          PathCmd.close(),
          PathCmd.moveTo(const Vec2(20, 0)),
          PathCmd.lineTo(const Vec2(30, 0)),
        ]),
        CommandPathSource([]),
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
        expect(json['sceneFormatVersion'], 3);
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
    test('v3 rejects obsolete path field $field', () {
      final json = _wire();
      _data(json)[field] = null;
      expect(
        () => decodeCanvasScene(json),
        throwsFormatException,
      );
    });
  }

  for (final field in ['source', 'appearance']) {
    test('v3 requires path $field and rejects explicit null', () {
      final missing = _wire();
      _data(missing).remove(field);
      expect(
        () => decodeCanvasScene(missing),
        throwsFormatException,
      );
      final absent = _wire();
      _data(absent)[field] = null;
      expect(
        () => decodeCanvasScene(absent),
        throwsFormatException,
      );
    });
  }

  test('v3 rejects unknown source kinds and invalid command structure', () {
    final unknown = _wire();
    _data(unknown)['source'] = {'kind': 'unknown'};
    expect(
      () => decodeCanvasScene(unknown),
      throwsFormatException,
    );
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
    expect(
      () => decodeCanvasScene(invalid),
      throwsFormatException,
    );
  });

  test('source semantics and integer parameters are checked before use', () {
    final negative = _wire();
    _data(negative)['source'] = {'kind': 'circle', 'r': -1};
    expect(
      () => decodeCanvasScene(negative),
      throwsArgumentError,
    );
    final fractional = _wire();
    _data(fractional)['source'] = {
      'kind': 'regularPolygon',
      'sides': 3.5,
      'r': 10,
    };
    expect(
      () => decodeCanvasScene(fractional),
      throwsFormatException,
    );
  });

  test('v3 validates inactive stroke values without numeric coercion', () {
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
      expect(
        () => decodeCanvasScene(json),
        throwsA(errorType),
      );
    }
    for (final (value, errorType) in [
      (-1, isA<ArgumentError>()),
      (double.infinity, isA<ArgumentError>()),
      ('3', isA<FormatException>()),
    ]) {
      final json = _wire();
      _stroke(json)['color'] = 0;
      _stroke(json)['dash'] = [5, value];
      expect(
        () => decodeCanvasScene(json),
        throwsA(errorType),
      );
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
    expect(
      () => encodeCanvasScene(invalid),
      throwsArgumentError,
    );
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
    expect(
      () => decodeCanvasScene(wire),
      throwsArgumentError,
    );

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
    expect(
      () => decodeCanvasScene(path),
      throwsArgumentError,
    );
  });

  test('rejects unknown fields including names containing slashes', () {
    for (final name in ['zzz', 'a~/b']) {
      final json = _wire();
      _data(json)[name] = true;
      expect(() => decodeCanvasScene(json), throwsFormatException);
    }
  });

  test('command decoding rejects malformed structure without coercion or ignored fields', () {
    for (final commands in <Object?>[
      null,
      'M0 0',
      [{'verb': 'unknown'}],
      [{'verb': 'moveTo', 'p': {'x': '0', 'y': 0}}],
      [{'verb': 'moveTo', 'p': {'x': double.infinity, 'y': 0}}],
      [{'verb': 'moveTo', 'p': {'x': 0, 'y': 0, 'extra': 1}}],
      [{'verb': 'moveTo', 'p': {'x': 0, 'y': 0}, 'extra': 1}],
      [{'verb': 'moveTo'}],
      [{'verb': 'lineTo', 'p': {'x': 0, 'y': 0}}],
      [
        {'verb': 'moveTo', 'p': {'x': 0, 'y': 0}},
        {'verb': 'quadTo', 'p': {'x': 1, 'y': 1}},
      ],
      [
        {'verb': 'moveTo', 'p': {'x': 0, 'y': 0}},
        {'verb': 'cubicTo', 'c1': {'x': 1, 'y': 1}, 'p': {'x': 2, 'y': 2}},
      ],
      [
        {'verb': 'moveTo', 'p': {'x': 0, 'y': 0}},
        {'verb': 'close', 'p': {'x': 0, 'y': 0}},
      ],
      [
        {'verb': 'moveTo', 'p': {'x': 0, 'y': 0}},
        {'verb': 'close'},
        {'verb': 'lineTo', 'p': {'x': 1, 'y': 1}},
      ],
    ]) {
      final json = _wire();
      _data(json)['source'] = {'kind': 'commands', 'commands': commands};
      expect(() => decodeCanvasScene(json), throwsFormatException);
    }
  });

  test('v2 fixture migrates without mutation or shared containers', () {
    final v2 = _fixture('v2_paths.json');
    final before = jsonEncode(v2);
    final upgraded = upgradeCanvasScene(v2);
    expect(upgraded, _fixture('v3_paths.json'));
    expect(jsonEncode(v2), before);
    final canonical = encodeCanvasScene(decodeCanvasScene(upgraded));
    expect(encodeCanvasScene(decodeCanvasScene(canonical)), canonical);

    final children = _nested(upgraded);
    final points = children[1]['data'] as Map<String, Object?>;
    final source = points['source'] as Map<String, Object?>;
    (source['points'] as List).clear();
    final asset = (upgraded['assets'] as Map)['asset'] as Map;
    asset['sourceRef'] = 'changed';
    expect(jsonEncode(v2), before);
  });

  test(
    'v2 rejects invalid inactive metadata and malformed selected geometry',
    () {
      final v2 = _fixture('v2_paths.json');
      final inactive = _nested(v2)[3]['data'] as Map<String, Object?>;
      inactive['dash'] = [5, -1];
      expect(
        () => upgradeCanvasScene(v2),
        throwsArgumentError,
      );
      inactive['dash'] = [];
      inactive['miterLimit'] = double.infinity;
      expect(
        () => upgradeCanvasScene(v2),
        throwsArgumentError,
      );
      inactive.remove('miterLimit');
      final selected = _nested(v2)[0]['data'] as Map<String, Object?>;
      selected['source'] = {'kind': 'unknown'};
      expect(
        () => upgradeCanvasScene(v2),
        throwsFormatException,
      );
    },
  );

  test(
    'historical versions require explicit upgrade and unknown versions fail',
    () {
      final old = _fixture('v2_paths.json');
      expect(
        () => decodeCanvasScene(old),
        throwsFormatException,
      );
      for (final version in <Object?>[null, 1.0, 3.0, 99]) {
        final json = _wire()..['sceneFormatVersion'] = version;
        expect(() => upgradeCanvasScene(json), throwsFormatException);
      }
    },
  );
}
