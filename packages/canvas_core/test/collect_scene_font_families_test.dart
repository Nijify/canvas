import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

void main() {
  group('collectSceneFontFamilies', () {
    test(
      'collects text and fallback families from nested and hidden nodes',
      () {
        final scene = CanvasSceneDocument(
          backgroundFill: const CanvasFill.none(),
          backgroundOpacity: 1.0,
          children: <Node>[
            Node.text(
              id: 'root-text',
              data: const TextData(
                text: 'Root',
                fontFamily: ' Inter ',
                fontWeight: 400,
                fontSize: 20,
              ),
            ),
            Node.group(
              id: 'hidden-group',
              hidden: true,
              children: <Node>[
                Node.text(
                  id: 'hidden-text',
                  data: const TextData(
                    text: 'Hidden',
                    fontFamily: 'Noto Sans',
                    fontWeight: 400,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            Node.text(
              id: 'duplicate-text',
              data: const TextData(
                text: 'Duplicate',
                fontFamily: 'Inter',
                fontWeight: 700,
                fontSize: 20,
              ),
            ),
            Node.text(
              id: 'blank-font',
              data: const TextData(
                text: 'Blank',
                fontFamily: '   ',
                fontWeight: 400,
                fontSize: 20,
              ),
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
      'icons add no font dependencies, including hidden and missing refs',
      () {
        final scene = CanvasSceneDocument(
          backgroundFill: const CanvasFill.none(),
          backgroundOpacity: 1,
          children: [
            const Node.icon(
              id: 'icon',
              data: CanvasIconData(iconRef: 'vector'),
            ),
            const Node.icon(
              id: 'missing',
              data: CanvasIconData(iconRef: 'missing'),
            ),
            const Node.group(
              id: 'hidden',
              hidden: true,
              children: [
                Node.icon(
                  id: 'hidden-icon',
                  data: CanvasIconData(iconRef: 'vector'),
                ),
              ],
            ),
          ],
        );
        expect(collectSceneFontFamilies(scene), isEmpty);
      },
    );
  });
}
