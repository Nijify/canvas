// Path: test/scene_smoke_test.dart

import 'dart:async';

import 'package:test/test.dart';

import 'package:canvas_core/canvas_core_runtime.dart';

class _FakeTextMeasurer implements TextMeasurer {
  @override
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required int letterSpacing,
  }) {
    final w = text.length.toDouble() * (fontSize * 0.6);
    final h = fontSize * 1.2;
    return Size2D(w, h);
  }
}

class _FakeImages implements ImageIntrinsics {
  final _ctrl = StreamController<ElementId>.broadcast();

  @override
  Size2D? intrinsicSize(ElementId id) => null;

  @override
  Stream<ElementId> get onIntrinsicUpdated => _ctrl.stream;
}

CoreServices _services() => CoreServices(
  tm: _FakeTextMeasurer(),
  images: _FakeImages(),
  textMeasureCache: TextMeasureCache(),
);

TextData _td(String text) => TextData(
  text: text,
  fontFamily: 'Inter',
  fontWeight: 400,
  fontSize: 20,
  letterSpacing: 0,
);

void main() {
  test('scene traversal + flatten smoke', () {
    final icon = Node.text(id: 'icon1', data: _td('I'), role: 'icon');

    final main = Node.text(id: 'main1', data: _td('MAIN'), role: 'main');

    final shape = Node.path(
      id: 'shape1',
      data: PathData(
        source: const RectSource(10, 2),
        fill: const CanvasFillSolid(0xFF111111),
      ),
      role: 'shape',
    );

    final accent = Node.text(
      id: 'accent1',
      data: _td('ACCENT'),
      role: 'accent',
    );

    final group = Node.group(
      id: 'group1',
      xf: const Transform2D(position: Vec2(100, 50)),
      children: [icon, main, shape, accent],
    );

    final rootSibling = Node.text(id: 'rootText1', data: _td('ROOT'));

    final doc = CanvasSceneDocument(children: [group, rootSibling]);

    final foundMain = findById(doc, 'main1');
    expect(foundMain, isA<TextNode>());
    expect((foundMain as TextNode).role, 'main');

    final pIcon = findParentOf(doc, 'icon1');
    expect(pIcon, isNotNull);
    expect(pIcon!.parent, isA<GroupNode>());
    expect(pIcon.parent!.id, 'group1');
    expect(pIcon.index, 0);

    final pRoot = findParentOf(doc, 'rootText1');
    expect(pRoot, isNotNull);
    expect(pRoot!.parent, isNull);
    expect(pRoot.index, 1);

    final updatedMain = (foundMain).copyWith(data: _td('MAIN_UPDATED'));
    final doc2 = replaceById(doc, 'main1', updatedMain);
    final foundMain2 = findById(doc2, 'main1') as TextNode;
    expect(foundMain2.data.text, 'MAIN_UPDATED');

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
