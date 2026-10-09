// Current linear-gradient invariants shared by wire and runtime validation.
//
// The typed model remains permissive so document validation can report every
// issue rather than throwing during construction. Historical formats do not
// use this validator.
import 'package:canvas_core/src/foundation/core_types.dart'
    show LinearGradientSpec;

enum GradientSemanticCode {
  nonFiniteNumber,
  valueOutOfRange,
  invalidColor,
  degenerateGradient,
  invalidGradientStopCount,
  gradientStopsOutOfOrder,
}

/// A diagnostic relative to a gradient's root, with JSON Pointer-style paths.
final class GradientSemanticIssue {
  const GradientSemanticIssue({
    required this.code,
    required this.path,
    required this.message,
    this.relatedPath,
  });

  final GradientSemanticCode code;
  final String path;
  final String message;
  final String? relatedPath;
}

/// Validates current gradient geometry, ordered stops, and ARGB colors.
///
/// Preserves authored duplicate offsets for hard transitions and the stable
/// issue order used by scene-document validation.
List<GradientSemanticIssue> validateLinearGradientSemantics(
  LinearGradientSpec gradient,
) {
  final issues = <GradientSemanticIssue>[];

  void add(
    GradientSemanticCode code,
    String path,
    String message, {
    String? relatedPath,
  }) {
    issues.add(
      GradientSemanticIssue(
        code: code,
        path: path,
        message: message,
        relatedPath: relatedPath,
      ),
    );
  }

  bool finite(double value, String path) {
    if (value.isFinite) return true;
    add(
      GradientSemanticCode.nonFiniteNumber,
      path,
      'Numeric value must be finite.',
    );
    return false;
  }

  final startX = finite(gradient.start.x, '/start/x');
  final startY = finite(gradient.start.y, '/start/y');
  final endX = finite(gradient.end.x, '/end/x');
  final endY = finite(gradient.end.y, '/end/y');

  if (startX && startY && endX && endY && gradient.start == gradient.end) {
    add(
      GradientSemanticCode.degenerateGradient,
      '/end',
      'Gradient start and end points must differ.',
      relatedPath: '/start',
    );
  }

  if (gradient.stops.length < 2) {
    add(
      GradientSemanticCode.invalidGradientStopCount,
      '/stops',
      'A gradient must contain at least two stops.',
    );
  }

  double? previousOffset;
  String? previousPath;
  for (var index = 0; index < gradient.stops.length; index++) {
    final stop = gradient.stops[index];
    final stopPath = '/stops/$index';
    final offsetPath = '$stopPath/offset';
    if (finite(stop.offset, offsetPath)) {
      if (stop.offset < 0 || stop.offset > 1) {
        add(
          GradientSemanticCode.valueOutOfRange,
          offsetPath,
          'Numeric value must be between 0 and 1.',
        );
      }
      if (previousOffset != null && stop.offset < previousOffset) {
        add(
          GradientSemanticCode.gradientStopsOutOfOrder,
          offsetPath,
          'Gradient stop offsets must be nondecreasing.',
          relatedPath: previousPath,
        );
      }
      previousOffset = stop.offset;
      previousPath = offsetPath;
    }

    if (stop.color < 0 || stop.color > 0xFFFFFFFF) {
      add(
        GradientSemanticCode.invalidColor,
        '$stopPath/color',
        'Color must be a 32-bit ARGB value.',
      );
    }
  }

  return issues;
}
