import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

final class _TestIconResolver implements IconResolver {
  const _TestIconResolver(this.icons);

  final Map<String, ResolvedIcon> icons;

  @override
  ResolvedIcon? resolve(String iconRef) => icons[iconRef];
}

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
      'collects text-backed icon fonts and ignores path or unresolved icons',
      () {
        const icons = _TestIconResolver(<String, ResolvedIcon>{
          'font-icon': ResolvedIconText(
            glyph: '\uf005',
            fontFamily: ' Font Awesome 6 Free ',
            fontWeight: 900,
          ),
          'path-icon': ResolvedIconPath(PathData(source: RectSource(16, 16))),
        });

        final scene = CanvasSceneDocument(
          backgroundFill: const CanvasFill.none(),
          backgroundOpacity: 1.0,
          children: <Node>[
            Node.icon(
              id: 'font-icon-node',
              data: const CanvasIconData(iconRef: 'font-icon'),
            ),
            Node.icon(
              id: 'path-icon-node',
              data: const CanvasIconData(iconRef: 'path-icon'),
            ),
            Node.icon(
              id: 'missing-icon-node',
              data: const CanvasIconData(iconRef: 'missing-icon'),
            ),
            Node.group(
              id: 'hidden-icons',
              hidden: true,
              children: <Node>[
                Node.icon(
                  id: 'hidden-font-icon',
                  data: const CanvasIconData(iconRef: 'font-icon'),
                ),
              ],
            ),
          ],
        );

        final families = collectSceneFontFamilies(scene, icons: icons);

        expect(families, unorderedEquals(<String>['Font Awesome 6 Free']));
      },
    );
  });
}
