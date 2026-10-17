import 'dart:convert';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

CanvasSceneDocument _scene({
  Size2D artboardSize = const Size2D(740, 360),
  CanvasFill backgroundFill = const CanvasFill.none(),
  double backgroundOpacity = 1,
  List<Node> children = const [],
}) => CanvasSceneDocument(
  artboardSize: artboardSize,
  backgroundFill: backgroundFill,
  backgroundOpacity: backgroundOpacity,
  children: children,
);

TextData _textData() => const TextData(
  text: 'Hello', fontFamily: 'Inter', fontWeight: 400, fontSize: 16,
);

Node _text(String id, {String? name, Transform2D xf = const Transform2D()}) =>
    Node.text(id: id, name: name, xf: xf, data: _textData());

Node _path(PathSource source) => Node.path(
  id: 'path', data: PathData(source: source),
);

Node _behavior(Map<String, dynamic> data, {String type = 'future', int version = 1}) =>
    Node.group(id: 'group', behavior: GroupBehaviorRef(
      type: type, version: version, data: data,
    ));

void main() {
  test('accepts empty scenes and unknown well-formed behavior payloads', () {
    for (final scene in [
      _scene(),
      _scene(children: [
        _text('text', xf: const Transform2D(origin: OriginKind.custom)),
        _behavior({'nested': [null, true, 3, 0.5, {'label': 'future'}]}, version: 999),
      ]),
    ]) {
      expect(() => requireCanvasSceneIntegrity(scene), returnsNormally);
      final json = encodeCanvasScene(scene);
      expect(encodeCanvasScene(decodeCanvasScene(json)), json);
    }
  });

  test('rejects invalid document dimensions, opacity, and colors', () {
    for (final scene in [
      _scene(artboardSize: const Size2D(0, 360)),
      _scene(artboardSize: const Size2D(740, double.infinity)),
      _scene(backgroundOpacity: -0.1),
      _scene(backgroundOpacity: 1.1),
      _scene(backgroundOpacity: double.nan),
      _scene(backgroundFill: const CanvasFill.solid(-1)),
      _scene(backgroundFill: const CanvasFill.solid(0x100000000)),
    ]) {
      expect(() => requireCanvasSceneIntegrity(scene), throwsArgumentError);
      expect(() => encodeCanvasScene(scene), throwsArgumentError);
    }
  });

  test('rejects blank and nested duplicate IDs and oversized names', () {
    for (final nodes in [
      [_text(' ')],
      [_text('duplicate'), Node.group(id: 'group', children: [_text('duplicate')])],
      [_text('text', name: List.filled(81, '😀').join())],
    ]) {
      expect(() => requireCanvasSceneIntegrity(_scene(children: nodes)), throwsArgumentError);
    }
    expect(() => requireCanvasSceneIntegrity(_scene(children: [
      _text('text', name: List.filled(80, '😀').join()),
    ])), returnsNormally);
  });

  test('checks every transform coordinate and optional custom pivots', () {
    for (final xf in const [
      Transform2D(position: Vec2(double.nan, 0)),
      Transform2D(position: Vec2(0, double.infinity)),
      Transform2D(rotationRad: double.infinity),
      Transform2D(scale: Vec2(double.nan, 1)),
      Transform2D(scale: Vec2(1, double.infinity)),
      Transform2D(customPivotPx: Vec2(double.nan, 0)),
      Transform2D(customPivotPx: Vec2(0, double.infinity)),
    ]) {
      expect(() => requireCanvasSceneIntegrity(_scene(children: [_text('text', xf: xf)])), throwsArgumentError);
    }
  });

  test('retains path source numeric invariants', () {
    for (final source in [
      const CircleSource(-1), const CircleSource(double.infinity),
      const RectSource(-1, 10), const RectSource(10, double.nan),
      const RoundRectSource(10, 10, -1, 0),
      const RoundRectSource(10, 10, 0, double.infinity),
      const PillSource(-1, 10), const UnderlineSource(10, -1),
      const EllipseSource(double.nan, 10),
      const RegularPolygonSource(2, 10),
      const RegularPolygonSource(3, -1),
      const RegularPolygonSource(3, 10, rotation: double.infinity),
      const StarSource(2, 10, 5), const StarSource(5, -1, 0),
      const StarSource(5, 10, -1), const StarSource(5, 10, 11),
      const StarSource(5, 10, 5, rotation: double.nan),
      PolylineSource(const [Vec2(double.nan, 0)]),
      PolylineSource(const [null, Vec2(0, double.infinity)]),
    ]) {
      expect(() => requireCanvasSceneIntegrity(_scene(children: [_path(source)])), throwsArgumentError);
    }
  });

  test('checks text, icon, and image numerics', () {
    for (final node in [
      Node.text(id: 'text', data: _textData().copyWith(fontSize: double.nan)),
      Node.text(id: 'text', data: _textData().copyWith(letterSpacing: double.infinity)),
      const Node.icon(id: 'icon', data: CanvasIconData(iconRef: 'symbol', sizePx: 0)),
      const Node.icon(id: 'icon', data: CanvasIconData(iconRef: 'symbol', sizePx: double.infinity)),
      const Node.image(id: 'image', data: ImageData(size: Size2D(-1, 10))),
      const Node.image(id: 'image', data: ImageData(size: Size2D(10, 0))),
      const Node.image(id: 'image', data: ImageData(size: Size2D(10, 10), align: Vec2(-0.1, 0.5))),
      const Node.image(id: 'image', data: ImageData(size: Size2D(10, 10), align: Vec2(0.5, 1.1))),
    ]) {
      expect(() => requireCanvasSceneIntegrity(_scene(children: [node])), throwsArgumentError);
    }
  });

  test('checks the behavior envelope and recursively rejects non-JSON data', () {
    for (final node in [
      _behavior({}, type: ' '), _behavior({}, version: 0),
      _behavior({'value': Object()}),
      _behavior({'value': double.infinity}),
      _behavior({'nested': [double.nan]}),
      _behavior({'nested': <Object, Object>{1: true}}),
    ]) {
      final scene = _scene(children: [node]);
      expect(() => requireCanvasSceneIntegrity(scene), throwsArgumentError);
      expect(() => encodeCanvasScene(scene), throwsArgumentError);
    }
  });

  test('rejects map, list, and node cycles before recursive encoding', () {
    final map = <String, dynamic>{};
    map['self'] = map;
    final list = <Object?>[];
    list.add(list);
    final children = <Node>[];
    final group = Node.group(id: 'group', children: children);
    children.add(group);
    for (final scene in [
      _scene(children: [_behavior(map)]),
      _scene(children: [_behavior({'list': list})]),
      _scene(children: [group]),
    ]) {
      expect(() => requireCanvasSceneIntegrity(scene), throwsArgumentError);
      expect(() => encodeCanvasScene(scene), throwsArgumentError);
    }
  });

  test('rejects contradictory labels from all generated node constructors', () {
    final variants = <(String, Node Function(String?))>[
      ('text', (label) => TextNode(id: 'text', data: _textData(), $type: label)),
      ('image', (label) => ImageNode(id: 'image', data: const ImageData(size: Size2D(10, 10)), $type: label)),
      ('path', (label) => PathNode(id: 'path', data: const PathData(source: RectSource(10, 10)), $type: label)),
      ('icon', (label) => IconNode(id: 'icon', data: const CanvasIconData(iconRef: 'symbol'), $type: label)),
      ('group', (label) => GroupNode(id: 'group', $type: label)),
    ];
    for (final (expected, build) in variants) {
      for (final label in [null, expected]) {
        final scene = _scene(children: [build(label)]);
        final wire = encodeCanvasScene(scene);
        expect(((wire['children'] as List).single as Map)['runtimeType'], expected);
        final restored = decodeCanvasScene(jsonDecode(jsonEncode(wire)) as Map<String, Object?>);
        expect(encodeCanvasScene(restored), wire);
      }
      for (final label in ['unknown', expected == 'text' ? 'path' : 'text']) {
        final scene = _scene(children: [build(label)]);
        expect(() => requireCanvasSceneIntegrity(scene), throwsArgumentError);
        expect(() => encodeCanvasScene(scene), throwsArgumentError);
      }
    }
  });
}
