import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_svg_export/canvas_svg_export.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

final class _TextMeasurer implements TextMeasurer {
  const _TextMeasurer();

  @override
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required double letterSpacing,
  }) => Size2D(text.length * fontSize * 0.6, fontSize);
}

ComputedScene _compute(CanvasSceneDocument scene) =>
    computeScene(scene, const CoreServices(textMeasurer: _TextMeasurer()));

CanvasSceneDocument _scene({
  CanvasFill background = const CanvasFill.none(),
  double opacity = 1,
  List<Node> children = const [],
}) => CanvasSceneDocument(
  artboardSize: const Size2D(120, 80),
  backgroundFill: background,
  backgroundOpacity: opacity,
  children: children,
);

void main() {
  test('emits an artboard, background, path paint, and alpha', () {
    final scene = _scene(
      background: const CanvasFill.solid(0x80445566),
      opacity: 0.5,
      children: const [
        Node.path(
          id: 'p',
          name: 'unsafe<&',
          role: 'logo:main',
          data: PathData(
            source: RectSource(20, 10),
            fill: CanvasFill.solid(0x80ff0000),
            fillRule: FillRule.evenOdd,
            strokeColor: 0xff00ff00,
            strokeWidth: 2,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.bevel,
          ),
        ),
      ],
    );

    final result = exportPreparedSvg(scene: scene, computed: _compute(scene));
    expect(result.issues, isEmpty);
    final root = XmlDocument.parse(result.svg!).rootElement;
    expect(root.name.local, 'svg');
    expect(root.getAttribute('viewBox'), '0 0 120.0 80.0');
    final rect = root.findAllElements('rect').single;
    expect(rect.getAttribute('fill'), '#445566');
    expect(
      double.parse(rect.getAttribute('fill-opacity')!),
      closeTo(64 / 255, 1e-12),
    );
    final path = root.findAllElements('path').single;
    expect(path.getAttribute('d'), startsWith('M-10.0 -5.0'));
    expect(path.getAttribute('fill'), '#ff0000');
    expect(path.getAttribute('fill-rule'), 'evenodd');
    expect(
      double.parse(path.getAttribute('fill-opacity')!),
      closeTo(128 / 255, 1e-12),
    );
    expect(path.getAttribute('stroke'), '#00ff00');
    expect(path.getAttribute('stroke-width'), '2.0');
    expect(path.getAttribute('stroke-linecap'), 'round');
    expect(path.getAttribute('stroke-linejoin'), 'bevel');
    expect(result.svg, isNot(contains('unsafe')));
    expect(result.svg, isNot(contains('logo:main')));
    expect(
      exportPreparedSvg(scene: scene, computed: _compute(scene)).svg,
      result.svg,
    );
  });

  test('flattens nested groups in computed paint order', () {
    final scene = _scene(
      children: const [
        Node.group(
          id: 'group',
          xf: Transform2D(
            position: Vec2(40, 20),
            scale: Vec2(2, 2),
            origin: OriginKind.custom,
            customPivotPx: Vec2.zero,
          ),
          children: [
            Node.path(
              id: 'first',
              xf: Transform2D(
                position: Vec2(10, 5),
                origin: OriginKind.custom,
                customPivotPx: Vec2.zero,
              ),
              data: PathData(
                source: RectSource(10, 10),
                fill: CanvasFill.solid(0xffff0000),
              ),
            ),
            Node.path(
              id: 'second',
              xf: Transform2D(
                position: Vec2(20, 5),
                origin: OriginKind.custom,
                customPivotPx: Vec2.zero,
              ),
              data: PathData(
                source: RectSource(20, 10),
                fill: CanvasFill.solid(0xff0000ff),
              ),
            ),
          ],
        ),
      ],
    );

    final result = exportPreparedSvg(scene: scene, computed: _compute(scene));
    final paths = XmlDocument.parse(
      result.svg!,
    ).findAllElements('path').toList();
    expect(paths.map((p) => p.getAttribute('fill')), ['#ff0000', '#0000ff']);
    expect(paths[0].getAttribute('transform'), 'matrix(2.0 0 0 2.0 60.0 30.0)');
    expect(paths[1].getAttribute('transform'), 'matrix(2.0 0 0 2.0 80.0 30.0)');
  });

  test('writes compiled quadratic and cubic path commands', () {
    final scene = _scene(
      children: const [
        Node.path(
          id: 'curve',
          data: PathData(
            source: RectSource(10, 10),
            fill: CanvasFill.solid(0xff123456),
          ),
        ),
      ],
    );
    final computed = _compute(scene);
    final original = computed.pathIRById['curve']!;
    final withCurves = ComputedScene(
      drawList: computed.drawList,
      nodeById: computed.nodeById,
      worldById: computed.worldById,
      layoutBoundsLocalById: computed.layoutBoundsLocalById,
      paintBoundsLocalById: computed.paintBoundsLocalById,
      paintBoundsWorldById: computed.paintBoundsWorldById,
      pathIRById: {
        'curve': PathIR([
          PathCmd.moveTo(const Vec2(0, 0)),
          PathCmd.quadTo(const Vec2(2, 3), const Vec2(4, 5)),
          PathCmd.cubicTo(
            const Vec2(6, 7),
            const Vec2(8, 9),
            const Vec2(10, 11),
          ),
          PathCmd.close(),
        ], original.style),
      },
      imagePlacementById: computed.imagePlacementById,
      iconTextById: computed.iconTextById,
      iconPathIRById: computed.iconPathIRById,
    );
    final result = exportPreparedSvg(scene: scene, computed: withCurves);
    final path = XmlDocument.parse(result.svg!).findAllElements('path').single;
    expect(
      path.getAttribute('d'),
      'M0 0 Q2.0 3.0 4.0 5.0 '
      'C6.0 7.0 8.0 9.0 10.0 11.0 Z',
    );
  });

  test('exports explicit background and path gradients', () {
    final backgroundGradient = LinearGradientSpec(
      start: const Vec2(0, 40),
      end: const Vec2(120, 40),
      stops: const <GradientStop>[
        GradientStop(offset: 0, color: 0x80445566),
        GradientStop(offset: 0.5, color: 0xFF778899),
        GradientStop(offset: 1, color: 0xFF001122),
      ],
    );
    final pathGradient = LinearGradientSpec(
      start: const Vec2(-10, 0),
      end: const Vec2(10, 0),
      stops: const <GradientStop>[
        GradientStop(offset: 0, color: 0xFF000000),
        GradientStop(offset: 0, color: 0xFFFF0000),
        GradientStop(offset: 1, color: 0x8000FF00),
      ],
    );
    final scene = _scene(
      background: CanvasFill.gradient(backgroundGradient),
      opacity: 0.5,
      children: <Node>[
        Node.path(
          id: 'gradient',
          xf: const Transform2D(
            position: Vec2(20, 10),
            rotationRad: 0.5,
          ),
          data: PathData(
            source: const RectSource(10, 10),
            fill: CanvasFill.gradient(pathGradient),
          ),
        ),
      ],
    );

    final result = exportPreparedSvg(scene: scene, computed: _compute(scene));

    expect(result.issues, isEmpty);
    final root = XmlDocument.parse(result.svg!).rootElement;
    final gradients = root.findAllElements('linearGradient').toList();
    expect(gradients.map((gradient) => gradient.getAttribute('id')), [
      'gradient-0',
      'gradient-1',
    ]);
    expect(gradients.first.getAttribute('gradientUnits'), 'userSpaceOnUse');
    expect(gradients.first.getAttribute('spreadMethod'), 'pad');
    expect(gradients.first.getAttribute('x1'), '0');
    expect(gradients.first.getAttribute('y1'), '40.0');
    expect(gradients.last.getAttribute('x1'), '-10.0');
    expect(gradients.last.getAttribute('x2'), '10.0');

    final background = root.findAllElements('rect').single;
    expect(background.getAttribute('fill'), 'url(#gradient-0)');
    expect(background.getAttribute('fill-opacity'), '0.5');

    final path = root.findAllElements('path').single;
    expect(path.getAttribute('fill'), 'url(#gradient-1)');
    expect(path.getAttribute('transform'), isNotNull);

    final pathStops = gradients.last.findElements('stop').toList();
    expect(pathStops.map((stop) => stop.getAttribute('offset')), ['0', '0', '1.0']);
    expect(pathStops.last.getAttribute('stop-color'), '#00ff00');
    expect(
      double.parse(pathStops.last.getAttribute('stop-opacity')!),
      closeTo(128 / 255, 1e-12),
    );
  });

  test('rejects dashed strokes without partial SVG', () {
    final scene = _scene(
      background: CanvasFill.gradient(
        LinearGradientSpec(
          start: const Vec2(0, 40),
          end: const Vec2(120, 40),
          stops: const <GradientStop>[
            GradientStop(offset: 0, color: 0xff000000),
            GradientStop(offset: 1, color: 0xffffffff),
          ],
        ),
      ),
      children: <Node>[
        Node.path(
          id: 'gradient',
          data: PathData(
            source: RectSource(10, 10),
            fill: CanvasFill.gradient(
              LinearGradientSpec(
                start: Vec2(-5, 0),
                end: Vec2(5, 0),
                stops: <GradientStop>[
                  GradientStop(offset: 0, color: 0xff000000),
                  GradientStop(offset: 1, color: 0xffffffff),
                ],
              ),
            ),
          ),
        ),
        Node.path(
          id: 'dashed',
          data: PathData(
            source: RectSource(20, 10),
            strokeColor: 0xff000000,
            dash: [5, 3],
          ),
        ),
      ],
    );

    final result = exportPreparedSvg(scene: scene, computed: _compute(scene));
    expect(result.svg, isNull);
    expect(result.issues.map((i) => (i.code, i.nodeId)), [
      (SvgExportIssueCode.unsupportedDashedStroke, 'dashed'),
    ]);
  });

  test('hidden unsupported nodes do not block export', () {
    final scene = _scene(
      children: const [
        Node.text(
          id: 'hidden-text',
          hidden: true,
          data: TextData(
            text: 'hidden',
            fontFamily: 'sans',
            fontWeight: 400,
            fontSize: 12,
          ),
        ),
      ],
    );
    final result = exportPreparedSvg(scene: scene, computed: _compute(scene));
    expect(result.issues, isEmpty);
    expect(XmlDocument.parse(result.svg!).findAllElements('path'), isEmpty);
  });

  test('rejects visible non-path nodes even when resources are missing', () {
    final scene = _scene(
      children: const [
        Node.text(
          id: 't',
          data: TextData(
            text: 'x',
            fontFamily: 'sans',
            fontWeight: 400,
            fontSize: 12,
          ),
        ),
        Node.image(
          id: 'i',
          data: ImageData(size: Size2D(10, 10)),
        ),
        Node.icon(
          id: 'c',
          data: CanvasIconData(iconRef: 'missing'),
        ),
      ],
    );
    final result = exportPreparedSvg(scene: scene, computed: _compute(scene));
    expect(result.svg, isNull);
    expect(result.issues.map((i) => i.code), [
      SvgExportIssueCode.unsupportedText,
      SvgExportIssueCode.unsupportedImage,
      SvgExportIssueCode.unsupportedIcon,
    ]);
  });

  test('does not silently skip missing computed path geometry', () {
    final scene = _scene(
      children: const [
        Node.path(
          id: 'p',
          data: PathData(
            source: RectSource(10, 10),
            fill: CanvasFill.solid(0xff000000),
          ),
        ),
      ],
    );
    final computed = _compute(scene);
    final incomplete = ComputedScene(
      drawList: computed.drawList,
      nodeById: computed.nodeById,
      worldById: computed.worldById,
      layoutBoundsLocalById: computed.layoutBoundsLocalById,
      paintBoundsLocalById: computed.paintBoundsLocalById,
      paintBoundsWorldById: computed.paintBoundsWorldById,
      pathIRById: const {},
      imagePlacementById: computed.imagePlacementById,
      iconTextById: computed.iconTextById,
      iconPathIRById: computed.iconPathIRById,
    );
    final result = exportPreparedSvg(scene: scene, computed: incomplete);
    expect(result.svg, isNull);
    expect(
      result.issues.single.code,
      SvgExportIssueCode.missingComputedGeometry,
    );
    expect(result.issues.single.nodeId, 'p');
  });

  test('rejects invalid numeric scene values before writing XML', () {
    final valid = _scene();
    final invalid = valid.copyWith(artboardSize: const Size2D(0, 80));
    final result = exportPreparedSvg(scene: invalid, computed: _compute(valid));
    expect(result.svg, isNull);
    expect(result.issues.single.code, SvgExportIssueCode.invalidScene);
    expect(result.issues.single.path, '/artboardSize/w');
  });
}
