import 'dart:convert';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

const _shadow = ShadowEffect(
  id: 's',
  offset: Vec2(10, -6),
  blurSigma: 2,
  color: 0x80446688,
);

CanvasSceneDocument _scene(List<ShadowEffect> shadows) => CanvasSceneDocument(
  backgroundFill: const CanvasFill.none(),
  children: [
    Node.text(
      id: 'text',
      data: TextData(
        text: 'X',
        fontFamily: 'Ahem',
        fontWeight: 400,
        fontSize: 24,
        shadows: shadows,
      ),
    ),
    Node.icon(
      id: 'icon',
      data: CanvasIconData(iconRef: 'test', shadows: shadows),
    ),
  ],
);

void main() {
  test('text and icon JSON round-trip order, identity and disabled state', () {
    final shadows = [_shadow, _shadow.copyWith(id: 'disabled', enabled: false)];
    final scene = _scene(shadows);
    final encoded = jsonEncode(scene.toJson());
    final decoded = CanvasSceneDocument.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );
    expect(decoded, scene);
    expect((decoded.children[0] as TextNode).data.shadows, shadows);
    expect((decoded.children[1] as IconNode).data.shadows, shadows);
    expect(encoded, isNot(contains('shadowOffset')));
    // Same shadow IDs on DIFFERENT nodes are allowed.
    expect(validateCanvasSceneDocument(scene), isEmpty);
  });

  test('empty shadows default correctly and round-trip', () {
    final data = TextData.fromJson({
      'text': 'X',
      'fontFamily': 'Ahem',
      'fontWeight': 400,
      'fontSize': 24,
    });
    expect(data.shadows, isEmpty);
    expect(TextData.fromJson(data.toJson()), data);
  });

  test('bounds use independent x/y offsets and four-sigma expansion', () {
    const base = Rect2D(-10, -5, 10, 5);
    expect(
      estimateShadowPaintBounds(base, [_shadow]),
      const Rect2D(-10, -19, 28, 7),
    );
    expect(estimateShadowPaintBounds(null, [_shadow]), isNull);
  });

  test('shadows expand the source, never accumulated shadow bounds', () {
    const base = Rect2D(-10, -5, 10, 5);
    final first = _shadow.copyWith(offset: const Vec2(20, 0), blurSigma: 0);
    final second = first.copyWith(id: 'second', offset: const Vec2(-20, 0));
    expect(
      estimateShadowPaintBounds(base, [first, second]),
      const Rect2D(-30, -5, 30, 5),
    );
    expect(
      estimateShadowPaintBounds(base, [second, first]),
      estimateShadowPaintBounds(base, [first, second]),
    );
  });

  test('disabled, transparent and malformed effects do not expand bounds', () {
    const base = Rect2D(-10, -5, 10, 5);
    expect(
      estimateShadowPaintBounds(base, [
        _shadow.copyWith(enabled: false),
        _shadow.copyWith(id: 'transparent', color: 0x00123456),
        _shadow.copyWith(id: 'invalid', blurSigma: double.nan),
      ]),
      base,
    );
  });

  test('validator reports blank/duplicate IDs, offsets, sigma and color', () {
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
        CanvasSceneValidationCode.duplicateShadowId,
        CanvasSceneValidationCode.blankShadowId,
        CanvasSceneValidationCode.nonFiniteNumber,
        CanvasSceneValidationCode.valueOutOfRange,
        CanvasSceneValidationCode.invalidColor,
      ]),
    );
    final duplicate = issues.firstWhere(
      (issue) => issue.code == CanvasSceneValidationCode.duplicateShadowId,
    );
    expect(duplicate.path, '/children/0/data/shadows/1/id');
    expect(duplicate.relatedPath, '/children/0/data/shadows/0/id');
  });

  test('draw operations snapshot the supplied list', () {
    final supplied = [_shadow];
    final op = DrawTextOp(
      text: 'X',
      family: 'Ahem',
      weight: 400,
      size: 24,
      originBaselineCenter: Vec2.zero,
      shadows: supplied,
    );
    supplied.clear();
    expect(op.shadows, [_shadow]);
    expect(() => op.shadows.clear(), throwsUnsupportedError);
  });
}
