import 'dart:convert';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_core/src/path/path_compile.dart';
import 'package:canvas_core/src/adapters/path_compile_scene.dart';
import 'package:test/test.dart';

List<PathCmd> _commands() => [
  PathCmd.moveTo(const Vec2(10, 20)),
  PathCmd.lineTo(const Vec2(50, 20)),
  PathCmd.quadTo(const Vec2(70, 20), const Vec2(70, 40)),
  PathCmd.cubicTo(const Vec2(70, 60), const Vec2(50, 80), const Vec2(10, 80)),
  PathCmd.close(),
  // Oppositely wound inner contour; preserve its order and explicit closure.
  PathCmd.moveTo(const Vec2(20, 30)),
  PathCmd.lineTo(const Vec2(20, 40)),
  PathCmd.lineTo(const Vec2(30, 40)),
  PathCmd.lineTo(const Vec2(30, 30)),
  PathCmd.close(),
  // An open contour must stay open.
  PathCmd.moveTo(const Vec2(90, 100)),
  PathCmd.lineTo(const Vec2(110, 120)),
];

CanvasSceneDocument _scene(CommandPathSource source) => CanvasSceneDocument(
  artboardSize: const Size2D(160, 160),
  backgroundFill: const CanvasFill.none(),
  backgroundOpacity: 1,
  children: [
    Node.path(
      id: 'commands',
      data: PathData(
        source: source,
        appearance: const CanvasAppearance(
          foreground: CanvasFill.solid(0xff123456),
        ),
        fillRule: FillRule.evenOdd,
      ),
    ),
  ],
);

