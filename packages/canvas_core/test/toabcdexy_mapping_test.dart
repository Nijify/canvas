// Path: test/toabcdexy_mapping_test.dart
import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import 'package:canvas_core/src/foundation/math/affine2d.dart';

void main() {
  test('toABCDExy maps column-major Matrix4 to Canvas2D [a,b,c,d,e,f]', () {
    // Build a known 2D affine in column-major:
    // | a c 0 e |
    // | b d 0 f |
    // | 0 0 1 0 |
    // | 0 0 0 1 |
    final m = vm.Matrix4.zero();
    const a = 0.8, b = 0.1, c = -0.3, d = 1.2, e = 12.0, f = -7.0;
    m.setEntry(0, 0, a);
    m.setEntry(1, 0, b);
    m.setEntry(0, 1, c);
    m.setEntry(1, 1, d);
    m.setEntry(0, 3, e);
    m.setEntry(1, 3, f);
    final (six: s) = toABCDExy(m);
    expect(s[0], equals(a));
    expect(s[1], equals(b));
    expect(s[2], equals(c));
    expect(s[3], equals(d));
    expect(s[4], equals(e));
    expect(s[5], equals(f));
  });
}
