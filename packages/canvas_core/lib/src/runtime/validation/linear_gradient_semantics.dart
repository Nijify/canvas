import 'package:canvas_core/src/foundation/core_types.dart'
    show LinearGradientSpec;

/// Shared current-format gradient semantics; duplicate offsets are valid.
void requireLinearGradientIntegrity(
  LinearGradientSpec gradient, {
  String context = 'gradient',
}) {
  Never fail(String field, String message) =>
      throw ArgumentError('$context/$field: $message');

  void finite(double value, String field) {
    if (!value.isFinite) fail(field, 'Numeric value must be finite.');
  }

  finite(gradient.start.x, 'start/x');
  finite(gradient.start.y, 'start/y');
  finite(gradient.end.x, 'end/x');
  finite(gradient.end.y, 'end/y');
  if (gradient.start == gradient.end) {
    fail('end', 'Gradient start and end points must differ.');
  }
  if (gradient.stops.length < 2) {
    fail('stops', 'A gradient must contain at least two stops.');
  }

  double? previousOffset;
  for (var index = 0; index < gradient.stops.length; index++) {
    final stop = gradient.stops[index];
    finite(stop.offset, 'stops/$index/offset');
    if (stop.offset < 0 || stop.offset > 1) {
      fail('stops/$index/offset', 'Stop offset must be between 0 and 1.');
    }
    if (previousOffset != null && stop.offset < previousOffset) {
      fail(
        'stops/$index/offset',
        'Gradient stop offsets must be nondecreasing.',
      );
    }
    if (stop.color < 0 || stop.color > 0xFFFFFFFF) {
      fail('stops/$index/color', 'Color must be a 32-bit ARGB value.');
    }
    previousOffset = stop.offset;
  }
}