void main() {
  test('raw SVG source decoding requires prepared commands', () {
    expect(
      () => PathSource.fromJson({'kind': 'svg', 'd': 'M0 0L24 0L24 24Z'}),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Normalize to a commands source'),
        ),
      ),
    );
  });

  group('CommandPathSource', () {
    test('snapshots commands and exposes an unmodifiable list', () {
      final commands = _commands();
      final source = CommandPathSource(commands);
      final original = source.toJson();
      commands.clear();

      expect(source.commands, hasLength(12));
      expect(source.toJson(), original);
      expect(() => source.commands.clear(), throwsUnsupportedError);
      expect(
        () => source.commands.add(PathCmd.close()),
        throwsUnsupportedError,
      );

      final json = source.toJson();
      (json['commands'] as List).clear();
      expect(source.toJson(), original);
    });

    test('compiles without fitting, flattening, or changing contour order', () {
      final commands = _commands();
      final source = CommandPathSource(commands);
      const compiler = PathCompiler();
      final plain = compiler.fromSource(source);
      final painted = compilePath(
        PathData(
          source: source,
          appearance: const CanvasAppearance(
            foreground: CanvasFill.solid(0xffabcdef),
            stroke: CanvasStroke(color: 0xff123456, width: 8),
          ),
          fillRule: FillRule.evenOdd,
        ),
      );

      expect(plain.cmds, orderedEquals(commands));
      expect(painted.cmds, orderedEquals(commands));
      expect(plain.localBounds(), Rect2D.fromLTRB(10, 20, 110, 120));
      expect(painted.localBounds(), plain.localBounds());
      expect(plain.cmds.last.verb, PathVerb.lineTo);
      expect(() => plain.cmds.clear(), throwsUnsupportedError);
      expect(source.toJson().keys, unorderedEquals(['kind', 'commands']));
    });

    test('round-trips every verb through JSON and the scene boundary', () {
      final source = CommandPathSource(_commands());
      final wire =
          jsonDecode(jsonEncode(source.toJson())) as Map<String, dynamic>;
      final restored = PathSource.fromJson(wire) as CommandPathSource;
      expect(restored.toJson(), source.toJson());
      expect((restored.toJson()['commands'] as List)[4], {'verb': 'close'});

      final sceneJson = encodeCanvasScene(_scene(source));
      final decoded = decodeCanvasScene(
        jsonDecode(jsonEncode(sceneJson)) as Map<String, dynamic>,
      );
      final data = (decoded.children.single as PathNode).data;
      expect(data.source, isA<CommandPathSource>());
      expect(data.source.toJson(), source.toJson());
      expect(data.fillRule, FillRule.evenOdd);
      expect(encodeCanvasScene(decoded), sceneJson);
      expect(validateCanvasSceneDocument(decoded), isEmpty);
    });

    test('accepts empty, move-only, and open contours', () {
      for (final commands in <List<PathCmd>>[
        [],
        [PathCmd.moveTo(Vec2.zero)],
        [PathCmd.moveTo(Vec2.zero), PathCmd.lineTo(const Vec2(1, 2))],
        [PathCmd.moveTo(Vec2.zero), PathCmd.moveTo(const Vec2(1, 2))],
      ]) {
        final source = CommandPathSource(commands);
        expect(PathSource.fromJson(source.toJson()).toJson(), source.toJson());
      }
    });

    test('rejects drawing or closure without an active contour', () {
      for (final commands in <List<PathCmd>>[
        [PathCmd.lineTo(Vec2.zero)],
        [PathCmd.close()],
        [PathCmd.moveTo(Vec2.zero), PathCmd.close(), PathCmd.close()],
        [
          PathCmd.moveTo(Vec2.zero),
          PathCmd.close(),
          PathCmd.lineTo(const Vec2(1, 2)),
        ],
      ]) {
        expect(() => CommandPathSource(commands), throwsArgumentError);
      }
      for (final tail in <Map<String, Object?>>[
        {
          'verb': 'lineTo',
          'p': {'x': 1, 'y': 2},
        },
        {'verb': 'close'},
      ]) {
        expect(
          () => PathSource.fromJson({
            'kind': 'commands',
            'commands': [tail],
          }),
          throwsFormatException,
        );
        expect(
          () => PathSource.fromJson({
            'kind': 'commands',
            'commands': [
              {
                'verb': 'moveTo',
                'p': {'x': 0, 'y': 0},
              },
              {'verb': 'close'},
              tail,
            ],
          }),
          throwsFormatException,
        );
      }
    });

    test('rejects nonfinite endpoints and curve controls at construction', () {
      for (final invalid in [double.nan, double.infinity, -double.infinity]) {
        for (final point in [Vec2(invalid, 0), Vec2(0, invalid)]) {
          for (final command in [
            PathCmd.moveTo(point),
            PathCmd.lineTo(point),
            PathCmd.quadTo(point, Vec2.zero),
            PathCmd.quadTo(Vec2.zero, point),
            PathCmd.cubicTo(point, Vec2.zero, Vec2.zero),
            PathCmd.cubicTo(Vec2.zero, point, Vec2.zero),
            PathCmd.cubicTo(Vec2.zero, Vec2.zero, point),
          ]) {
            expect(
              () => CommandPathSource([PathCmd.moveTo(Vec2.zero), command]),
              throwsArgumentError,
            );
          }
        }
      }
    });

    test('rejects malformed or noncanonical command JSON', () {
      final invalid = <Map<String, Object?>>[
        {'kind': 'commands'},
        {'kind': 'commands', 'commands': null},
        {'kind': 'commands', 'commands': {}},
        {'kind': 'commands', 'commands': [], 'fillRule': 'evenOdd'},
        for (final command in <Object?>[
          null,
          [],
          {},
          {'verb': 'arcTo'},
          {'verb': true},
          {'verb': 'moveTo'},
          {
            'verb': 'moveTo',
            'p': {'x': 0},
          },
          {
            'verb': 'moveTo',
            'p': {'x': 0, 'y': 0, 'z': 0},
          },
          {
            'verb': 'moveTo',
            'p': {'x': true, 'y': 0},
          },
          {
            'verb': 'moveTo',
            'p': {'x': '0', 'y': 0},
          },
          {
            'verb': 'moveTo',
            'p': {'x': double.nan, 'y': 0},
          },
          {
            'verb': 'moveTo',
            'p': {'x': double.infinity, 'y': 0},
          },
          {
            'verb': 'quadTo',
            'p': {'x': 0, 'y': 0},
          },
          {
            'verb': 'cubicTo',
            'c1': {'x': 0, 'y': 0},
            'p': {'x': 0, 'y': 0},
          },
          {
            'verb': 'close',
            'p': {'x': 0, 'y': 0},
          },
          {
            'verb': 'lineTo',
            'p': {'x': 0, 'y': 0},
            'stroke': 1,
          },
        ])
          {
            'kind': 'commands',
            'commands': [
              {
                'verb': 'moveTo',
                'p': {'x': 0, 'y': 0},
              },
              command,
            ],
          },
      ];
      for (final json in invalid) {
        expect(() => PathSource.fromJson(json), throwsFormatException);
      }
    });

    test('scene decoding rejects malformed nested command sources', () {
      final json = encodeCanvasScene(_scene(CommandPathSource(_commands())));
      final node = (json['children'] as List).single as Map<String, dynamic>;
      final data = node['data'] as Map<String, dynamic>;
      data['source'] = {
        'kind': 'commands',
        'commands': [
          {'verb': 'close'},
        ],
      };
      expect(() => decodeCanvasScene(json), throwsFormatException);
    });
  });
}
