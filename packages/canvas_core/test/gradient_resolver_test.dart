// Path: test/gradient_resolver_test.dart

import 'package:test/test.dart';
import 'package:canvas_core/canvas_core_runtime.dart';

void main() {
  test('angle/opacity applied', () {
    final r = resolveLinearGradient(
      const LinearGradientSpec(
        color1: 0x80FF0000,
        color2: 0x80FF0000,
        angle: 90,
        width: 10,
      ),
      const Size2D(100, 50),
      opacity: 0.5,
    );
    expect((r.colors.first >> 24), closeTo(0x40, 1)); // 0x80 * 0.5 = ~0x40
    expect(r.stops.length, 2);
  });
}
