import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;
import 'package:canvas_core/src/foundation/style/style_types.dart'
    show FillRule;
import 'package:canvas_core/src/path/path_compile.dart' show PathCompiler;
import 'package:canvas_core/src/path/path_source.dart';

/// Synchronous lookup into the host's selected resource session.
/// Downloads and source normalization happen before scene evaluation.
abstract interface class IconResolver {
  ResolvedIcon? resolve(String iconRef);
}

/// A filled, recolorable vector symbol in its declared source viewBox.
///
/// Geometry has no paint or font dependency. Primitive sources are normalized
/// once at resource construction; command sources are already immutable.
/// Open contours use ordinary filled-path implicit closure. Empty geometry is
/// valid and keeps the instance's layout square without producing paint.
final class ResolvedIcon {
  factory ResolvedIcon({
    required PathSource source,
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
    if (source is SvgPathSource) {
      throw ArgumentError(
        'Icon SVG paths must be normalized before resolution.',
      );
    }
    if (source case RegularPolygonSource(:final sides) when sides < 3) {
      throw ArgumentError('An icon polygon requires at least three sides.');
    }
    if (source case StarSource(
      :final points,
      :final rOuter,
      :final rInner,
    ) when points < 3 || rOuter < 0 || rInner < 0 || rInner > rOuter) {
      throw ArgumentError('Invalid icon star geometry.');
    }
    final CommandPathSource geometry;
    if (source is CommandPathSource) {
      geometry = source;
    } else {
      _requireFinite(source.toJson());
      geometry = CommandPathSource(
        const PathCompiler().fromSource(source).cmds,
      );
    }
    return ResolvedIcon._(geometry, viewBox, fillRule);
  }

  const ResolvedIcon._(this.source, this.viewBox, this.fillRule);

  final CommandPathSource source;
  final Rect2D viewBox;
  final FillRule fillRule;

  static void _requireFinite(Object? value) {
    if (value is num && !value.isFinite) {
      throw ArgumentError('Icon geometry must contain finite numbers.');
    }
    if (value is Map) {
      for (final child in value.values) {
        _requireFinite(child);
      }
    } else if (value is Iterable) {
      for (final child in value) {
        _requireFinite(child);
      }
    }
  }
}
