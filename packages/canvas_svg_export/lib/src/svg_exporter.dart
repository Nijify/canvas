import 'package:canvas_core/canvas_core_runtime.dart';

import 'svg_export_result.dart';

/// Projects an already-prepared scene and its matching computed geometry.
///
/// The caller computes [computed] from this exact [scene] with `computeScene`.
/// This exporter does not consume paint operations or resolve host resources.
/// Its first profile supports solid backgrounds and undashed path geometry.
SvgExportResult exportPreparedSvg({
  required CanvasSceneDocument scene,
  required ComputedScene computed,
}) {
  final issues = <SvgExportIssue>[
    for (final issue in validateCanvasSceneDocument(scene))
      SvgExportIssue(
        code: SvgExportIssueCode.invalidScene,
        path: issue.path,
        message: issue.message,
      ),
  ];
  if (issues.isNotEmpty) return SvgExportResult.failure(issues);

  if (scene.backgroundFill is CanvasFillGradient &&
      scene.backgroundOpacity > 0) {
    issues.add(
      const SvgExportIssue(
        code: SvgExportIssueCode.unsupportedGradient,
        path: '/backgroundFill',
        message:
            'The current angle/width background gradient has no '
            'direct SVG semantics.',
      ),
    );
  }

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
        if (data.fill is CanvasFillGradient) {
          issues.add(
            SvgExportIssue(
              code: SvgExportIssueCode.unsupportedGradient,
              nodeId: node.id,
              message:
                  'The current angle/width path gradient has no '
                  'direct SVG semantics.',
            ),
          );
        }
        if (data.dash.isNotEmpty &&
            data.strokeColor != 0 &&
            data.strokeWidth > 0) {
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

  final drawList = computed.drawList;
  var orderMatches = drawList.length == paths.length;
  if (orderMatches) {
    for (var i = 0; i < paths.length; i++) {
      if (drawList[i].leafId != paths[i].id) {
        orderMatches = false;
        break;
      }
    }
  }
  if (!orderMatches) {
    return SvgExportResult.failure(const <SvgExportIssue>[
      SvgExportIssue(
        code: SvgExportIssueCode.missingComputedGeometry,
        message: 'Computed paint order does not match the prepared scene.',
      ),
    ]);
  }

  for (final path in paths) {
    final id = path.id;
    final ir = computed.pathIRById[id];
    final matrix = computed.worldById[id];
    if (computed.nodeById[id] != path ||
        ir == null ||
        matrix == null ||
        !_validPath(ir) ||
        !_validMatrix(matrix.storage)) {
      issues.add(
        SvgExportIssue(
          code: SvgExportIssueCode.missingComputedGeometry,
          nodeId: id,
          message: 'The path or its computed transform is missing or invalid.',
        ),
      );
    } else if (ir.style.stroke != null &&
        ir.style.strokeWidth > 0 &&
        ir.style.dash?.isNotEmpty == true) {
      issues.add(
        SvgExportIssue(
          code: SvgExportIssueCode.unsupportedDashedStroke,
          nodeId: id,
          message:
              'Flutter currently paints this stroke without its '
              'authored dash pattern.',
        ),
      );
    }
  }
  if (issues.isNotEmpty) return SvgExportResult.failure(issues);

  final width = _number(scene.artboardSize.w);
  final height = _number(scene.artboardSize.h);
  final out = StringBuffer()
    ..writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" '
      'width="$width" height="$height" viewBox="0 0 $width $height">',
    );

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
  }

  for (final path in paths) {
    final ir = computed.pathIRById[path.id]!;
    final storage = computed.worldById[path.id]!.storage;
    final matrix = [
      storage[0],
      storage[1],
      storage[4],
      storage[5],
      storage[12],
      storage[13],
    ].map(_number).join(' ');
    final style = ir.style;
    final fill = style.fill;
    final stroke = style.strokeWidth > 0 ? style.stroke : null;
    out.write(
      '  <path d="${_pathData(ir)}" transform="matrix($matrix)" '
      'fill="${fill == null ? 'none' : _rgb(fill)}" '
      'fill-rule="${style.fillRule == FillRule.evenOdd ? 'evenodd' : 'nonzero'}"',
    );
    if (fill != null) {
      out.write(' fill-opacity="${_opacity(fill)}"');
    }
    out.write(' stroke="${stroke == null ? 'none' : _rgb(stroke)}"');
    if (stroke != null) {
      out.write(
        ' stroke-opacity="${_opacity(stroke)}" '
        'stroke-width="${_number(style.strokeWidth)}" '
        'stroke-linecap="${style.strokeCap.name}" '
        'stroke-linejoin="${style.strokeJoin.name}" '
        'stroke-miterlimit="${_number(style.miterLimit)}"',
      );
    }
    out.writeln('/>');
  }

  out.writeln('</svg>');
  return SvgExportResult.success(out.toString());
}

bool _validPath(PathIR path) {
  var hasStart = false;
  for (final cmd in path.cmds) {
    if (!cmd.p.x.isFinite || !cmd.p.y.isFinite) return false;
    switch (cmd.verb) {
      case PathVerb.moveTo:
        hasStart = true;
      case PathVerb.lineTo:
      case PathVerb.close:
        if (!hasStart) return false;
      case PathVerb.quadTo:
        if (!hasStart ||
            cmd.c1 == null ||
            !cmd.c1!.x.isFinite ||
            !cmd.c1!.y.isFinite)
          return false;
      case PathVerb.cubicTo:
        if (!hasStart ||
            cmd.c1 == null ||
            cmd.c2 == null ||
            !cmd.c1!.x.isFinite ||
            !cmd.c1!.y.isFinite ||
            !cmd.c2!.x.isFinite ||
            !cmd.c2!.y.isFinite)
          return false;
    }
  }
  return true;
}

bool _validMatrix(List<double> m) {
  if (m.length != 16 || m.any((v) => !v.isFinite)) return false;
  const zero = <int>[2, 3, 6, 7, 8, 9, 11, 14];
  return zero.every((i) => m[i].abs() < 1e-9) &&
      (m[10] - 1).abs() < 1e-9 &&
      (m[15] - 1).abs() < 1e-9;
}

String _pathData(PathIR path) => path.cmds
    .map((cmd) {
      final p = cmd.p;
      switch (cmd.verb) {
        case PathVerb.moveTo:
          return 'M${_number(p.x)} ${_number(p.y)}';
        case PathVerb.lineTo:
          return 'L${_number(p.x)} ${_number(p.y)}';
        case PathVerb.quadTo:
          final c = cmd.c1!;
          return 'Q${_number(c.x)} ${_number(c.y)} '
              '${_number(p.x)} ${_number(p.y)}';
        case PathVerb.cubicTo:
          final c1 = cmd.c1!, c2 = cmd.c2!;
          return 'C${_number(c1.x)} ${_number(c1.y)} '
              '${_number(c2.x)} ${_number(c2.y)} '
              '${_number(p.x)} ${_number(p.y)}';
        case PathVerb.close:
          return 'Z';
      }
    })
    .join(' ');

String _number(double value) => value == 0 ? '0' : value.toString();
String _rgb(int argb) =>
    '#${(argb & 0xffffff).toRadixString(16).padLeft(6, '0')}';
String _opacity(int argb) => _number(((argb >> 24) & 0xff) / 255);
