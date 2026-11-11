// Path: test/scene_smoke_test.dart

import 'package:test/test.dart';

import 'package:canvas_core/canvas_core_runtime.dart';

class _FakeTextMeasurer implements TextMeasurer {
  @override
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required double letterSpacing,
  }) {
    final w = text.length.toDouble() * (fontSize * 0.6);
    final h = fontSize * 1.2;
    return Size2D(w, h);
  }
}

class _FakeImages implements ImageIntrinsics {
  @override
  Size2D? intrinsicSize(ElementId id) => null;
}

CoreServices _services() =>
    CoreServices(textMeasurer: _FakeTextMeasurer(), images: _FakeImages());

TextNode _text(String id, String text) => TextNode(
  id: id,

  text: text,
  fontFamily: 'Inter',
  fontWeight: 400,
  fontSize: 20,
  letterSpacing: 0,
);

void main() {
  test('scene traversal + flatten smoke', () {
    final icon = _text('icon1', 'I');

    final main = _text('main1', 'MAIN');

    final shape = Node.path(
      id: 'shape1',
      geometry: const RectSource(x: -5, y: -1, width: 10, height: 2),
      appearance: const CanvasAppearance(
        foreground: CanvasFill.solid(0xFF111111),
      ),
    );

    final accent = _text('accent1', 'ACCENT');

    final group = Node.group(
      id: 'group1',
      xf: Affine2D.translation(100, 50),
      children: [icon, main, shape, accent],
    );

    final rootSibling = _text('rootText1', 'ROOT');

    final doc = CanvasSceneDocument(
      backgroundFill: const CanvasFill.none(),
      backgroundOpacity: 1.0,
      children: [group, rootSibling],
    );

    final foundMain = findById(doc, 'main1');
    expect(foundMain, isA<TextNode>());
    expect((foundMain as TextNode).text, 'MAIN');

    final pIcon = findParentOf(doc, 'icon1');
    expect(pIcon, isNotNull);
    expect(pIcon!.parent, isA<GroupNode>());
    expect(pIcon.parent!.id, 'group1');
    expect(pIcon.index, 0);

    final pRoot = findParentOf(doc, 'rootText1');
    expect(pRoot, isNotNull);
    expect(pRoot!.parent, isNull);
    expect(pRoot.index, 1);

    final updatedMain = (foundMain).copyWith(text: 'MAIN_UPDATED');
    final doc2 = replaceById(doc, 'main1', updatedMain);
    final foundMain2 = findById(doc2, 'main1') as TextNode;
    expect(foundMain2.text, 'MAIN_UPDATED');

    final computed = computeScene(doc, _services());
    final drawList = computed.drawList;

    final ids = drawList.map((f) => f.leafId).toList();
    expect(ids, ['icon1', 'main1', 'shape1', 'accent1', 'rootText1']);

    for (final f in drawList.where((x) => x.leafId != 'rootText1')) {
      expect(f.groupStack, ['group1']);
    }

    final rootFlat = drawList.last;
    expect(rootFlat.leafId, 'rootText1');
    expect(rootFlat.groupStack, isEmpty);
  });
}
