// Path: oss_packages/canvas_editor_flutter/test/editor_runtime_publication_boundary_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/runtime/editor_runtime.dart';
import 'package:canvas_editor_flutter/src/editor_api.dart'
    show CanvasSceneDocumentAdapter;
import 'package:canvas_editor_flutter/src/editor_edits.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTextMeasurer implements TextMeasurer {
  @override
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required int letterSpacing,
  }) {
    return Size2D(text.length * fontSize * 0.6, fontSize);
  }
}

const _textData = TextData(
  text: 'Hello',
  fontFamily: 'Inter',
  fontWeight: 700,
  fontSize: 24,
  letterSpacing: 0,
  fill: CanvasFill.solid(0xFF111111),
  shadowOffset: 0,
);

CanvasSceneDocument _sceneWithChildren(List<Node> children) {
  return CanvasSceneDocument(
    artboardSize: const Size2D(300, 200),
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1.0,
    children: children,
  );
}

EditorRuntime<CanvasSceneDocument> _buildRuntime(
  CanvasSceneDocument initialScene,
) {
  final renderPipeline = CanvasRenderPipeline(
    textMeasurer: _FakeTextMeasurer(),
  );

  return EditorRuntime<CanvasSceneDocument>(
    initial: initialScene,
    adapter: const CanvasSceneDocumentAdapter(),
    renderPipeline: renderPipeline,
    imageIntrinsics: null,
  );
}

void main() {
  testWidgets(
    'layout invalidation publishes render without publishing document',
    (tester) async {
      final runtime = _buildRuntime(
        _sceneWithChildren(const [Node.text(id: 't1', data: _textData)]),
      );
      addTearDown(runtime.dispose);

      final initialRender = runtime.render.value;

      var renderPublications = 0;
      var documentPublications = 0;

      runtime.render.addListener(() {
        renderPublications += 1;
      });

      runtime.document.addListener(() {
        documentPublications += 1;
      });

      runtime.scheduleLayoutInvalidation();
      await tester.pump();

      expect(renderPublications, 1);
      expect(documentPublications, 0);
      expect(identical(runtime.render.value, initialRender), isFalse);
      expect(runtime.document.value.children.single.name, isNull);

      runtime.applyEdit(EditorEdits.renameElement('t1', 'Hero Title'));

      expect(renderPublications, 2);
      expect(documentPublications, 1);
      expect(runtime.document.value.children.single.name, 'Hero Title');
    },
  );

  testWidgets(
    'pending layout invalidation is cancelled when runtime is disposed',
    (tester) async {
      final runtime = _buildRuntime(
        _sceneWithChildren(const [Node.text(id: 't1', data: _textData)]),
      );
      addTearDown(runtime.dispose);

      var renderPublications = 0;
      var sourcePublications = 0;
      var documentPublications = 0;

      runtime.render.addListener(() {
        renderPublications += 1;
      });

      runtime.source.addListener(() {
        sourcePublications += 1;
      });

      runtime.document.addListener(() {
        documentPublications += 1;
      });

      runtime.scheduleLayoutInvalidation();
      runtime.dispose();

      await tester.pump();

      expect(renderPublications, 0);
      expect(sourcePublications, 0);
      expect(documentPublications, 0);
      expect(tester.takeException(), isNull);

      expect(() => runtime.dispose(), returnsNormally);
    },
  );
}
