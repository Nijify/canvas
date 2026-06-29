// Path: test/snap_scene_test.dart

import 'package:test/test.dart';

import 'package:canvas_core/canvas_core_editor.dart';
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
    return const Size2D(0, 0);
  }
}

void main() {
  test('snapScene applies symmetric grid snapping on both axes', () {
    final doc = const CanvasSceneDocument(
      backgroundFill: CanvasFill.none(),
      backgroundOpacity: 1.0,
    );
    final services = CoreServices(tm: _FakeTextMeasurer());
    final computed = computeScene(doc, services);
    const options = SnapOptions(
      snapToKeylines: false,
      snapToGuides: true,
      snapToGrid: true,
      snapToObjects: false,
      toleranceScreenPx: 5,
      zoom: 1,
      innerDualAxisTolPx: 2,
    );
    const config = SnapConfig(
      options: options,
      gridStepWorld: 10,
      transientGuideCandidates: [
        SnapCandidate(kind: SnapKind.guide, axis: SnapAxis.x, pos: 11),
        SnapCandidate(kind: SnapKind.guide, axis: SnapAxis.y, pos: 23),
      ],
    );

    final probeWorld = Rect2D.fromLTRB(9, 21, 19, 31);
    final result = snapScene(
      doc: doc,
      computed: computed,
      probeWorld: probeWorld,
      config: config,
    );

    expect(result.axis, SnapAxis.both);
    expect(result.deltaWorld, const Vec2(1, -1));
    expect(result.guides, hasLength(2));
    expect(
      result.guides.where((guide) => guide.axis == SnapAxis.x).single.kind,
      SnapKind.grid,
    );
    expect(
      result.guides.where((guide) => guide.axis == SnapAxis.y).single.kind,
      SnapKind.grid,
    );
  });
}
