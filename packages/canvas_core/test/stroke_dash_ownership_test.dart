import 'dart:convert';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

void main() {
  test('construction owns dash values independently of the caller', () {
    final input = <double>[5, 0, 3];
    final stroke = CanvasStroke(color: 0x00123456, width: 0, dash: input);
    final equal = CanvasStroke(color: 0x00123456, width: 0, dash: [5, 0, 3]);
    final hash = stroke.hashCode;
    final encoded = jsonEncode(stroke.toJson());
    final values = {stroke};

    input[0] = 99;
    input.clear();

    expect(stroke.dash, [5, 0, 3]);
    expect(stroke, equal);
    expect(stroke.hashCode, hash);
    expect(values.contains(equal), isTrue);
    expect(jsonEncode(stroke.toJson()), encoded);
    expect(() => stroke.dash[0] = 99, throwsUnsupportedError);
    expect(() => stroke.dash.add(1), throwsUnsupportedError);
  });

  test('copyWith owns replacement dashes and preserves other settings', () {
    final original = CanvasStroke(
      color: 0x00123456,
      width: 0,
      cap: StrokeCap.square,
      join: StrokeJoin.bevel,
      miterLimit: 7,
      dash: [2, 0, 3],
    );
    final replacement = <double>[8, 0, 5];
    final copied = original.copyWith(dash: replacement);
    final scalarEdit = copied.copyWith(width: 12);
    replacement.clear();

    expect(original.dash, [2, 0, 3]);
    expect(copied.dash, [8, 0, 5]);
    expect(scalarEdit.dash, [8, 0, 5]);
    expect(copied.color, original.color);
    expect(copied.width, 0);
    expect(copied.cap, original.cap);
    expect(copied.join, original.join);
    expect(copied.miterLimit, original.miterLimit);
    expect(() => copied.dash.clear(), throwsUnsupportedError);
  });

  test('nested appearance copies also snapshot replacement dashes', () {
    final appearance = CanvasAppearance(
      stroke: CanvasStroke(color: 0xFF112233, dash: [5, 3]),
    );
    final replacement = <double>[7, 0, 3];
    final copied = appearance.copyWith.stroke!.call(dash: replacement);
    replacement[0] = 99;

    expect(appearance.stroke!.dash, [5, 3]);
    expect(copied.stroke!.dash, [7, 0, 3]);
  });

  test('JSON construction preserves defaults and authored dash values', () {
    final defaults = CanvasStroke.fromJson({'color': 0});
    expect(defaults, CanvasStroke(color: 0));
    expect(defaults.toJson(), {
      'color': 0,
      'width': 4.0,
      'cap': 'butt',
      'join': 'miter',
      'miterLimit': 4.0,
      'dash': <double>[],
    });

    final input = <double>[5, 0, 3];
    final stroke = CanvasStroke.fromJson({
      'color': 0x00123456,
      'width': 0,
      'cap': 'round',
      'join': 'bevel',
      'miterLimit': 7,
      'dash': input,
    });
    final wire =
        jsonDecode(jsonEncode(stroke.toJson())) as Map<String, dynamic>;
    input.clear();

    expect(stroke.dash, [5, 0, 3]);
    expect(CanvasStroke.fromJson(wire), stroke);
    expect(stroke.color, 0x00123456);
    expect(stroke.width, 0);
    expect(() => stroke.dash.clear(), throwsUnsupportedError);
  });
}
