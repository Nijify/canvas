import 'dart:convert';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

const _shadow = ShadowEffect(
  id: 's',
  offset: Vec2(10, -6),
  blurSigma: 2,
  color: 0x80446688,
);

CanvasSceneDocument _scene(
  List<CanvasSourceUnderlay> underlays, {
  CanvasFill foreground = const CanvasFill.solid(0xFF111111),
}) {
  final appearance = CanvasAppearance(
    foreground: foreground,
    underlays: underlays,
  );

  return CanvasSceneDocument(
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1,
    children: [
      Node.text(
        id: 'text',
        data: TextData(
          text: 'X',
          fontFamily: 'Ahem',
          fontWeight: 400,
          fontSize: 24,
          appearance: appearance,
        ),
      ),
      Node.icon(
        id: 'icon',
        data: CanvasIconData(iconRef: 'test', appearance: appearance),
      ),
    ],
  );
}

void main() {
  test('default appearance preserves visible foreground', () {
    const appearance = CanvasAppearance();

    expect(appearance.foreground, const CanvasFill.solid(0xFF111111));
    expect(appearance.underlays, isEmpty);
  });

  test('appearance JSON uses source-underlay discriminator', () {
    final scene = _scene([
      _shadow,
      _shadow.copyWith(id: 'disabled', enabled: false),
    ]);

    final encoded = jsonEncode(scene.toJson());

    expect(encoded, contains('"type":"shadow"'));

    final decoded = CanvasSceneDocument.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );

    expect(decoded, scene);

    final text = decoded.children[0] as TextNode;

    expect(
      text.data.appearance.underlays,
      scene.children.whereType<TextNode>().first.data.appearance.underlays,
    );
  });

  test('foreground none with no underlays has no paint bounds', () {
    const source = Rect2D(-10, -5, 10, 5);

    expect(
      estimateAppearancePaintBounds(
        sourceBounds: source,
        foregroundPresent: false,
        underlays: const [],
      ),
      isNull,
    );
  });

  test('foreground none with shadow contains only shadow extent', () {
    const source = Rect2D(-10, -5, 10, 5);

    expect(
      estimateAppearancePaintBounds(
        sourceBounds: source,
        foregroundPresent: false,
        underlays: const [_shadow],
      ),
      const Rect2D(-8, -19, 28, 7),
    );
  });

  test('visible foreground unions source and shadow extent', () {
    const source = Rect2D(-10, -5, 10, 5);

    expect(
      estimateAppearancePaintBounds(
        sourceBounds: source,
        foregroundPresent: true,
        underlays: const [_shadow],
      ),
      const Rect2D(-10, -19, 28, 7),
    );
  });

  test('underlays derive independently from original source', () {
    const source = Rect2D(-10, -5, 10, 5);

    const right = ShadowEffect(
      id: 'right',
      offset: Vec2(20, 0),
      color: 0xFF000000,
    );

    const left = ShadowEffect(
      id: 'left',
      offset: Vec2(-20, 0),
      color: 0xFF000000,
    );

    expect(
      estimateAppearancePaintBounds(
        sourceBounds: source,
        foregroundPresent: false,
        underlays: const [right, left],
      ),
      const Rect2D(-30, -5, 30, 5),
    );
  });

  test('validator requires unique nonblank underlay IDs', () {
    final scene = _scene([
      _shadow,
      _shadow.copyWith(
        offset: const Vec2(double.nan, double.infinity),
        blurSigma: -1,
        color: -1,
        enabled: false,
      ),
      _shadow.copyWith(id: ' '),
    ]);

    final issues = validateCanvasSceneDocument(scene);

    expect(
      issues.map((issue) => issue.code),
      containsAll([
        CanvasSceneValidationCode.duplicateUnderlayId,
        CanvasSceneValidationCode.blankUnderlayId,
        CanvasSceneValidationCode.nonFiniteNumber,
        CanvasSceneValidationCode.valueOutOfRange,
        CanvasSceneValidationCode.invalidColor,
      ]),
    );

    final duplicate = issues.firstWhere(
      (issue) => issue.code == CanvasSceneValidationCode.duplicateUnderlayId,
    );

    expect(duplicate.path, '/children/0/data/appearance/underlays/1/id');

    expect(duplicate.relatedPath, '/children/0/data/appearance/underlays/0/id');
  });
}
