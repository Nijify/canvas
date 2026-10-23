import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;
import 'package:canvas_core/src/foundation/style/style_types.dart'
    show FillRule;
import 'package:canvas_core/src/path/path_ir.dart' show PathIR;

/// Synchronous lookup into the host's selected resource session.
/// Downloads and source normalization happen before scene evaluation.
abstract interface class IconResolver {
  ResolvedIcon? resolve(String iconRef);
}

/// A filled, recolorable vector symbol in its declared source viewBox.
///
/// Hosts supply normalized [PathIR] geometry, which already validates
/// coordinates and contour order and snapshots its commands. The resource has
/// no paint or font dependency.
/// Open contours use ordinary filled-path implicit closure. Empty geometry is
/// valid and keeps the instance's layout square without producing paint.
final class ResolvedIcon {
  factory ResolvedIcon({
    required PathIR pathIR,
    required Rect2D viewBox,
    required FillRule fillRule,
  }) {
    if (![
          viewBox.left,
          viewBox.top,
          viewBox.right,
          viewBox.bottom,
          viewBox.width,
          viewBox.height,
        ].every((value) => value.isFinite) ||
        viewBox.width <= 0 ||
        viewBox.height <= 0) {
      throw ArgumentError.value(
        viewBox,
        'viewBox',
        'Must be finite and positive.',
      );
    }
    return ResolvedIcon._(pathIR, viewBox, fillRule);
  }

  const ResolvedIcon._(this.pathIR, this.viewBox, this.fillRule);

  final PathIR pathIR;
  final Rect2D viewBox;
  final FillRule fillRule;
}
