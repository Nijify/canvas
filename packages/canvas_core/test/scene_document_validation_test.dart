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

const _textNode = TextNode(
  id: 'text',
  text: 'Hello',
  fontFamily: 'Inter',
  fontWeight: 400,
  fontSize: 16,
);

Node _text(
  String id, {
  String? name,
  Affine2D xf = const Affine2D.identity(),
}) => _textNode.copyWith(id: id, name: name, xf: xf);

Node _path(PathSource source) => Node.path(id: 'path', geometry: source);

void main() {
  test('accepts empty scenes and ordinary nested layers', () {
    for (final scene in [
      _scene(),
      _scene(
        children: [
          Node.group(id: 'group', children: [_text('text')]),
        ],
      ),
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
      [
        _text('duplicate'),
        Node.group(id: 'group', children: [_text('duplicate')]),
      ],
      [_text('text', name: List.filled(81, '😀').join())],
    ]) {
      expect(
        () => requireCanvasSceneIntegrity(_scene(children: nodes)),
        throwsArgumentError,
      );
    }
    expect(
      () => requireCanvasSceneIntegrity(
        _scene(children: [_text('text', name: List.filled(80, '😀').join())]),
      ),
      returnsNormally,
    );
  });

  test('retains path source numeric invariants', () {
    for (final source in [
      const CircleSource(-1),
      const CircleSource(double.infinity),
      const RectSource(x: 0.5, y: -5, width: -1, height: 10),
      const RectSource(
        x: -5,
        y: -(double.nan) / 2,
        width: 10,
        height: double.nan,
      ),
      const RectSource(x: -5, y: -5, width: 10, height: 10, rx: -1, ry: 0),
      const RectSource(
        x: -5,
        y: -5,
        width: 10,
        height: 10,
        rx: 0,
        ry: double.infinity,
      ),
      const RectSource(
        x: 0.5,
        y: -5,
        width: -1,
        height: 10,
        rx: (10) / 2,
        ry: (10) / 2,
      ),
      const RectSource(x: -5, y: 0.5, width: 10, height: -1),
      const EllipseSource(double.nan, 10),
      const LineSource(x1: double.nan),
      const CircleSource(10, cx: double.infinity),
      const RectSource(width: 1e308, height: 1, x: 1e308),
    ]) {
      expect(
        () => requireCanvasSceneIntegrity(_scene(children: [_path(source)])),
        throwsArgumentError,
      );
    }
  });

  test('checks text, icon, and image numerics', () {
    for (final node in [
      _textNode.copyWith(id: 'text', fontSize: double.nan),
      _textNode.copyWith(id: 'text', letterSpacing: double.infinity),
      const Node.icon(id: 'icon', iconRef: 'symbol', sizePx: 0),
      const Node.icon(id: 'icon', iconRef: 'symbol', sizePx: double.infinity),
      const Node.image(id: 'image', size: Size2D(-1, 10)),
      const Node.image(id: 'image', size: Size2D(10, 0)),
      const Node.image(
        id: 'image',
        size: Size2D(10, 10),
        align: Vec2(-0.1, 0.5),
      ),
      const Node.image(
        id: 'image',
        size: Size2D(10, 10),
        align: Vec2(0.5, 1.1),
      ),
    ]) {
      expect(
        () => requireCanvasSceneIntegrity(_scene(children: [node])),
        throwsArgumentError,
      );
    }
  });

  test('rejects node cycles before recursive encoding', () {
    final children = <Node>[];
    final group = Node.group(id: 'group', children: children);
    children.add(group);
    final scene = _scene(children: [group]);
    expect(() => requireCanvasSceneIntegrity(scene), throwsArgumentError);
    expect(() => encodeCanvasScene(scene), throwsArgumentError);
  });

  test('rejects contradictory labels from all generated node constructors', () {
    final variants = <(String, Node Function(String?))>[
      (
        'text',
        (label) => TextNode(
          id: 'text',
          text: 'Hello',
          fontFamily: 'Inter',
          fontWeight: 400,
          fontSize: 16,
          $type: label,
        ),
      ),
      (
        'image',
        (label) => ImageNode(id: 'image', size: Size2D(10, 10), $type: label),
      ),
      (
        'path',
        (label) => PathNode(
          id: 'path',
          geometry: RectSource(x: -5, y: -5, width: 10, height: 10),
          $type: label,
        ),
      ),
      (
        'icon',
        (label) => IconNode(id: 'icon', iconRef: 'symbol', $type: label),
      ),
      ('group', (label) => GroupNode(id: 'group', $type: label)),
    ];
    for (final (expected, build) in variants) {
      for (final label in [null, expected]) {
        final scene = _scene(children: [build(label)]);
        final wire = encodeCanvasScene(scene);
        expect(((wire['children'] as List).single as Map)['type'], expected);
        final restored = decodeCanvasScene(
          jsonDecode(jsonEncode(wire)) as Map<String, Object?>,
        );
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
