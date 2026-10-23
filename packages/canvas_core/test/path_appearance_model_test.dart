import 'dart:convert';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_core/src/serialization/path_converters.dart';
import 'package:canvas_core/src/adapters/path_compile_scene.dart';
import 'package:test/test.dart';

CanvasSceneDocument _scene(List<Node> children) => CanvasSceneDocument(
  backgroundFill: const CanvasFill.none(),
  backgroundOpacity: 1,
  children: children,
);

void main() {
  test('node defaults preserve their foreground and have no stroke', () {
    const path = PathData(source: RectSource(x: -10, y: -5, width: 20, height: 10));
    const text = TextData(
      text: 'A',
      fontFamily: 'Test',
      fontWeight: 400,
      fontSize: 16,
    );
    const icon = CanvasIconData(iconRef: 'test');

    expect(path.appearance.foreground, const CanvasFill.none());
    expect(path.appearance.stroke, isNull);
    expect(path.appearance.underlays, isEmpty);
    expect(text.appearance.foreground, const CanvasFill.solid(0xFF111111));
    expect(icon.appearance.foreground, text.appearance.foreground);
    expect(text.appearance.stroke, isNull);
    expect(icon.appearance.stroke, isNull);
  });

  test('path source conversion rejects null and non-object values', () {
    const converter = PathSourceConverter();
    for (final value in <Object?>[null, 'rect', 1, []]) {
      expect(() => converter.fromJson(value), throwsFormatException);
    }
    expect(() => PathData.fromJson({}), throwsFormatException);
    expect(() => PathData.fromJson({'source': null}), throwsFormatException);
  });

  test('path model JSON owns styling only through appearance', () {
    final path = PathData(
      source: const RectSource(x: -10, y: -5, width: 20, height: 10),
      fillRule: FillRule.evenOdd,
      appearance: CanvasAppearance(
        foreground: const CanvasFill.solid(0xFF123456),
        stroke: CanvasStroke(color: 0xFF654321, width: 2, dash: [5, 0, 3]),
      ),
    );
    final json = jsonDecode(jsonEncode(path.toJson())) as Map<String, dynamic>;

    expect(json.keys, unorderedEquals(['source', 'fillRule', 'appearance']));
    final restored = PathData.fromJson(json);
    expect(restored.source.toJson(), path.source.toJson());
    expect(restored.fillRule, path.fillRule);
    expect(restored.appearance, path.appearance);
  });

  test(
    'stroke copy and JSON preserve invisible configuration and odd dashes',
    () {
      final stroke = CanvasStroke(
        color: 0x00123456,
        width: 12,
        cap: StrokeCap.round,
        join: StrokeJoin.bevel,
        miterLimit: 6,
        dash: [5, 0, 3],
      );
      final restored = CanvasStroke.fromJson(
        jsonDecode(jsonEncode(stroke.toJson())) as Map<String, dynamic>,
      );

      expect(restored, stroke);
      expect(restored.dash, [5, 0, 3]);
      expect(restored.copyWith(color: 0xFF123456).width, 12);
      expect(restored.copyWith(color: 0xFF123456).cap, StrokeCap.round);
      expect(
        CanvasAppearance(stroke: stroke).copyWith(stroke: null).stroke,
        isNull,
      );
      expect(() => restored.dash.add(1), throwsUnsupportedError);
    },
  );

  test('stroke paint participation uses alpha and finite positive width', () {
    expect(strokeContributesToPaint(null), isFalse);
    for (final stroke in [
      CanvasStroke(color: 0x00123456, width: 2),
      CanvasStroke(color: 0xFF123456, width: 0),
      CanvasStroke(color: 0xFF123456, width: -1),
      CanvasStroke(color: 0xFF123456, width: double.nan),
      CanvasStroke(color: 0xFF123456, width: double.infinity),
      CanvasStroke(color: -1, width: 2),
    ]) {
      expect(strokeContributesToPaint(stroke), isFalse);
    }
    expect(
      strokeContributesToPaint(CanvasStroke(color: 0x01123456, width: 2)),
      isTrue,
    );
  });

  test('appearance and fill-rule edits reuse compiled source geometry', () {
    final source = GeneralPathSource(PathIR([
      PathCmd.moveTo(Vec2.zero),
      PathCmd.lineTo(const Vec2(10, 0)),
    ]));
    final plain = PathData(source: source);
    final painted = plain.copyWith(
      fillRule: FillRule.evenOdd,
      appearance: CanvasAppearance(
        foreground: const CanvasFill.solid(0xFF123456),
        stroke: CanvasStroke(color: 0xFF654321, width: 8),
      ),
    );

    expect(identical(compilePath(plain), compilePath(painted)), isTrue);
    final changed = plain.copyWith(source: const RectSource(x: -10, y: -5, width: 20, height: 10));
    expect(identical(compilePath(plain), compilePath(changed)), isFalse);
    expect(compilePath(changed).localBounds(), const Rect2D(-10, -5, 10, 5));
  });

  test(
    'polyline source freezes caller points',
    () {
      final points = <Vec2>[
        Vec2.zero,
        const Vec2(10, 0),
        const Vec2(20, 0),
        const Vec2(30, 0),
      ];
      final source = PolylineSource(points);
      final path = PathData(source: source);
      final compiled = compilePath(path);
      points.clear();

      expect(source.points, hasLength(4));
      expect(() => source.points.clear(), throwsUnsupportedError);
      expect(identical(compilePath(path.copyWith()), compiled), isTrue);
      expect(compiled.cmds.map((command) => command.verb), [
        PathVerb.moveTo,
        PathVerb.lineTo,
        PathVerb.lineTo,
        PathVerb.lineTo,
      ]);
      expect(
        compilePath(PathData(source: GeneralPathSource(PathIR([])))).cmds,
        isEmpty,
      );
    },
  );

  test('inactive stroke numerics are still rejected', () {
    for (final stroke in [
      CanvasStroke(color: 0, width: double.infinity),
      CanvasStroke(color: 0, width: -1),
      CanvasStroke(color: 0, miterLimit: 0.5),
      CanvasStroke(color: 0, miterLimit: double.nan),
      CanvasStroke(color: 0, dash: [double.nan]),
      CanvasStroke(color: 0, dash: [-1]),
      CanvasStroke(color: -1, width: 0),
    ]) {
      final scene = _scene([
        Node.path(
          id: 'path',
          data: PathData(
            source: const RectSource(x: -10, y: -5, width: 20, height: 10),
            appearance: CanvasAppearance(stroke: stroke),
          ),
        ),
      ]);
      expect(() => requireCanvasSceneIntegrity(scene), throwsArgumentError);
    }
  });

  test('node-specific appearance capabilities are enforced', () {
    final stroke = CanvasStroke(color: 0, width: 0);
    const shadow = ShadowEffect(id: 's', offset: Vec2.zero, color: 0xFF000000);
    final nodes = [
      Node.text(
        id: 'text',
        data: TextData(
          text: 'A',
          fontFamily: 'Test',
          fontWeight: 400,
          fontSize: 16,
          appearance: CanvasAppearance(stroke: stroke),
        ),
      ),
      Node.icon(
        id: 'icon',
        data: CanvasIconData(
          iconRef: 'test',
          appearance: CanvasAppearance(stroke: stroke),
        ),
      ),
      const Node.path(
        id: 'path',
        data: PathData(
          source: RectSource(x: -10, y: -5, width: 20, height: 10),
          appearance: CanvasAppearance(underlays: [shadow]),
        ),
      ),
    ];
    for (final node in nodes) {
      expect(
        () => requireCanvasSceneIntegrity(_scene([node])),
        throwsArgumentError,
      );
    }
  });
}
