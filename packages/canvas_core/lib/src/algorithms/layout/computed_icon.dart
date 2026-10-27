import 'dart:math' as math;

import 'package:canvas_core/src/foundation/style/style_types.dart'
    show FillRule;
import 'package:canvas_core/src/path/path_ir.dart' show PathIR;
import 'package:canvas_core/src/services/icon_resolver.dart' show ResolvedIcon;
import 'package:canvas_core/src/foundation/math/affine2d.dart';

/// Evaluated icon geometry and its centered, uniform viewBox fit.
/// Commands stay in source coordinates; appearance is authored in node-local
/// coordinates and is applied after fitting the source.
final class ComputedIcon {
  factory ComputedIcon.fit(ResolvedIcon icon, double sizePx) {
    if (!sizePx.isFinite || sizePx <= 0) {
      throw ArgumentError.value(
        sizePx,
        'sizePx',
        'Must be finite and positive.',
      );
    }
    final box = icon.viewBox;
    final scale = math.min(sizePx / box.width, sizePx / box.height);
    final x = -scale * (box.left / 2 + box.right / 2);
    final y = -scale * (box.top / 2 + box.bottom / 2);
    if (!scale.isFinite || scale <= 0 || !x.isFinite || !y.isFinite) {
      throw ArgumentError(
        'Icon fitting must be representable as finite geometry.',
      );
    }
    final sourceToLocal = Affine2D.translation(x, y) * Affine2D.scale(scale);
    return ComputedIcon._(icon.pathIR, sourceToLocal, icon.fillRule);
  }

  const ComputedIcon._(this.pathIR, this.sourceToLocal, this.fillRule);

  final PathIR pathIR;
  final Affine2D sourceToLocal;
  final FillRule fillRule;
}
