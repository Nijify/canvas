import 'package:canvas_core/canvas_core_runtime.dart';

import 'svg_export_result.dart';

/// Projects an already-prepared scene and its matching computed geometry.
///
/// [evaluation] is the matching scene/geometry snapshot created by core.
/// This exporter does not consume paint operations or resolve host resources.
/// The supported profile includes none, solid, and linear-gradient backgrounds,
/// plus undashed path geometry with those same fill variants.
SvgExportResult exportPreparedSvg({
  required SceneEvaluation evaluation,
}) {
  final scene = evaluation.scene;
  final computed = evaluation.computed;
  try {
    requireCanvasSceneIntegrity(scene);
  } on ArgumentError catch (error) {
    return SvgExportResult.failure([
      SvgExportIssue(
        code: SvgExportIssueCode.invalidScene,
        message: error.message.toString(),
      ),
    ]);
  }

  final issues = <SvgExportIssue>[];
  final paths = <PathNode>[];

  void visit(Node node) {
    if (node.hidden) return;

    switch (node) {
      case GroupNode(:final children):
        for (final child in children) {
          visit(child);
        }
      case PathNode(:final data):
        paths.add(node);
        final stroke = data.appearance.stroke;
        if (stroke != null &&
            stroke.dash.isNotEmpty &&
            strokeContributesToPaint(stroke)) {
          issues.add(
            SvgExportIssue(
              code: SvgExportIssueCode.unsupportedDashedStroke,
              nodeId: node.id,
              message:
                  'Flutter currently paints this stroke without its '
                  'authored dash pattern.',
            ),
          );
        }
      case TextNode():
        issues.add(
          SvgExportIssue(
            code: SvgExportIssueCode.unsupportedText,
            nodeId: node.id,
            message: 'Text is outside the supported SVG export profile.',
          ),
        );
      case ImageNode():
        issues.add(
          SvgExportIssue(
            code: SvgExportIssueCode.unsupportedImage,
            nodeId: node.id,
            message: 'Images are outside the supported SVG export profile.',
          ),
        );
      case IconNode():
        issues.add(
          SvgExportIssue(
            code: SvgExportIssueCode.unsupportedIcon,
            nodeId: node.id,
            message: 'Icons are outside the supported SVG export profile.',
          ),
        );
    }
  }

  for (final node in scene.children) {
    visit(node);
  }
  if (issues.isNotEmpty) return SvgExportResult.failure(issues);

  final width = _number(scene.artboardSize.w);
  final height = _number(scene.artboardSize.h);
  final gradients = <_SvgLinearGradient>[];
  String? backgroundGradientId;
  final pathGradientIds = <ElementId, String>{};

  void addGradient(LinearGradientSpec gradient, void Function(String id) use) {
    final id = 'gradient-${gradients.length}';
    gradients.add(_SvgLinearGradient(id: id, spec: gradient));
    use(id);
  }

  final backgroundFill = scene.backgroundFill;
  if (scene.backgroundOpacity > 0 && backgroundFill is CanvasFillGradient) {
    addGradient(backgroundFill.grad, (id) => backgroundGradientId = id);
  }

  for (final path in paths) {
    final fill = path.data.appearance.foreground;
    if (fill is CanvasFillGradient) {
      addGradient(fill.grad, (id) => pathGradientIds[path.id] = id);
    }
  }

  final out = StringBuffer()
    ..writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" '
      'width="$width" height="$height" viewBox="0 0 $width $height">',
    );

  if (gradients.isNotEmpty) {
    out.writeln('  <defs>');
    for (final gradient in gradients) {
      _writeLinearGradient(out, gradient);
    }
    out.writeln('  </defs>');
  }

  if (scene.backgroundFill case CanvasFillSolid(:final color)) {
    final alpha = (((color >> 24) & 0xff) * scene.backgroundOpacity)
        .clamp(0, 255)
        .round();
    if (alpha > 0) {
      out.writeln(
        '  <rect x="0" y="0" width="$width" height="$height" '
        'fill="${_rgb(color)}" fill-opacity="${_number(alpha / 255)}"/>',
      );
    }
  } else if (backgroundGradientId != null) {
    out.writeln(
      '  <rect x="0" y="0" width="$width" height="$height" '
      'fill="url(#$backgroundGradientId)" '
      'fill-opacity="${_number(scene.backgroundOpacity)}"/>',
    );
  }

  for (final path in paths) {
    final ir = computed.pathIRById[path.id]!;
    final matrix = computed.worldById[path.id]!.toJson().map(_number).join(' ');
    final data = path.data;
    final authoredFill = data.appearance.foreground;
    final fill = switch (authoredFill) {
      CanvasFillNone() => 'none',
      CanvasFillSolid(:final color) => _rgb(color),
      CanvasFillGradient() => 'url(#${pathGradientIds[path.id]!})',
    };
    final stroke = strokeContributesToPaint(data.appearance.stroke)
        ? data.appearance.stroke
        : null;
    out.write(
      '  <path d="${writeSvgPathData(ir)}" transform="matrix($matrix)" '
      'fill="$fill" '
      'fill-rule="${data.fillRule == FillRule.evenOdd ? 'evenodd' : 'nonzero'}"',
    );
    if (authoredFill case CanvasFillSolid(:final color)) {
      out.write(' fill-opacity="${_opacity(color)}"');
    }
    out.write(' stroke="${stroke == null ? 'none' : _rgb(stroke.color)}"');
    if (stroke != null) {
      out.write(
        ' stroke-opacity="${_opacity(stroke.color)}" '
        'stroke-width="${_number(stroke.width)}" '
        'stroke-linecap="${stroke.cap.name}" '
        'stroke-linejoin="${stroke.join.name}" '
        'stroke-miterlimit="${_number(stroke.miterLimit)}"',
      );
    }
    out.writeln('/>');
  }

  out.writeln('</svg>');
  return SvgExportResult.success(out.toString());
}

void _writeLinearGradient(StringBuffer out, _SvgLinearGradient gradient) {
  final spec = gradient.spec;
  out.writeln(
    '    <linearGradient id="${gradient.id}" '
    'gradientUnits="userSpaceOnUse" spreadMethod="pad" '
    'x1="${_number(spec.start.x)}" y1="${_number(spec.start.y)}" '
    'x2="${_number(spec.end.x)}" y2="${_number(spec.end.y)}">',
  );
  for (final stop in spec.stops) {
    out.writeln(
      '      <stop offset="${_number(stop.offset)}" '
      'stop-color="${_rgb(stop.color)}" '
      'stop-opacity="${_opacity(stop.color)}"/>',
    );
  }
  out.writeln('    </linearGradient>');
}

final class _SvgLinearGradient {
  const _SvgLinearGradient({required this.id, required this.spec});

  final String id;
  final LinearGradientSpec spec;
}

String _number(double value) => value == 0 ? '0' : value.toString();
String _rgb(int argb) =>
    '#${(argb & 0xffffff).toRadixString(16).padLeft(6, '0')}';
String _opacity(int argb) => _number(((argb >> 24) & 0xff) / 255);
