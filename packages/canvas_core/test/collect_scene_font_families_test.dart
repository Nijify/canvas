import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

void main() {
  group('collectSceneFontFamilies', () {
    test(
      'collects text and fallback families from all nested nodes',
      () {
        final scene = CanvasSceneDocument(
          backgroundFill: const CanvasFill.none(),
          backgroundOpacity: 1.0,
          children: <Node>[
            Node.text(
              id: 'root-text',
              text: 'Root',
              fontFamily: ' Inter ',
              fontWeight: 400,
              fontSize: 20,
            ),
            Node.group(
              id: 'nested-group',
              children: <Node>[
                Node.text(
                  id: 'nested-text',
                  text: 'Nested',
                  fontFamily: 'Noto Sans',
                  fontWeight: 400,
                  fontSize: 20,
                ),
              ],
            ),
            Node.text(
              id: 'duplicate-text',
              text: 'Duplicate',
              fontFamily: 'Inter',
              fontWeight: 700,
              fontSize: 20,
            ),
            Node.text(
              id: 'blank-font',
              text: 'Blank',
              fontFamily: '   ',
              fontWeight: 400,
              fontSize: 20,
            ),
          ],
        );

        final families = collectSceneFontFamilies(
          scene,
          fallbackFontFamilies: const <String>[
            ' Fallback Sans ',
            '',
            'Fallback Sans',
            'Fallback Serif',
          ],
        );

        expect(
          families,
          unorderedEquals(<String>[
            'Inter',
            'Noto Sans',
            'Fallback Sans',
            'Fallback Serif',
          ]),
        );
      },
    );

    test(
      'icons add no font dependencies, including nested and missing refs',
      () {
        final scene = CanvasSceneDocument(
          backgroundFill: const CanvasFill.none(),
          backgroundOpacity: 1,
          children: [
            const Node.icon(id: 'icon', iconRef: 'vector'),
            const Node.icon(id: 'missing', iconRef: 'missing'),
            const Node.group(
              id: 'nested',
              children: [Node.icon(id: 'nested-icon', iconRef: 'vector')],
            ),
          ],
        );
        expect(collectSceneFontFamilies(scene), isEmpty);
      },
    );
  });
}
