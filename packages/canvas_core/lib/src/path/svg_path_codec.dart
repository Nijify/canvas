import 'package:canvas_core/src/foundation/core_types.dart' show Vec2;
import 'package:canvas_core/src/path/path_ir.dart';
import 'package:path_parsing/path_parsing.dart' as svg;

/// Parses SVG path data once into core-owned absolute M/L/C/Z geometry.
/// Quadratics and arcs are normalized by path_parsing, not by the renderer.
/// Empty/whitespace-only path data is valid. Errors never return partial paths.
PathIR parseSvgPathData(String d) {
  // The dependency tolerates a comma before a command or end of input. Those
  // separators are not SVG path syntax, and persisted geometry is strict.
  if (RegExp(r',\s*(?:[a-zA-Z]|$)').hasMatch(d)) {
    throw const FormatException('Unexpected comma in SVG path data.');
  }
  final collector = _PathCollector();
  try {
    final normalizer = svg.SvgPathNormalizer();
    for (final segment in svg.SvgPathStringSource(d).parseSegments()) {
      final command = segment.command.name;
      collector.normalizingArc = command == 'arcToAbs' || command == 'arcToRel';
      normalizer.emitSegment(segment, collector);
    }
    return PathIR(collector.commands);
  } on StateError catch (error) {
    throw FormatException('Invalid SVG path data: ${error.message}');
  } on ArgumentError catch (error) {
    throw FormatException('Invalid SVG path geometry: ${error.message}');
  }
}

/// Writes absolute, explicit M/L/C/Z commands with deterministic double spelling.
/// This writes geometry only, without XML, transforms, fill, or stroke.
String writeSvgPathData(PathIR geometry) => geometry.cmds.map((command) {
  String point(Vec2 p) => '${_number(p.x)} ${_number(p.y)}';
  return switch (command.verb) {
    PathVerb.moveTo => 'M${point(command.p)}',
    PathVerb.lineTo => 'L${point(command.p)}',
    PathVerb.cubicTo =>
      'C${point(command.c1!)} ${point(command.c2!)} ${point(command.p)}',
    PathVerb.close => 'Z',
  };
}).join(' ');

final class _PathCollector extends svg.PathProxy {
  final commands = <PathCmd>[];
  Vec2 _start = Vec2.zero;
  Vec2 _current = Vec2.zero;
  bool normalizingArc = false;
  bool _open = false;

  void _continueContour() {
    if (!_open) moveTo(_start.x, _start.y);
  }

  @override
  void moveTo(double x, double y) {
    _start = Vec2(x, y);
    _current = _start;
    _open = true;
    commands.add(PathCmd.moveTo(_start));
  }

  @override
  void lineTo(double x, double y) {
    final point = Vec2(x, y);
    // SVG omits arcs with coincident endpoints. The dependency emits a zero
    // line instead, which could otherwise paint a round/square stroke cap.
    if (normalizingArc && point == _current) return;
    _continueContour();
    commands.add(PathCmd.lineTo(point));
    _current = point;
  }

  @override
  void cubicTo(double x1, double y1, double x2, double y2, double x, double y) {
    _continueContour();
    _current = Vec2(x, y);
    commands.add(PathCmd.cubicTo(Vec2(x1, y1), Vec2(x2, y2), _current));
  }

  @override
  void close() {
    if (!_open) return;
    commands.add(PathCmd.close());
    _current = _start;
    _open = false;
  }
}

final _pointNumber = RegExp(r'[-+]?(?:\d+(?:\.\d+)?|\.\d+)(?:[eE][-+]?\d+)?');
final _pointSpace = RegExp(r'[\x20\t\r\n\f]');

/// Parses an SVG numeric point list, rejecting incomplete pairs and junk.
List<Vec2> parseSvgPoints(String text) {
  final coordinates = <double>[];
  var index = 0;
  while (index < text.length) {
    while (index < text.length && _pointSpace.hasMatch(text[index])) index++;
    if (index == text.length) break;
    if (text[index] == ',') {
      if (coordinates.isEmpty) {
        throw const FormatException('A points list cannot start with a comma.');
      }
      index++;
      while (index < text.length && _pointSpace.hasMatch(text[index])) index++;
    }
    final match = _pointNumber.matchAsPrefix(text, index);
    if (match == null) throw const FormatException('Invalid SVG points list.');
    final value = double.parse(match.group(0)!);
    if (!value.isFinite) throw const FormatException('Points must be finite.');
    coordinates.add(value);
    index = match.end;
  }
  if (coordinates.length.isOdd) {
    throw const FormatException('Points require complete x/y pairs.');
  }
  return List.unmodifiable([
    for (var i = 0; i < coordinates.length; i += 2)
      Vec2(coordinates[i], coordinates[i + 1]),
  ]);
}

String writeSvgPoints(List<Vec2> points) => points.map(
  (point) => '${_number(point.x)},${_number(point.y)}',
).join(' ');

String _number(double value) {
  if (!value.isFinite) throw ArgumentError.value(value, 'coordinate', 'Must be finite.');
  if (value == 0) return '0';
  final text = value.toString();
  final parts = text.split('e');
  if (parts.length == 1) return text;
  final exponent = int.parse(parts[1]);
  if (exponent >= -37 && exponent <= 38) return text;
  // The parser restricts explicit exponents. Expand the writer's own output
  // outside that lexical range without rounding the represented double.
  final negative = parts[0].startsWith('-');
  final mantissa = negative ? parts[0].substring(1) : parts[0];
  final dot = mantissa.indexOf('.');
  final decimal = (dot == -1 ? mantissa.length : dot) + exponent;
  final digits = mantissa.replaceAll('.', '');
  final String expanded;
  if (decimal <= 0) {
    expanded = '0.${List.filled(-decimal, '0').join()}$digits';
  } else if (decimal >= digits.length) {
    expanded = '$digits${List.filled(decimal - digits.length, '0').join()}';
  } else {
    expanded = '${digits.substring(0, decimal)}.${digits.substring(decimal)}';
  }
  return negative ? '-$expanded' : expanded;
}
