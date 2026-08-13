// Path: lib/src/runtime/validation/scene_document_validation.dart

import 'dart:collection';

import 'package:canvas_core/src/foundation/paint/canvas_fill.dart';
import 'package:canvas_core/src/path/path_source.dart';
import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/runtime/model/scene_document.dart';

/// Stable machine-readable categories returned by scene validation.
enum CanvasSceneValidationCode {
  nonFiniteNumber,
  valueOutOfRange,
  invalidColor,
  blankNodeId,
  duplicateNodeId,
  nameTooLong,
  invalidTextFill,
  invalidIconFill,
  invalidBehaviorType,
  invalidBehaviorVersion,
  nonJsonBehaviorValue,
  cyclicBehaviorData,
  cyclicNodeGraph,
}

/// One deterministic validation diagnostic for a [CanvasSceneDocument].
///
/// [code], [path], and [relatedPath] are suitable for machine consumption.
/// [message] is human-readable diagnostic text and should not be treated as a
/// stable API contract.
final class CanvasSceneValidationIssue {
  const CanvasSceneValidationIssue({
    required this.code,
    required this.path,
    required this.message,
    this.relatedPath,
  });

  final CanvasSceneValidationCode code;
  final String path;
  final String message;

  /// A second JSON Pointer location when the issue relates two scene values.
  final String? relatedPath;
}

/// Validate generic runtime-scene integrity without interpreting component
/// semantics.
///
/// Validation is pure and accumulates all discoverable issues in deterministic
/// order. Unknown [GroupBehaviorRef] types and versions are valid as long as
/// their neutral envelope and JSON data are well formed.
List<CanvasSceneValidationIssue> validateCanvasSceneDocument(
  CanvasSceneDocument document,
) {
  final validator = _SceneValidator();
  validator.validate(document);
  return List<CanvasSceneValidationIssue>.unmodifiable(validator.issues);
}

final class _SceneValidator {
  final List<CanvasSceneValidationIssue> issues =
      <CanvasSceneValidationIssue>[];
  final Map<String, String> _firstNodeIdPath = <String, String>{};
  final HashSet<Node> _activeNodes = HashSet<Node>.identity();
  final HashSet<Object> _activeBehaviorContainers = HashSet<Object>.identity();

  void validate(CanvasSceneDocument document) {
    _validatePositive(document.artboardSize.w, '/artboardSize/w');
    _validatePositive(document.artboardSize.h, '/artboardSize/h');
    _validateFill(document.backgroundFill, '/backgroundFill');
    _validateRange(document.backgroundOpacity, '/backgroundOpacity', 0, 1);

    for (var index = 0; index < document.children.length; index++) {
      _validateNode(document.children[index], '/children/$index');
    }
  }

  void _validateNode(Node node, String path) {
    if (!_activeNodes.add(node)) {
      _add(
        CanvasSceneValidationCode.cyclicNodeGraph,
        path,
        'Scene node graph contains a cycle.',
      );
      return;
    }

    try {
      _validateNodeId(node.id, '$path/id');
      _validateName(node.name, '$path/name');
      _validateTransform(node.xf, '$path/xf');

      switch (node) {
        case TextNode(:final data):
          _validateTextData(data, '$path/data');
        case IconNode(:final data):
          _validateIconData(data, '$path/data');
        case ImageNode(:final data):
          _validateImageData(data, '$path/data');
        case PathNode(:final data):
          _validatePathData(data, '$path/data');
        case GroupNode(:final behavior, :final children):
          if (behavior != null) {
            _validateBehavior(behavior, '$path/behavior');
          }
          for (var index = 0; index < children.length; index++) {
            _validateNode(children[index], '$path/children/$index');
          }
      }
    } finally {
      _activeNodes.remove(node);
    }
  }

  void _validateNodeId(String id, String path) {
    if (id.trim().isEmpty) {
      _add(
        CanvasSceneValidationCode.blankNodeId,
        path,
        'Node ID must be nonblank.',
      );
      return;
    }

    final firstPath = _firstNodeIdPath[id];
    if (firstPath == null) {
      _firstNodeIdPath[id] = path;
      return;
    }

    _add(
      CanvasSceneValidationCode.duplicateNodeId,
      path,
      'Node ID must be globally unique within the document.',
      relatedPath: firstPath,
    );
  }

  void _validateName(String? name, String path) {
    if (name != null && name.runes.length > 80) {
      _add(
        CanvasSceneValidationCode.nameTooLong,
        path,
        'Node name must be at most 80 characters.',
      );
    }
  }

  void _validateTransform(Transform2D transform, String path) {
    _validateFinite(transform.position.x, '$path/position/x');
    _validateFinite(transform.position.y, '$path/position/y');
    _validateFinite(transform.rotationRad, '$path/rotationRad');
    _validateFinite(transform.scale.x, '$path/scale/x');
    _validateFinite(transform.scale.y, '$path/scale/y');

    final pivot = transform.customPivotPx;
    if (pivot != null) {
      _validateFinite(pivot.x, '$path/customPivotPx/x');
      _validateFinite(pivot.y, '$path/customPivotPx/y');
    }
  }

  void _validateTextData(TextData data, String path) {
    _validateFinite(data.fontSize, '$path/fontSize');
    _validateFinite(data.letterSpacing, '$path/letterSpacing');

    if (data.fill is CanvasFillNone) {
      _add(
        CanvasSceneValidationCode.invalidTextFill,
        '$path/fill',
        'Text fill cannot be none.',
      );
    } else {
      _validateFill(data.fill, '$path/fill');
    }

    _validateFinite(data.shadowOffset, '$path/shadowOffset');
  }

  void _validateIconData(CanvasIconData data, String path) {
    _validateFinite(data.sizePx, '$path/sizePx');

    if (data.fill is CanvasFillNone) {
      _add(
        CanvasSceneValidationCode.invalidIconFill,
        '$path/fill',
        'Icon fill cannot be none.',
      );
    } else {
      _validateFill(data.fill, '$path/fill');
    }

    _validateFinite(data.shadowOffset, '$path/shadowOffset');
  }

  void _validateImageData(ImageData data, String path) {
    final size = data.size;
    if (size != null) {
      _validatePositive(size.w, '$path/size/w');
      _validatePositive(size.h, '$path/size/h');
    }

    _validateRange(data.align.x, '$path/align/x', 0, 1);
    _validateRange(data.align.y, '$path/align/y', 0, 1);
  }

  void _validatePathData(PathData data, String path) {
    for (var index = 0; index < data.points.length; index++) {
      final point = data.points[index];
      if (point == null) continue;
      _validateFinite(point.x, '$path/points/$index/x');
      _validateFinite(point.y, '$path/points/$index/y');
    }

    final source = data.source;
    if (source != null) {
      _validatePathSource(source, '$path/source');
    }

    _validateFill(data.fill, '$path/fill');
    _validateColor(data.strokeColor, '$path/strokeColor');
    _validateNonNegative(data.strokeWidth, '$path/strokeWidth');
    _validateNonNegative(data.miterLimit, '$path/miterLimit');

    for (var index = 0; index < data.dash.length; index++) {
      _validateNonNegative(data.dash[index], '$path/dash/$index');
    }
  }

  void _validatePathSource(PathSource source, String path) {
    switch (source) {
      case PolylineSource(:final points):
        for (var index = 0; index < points.length; index++) {
          final point = points[index];
          if (point == null) continue;
          _validateFinite(point.x, '$path/points/$index/x');
          _validateFinite(point.y, '$path/points/$index/y');
        }
      case CircleSource(:final r):
        _validateFinite(r, '$path/r');
      case RegularPolygonSource(:final sides, :final r, :final rotation):
        if (sides < 3) {
          _add(
            CanvasSceneValidationCode.valueOutOfRange,
            '$path/sides',
            'Regular polygon side count must be at least 3.',
          );
        }
        _validateFinite(r, '$path/r');
        _validateFinite(rotation, '$path/rotation');
      case StarSource(
        :final points,
        :final rOuter,
        :final rInner,
        :final rotation,
      ):
        if (points < 3) {
          _add(
            CanvasSceneValidationCode.valueOutOfRange,
            '$path/points',
            'Star point count must be at least 3.',
          );
        }
        final outerFinite = _validateFinite(rOuter, '$path/rOuter');
        final innerFinite = _validateFinite(rInner, '$path/rInner');
        if (outerFinite && rOuter < 0) {
          _add(
            CanvasSceneValidationCode.valueOutOfRange,
            '$path/rOuter',
            'Star outer radius must be nonnegative.',
          );
        }
        if (innerFinite && outerFinite && (rInner < 0 || rInner > rOuter)) {
          _add(
            CanvasSceneValidationCode.valueOutOfRange,
            '$path/rInner',
            'Star inner radius must be between 0 and the outer radius.',
          );
        }
        _validateFinite(rotation, '$path/rotation');
      case RectSource(:final w, :final h):
        _validateFinite(w, '$path/w');
        _validateFinite(h, '$path/h');
      case RoundRectSource(:final w, :final h, :final rx, :final ry):
        _validateFinite(w, '$path/w');
        _validateFinite(h, '$path/h');
        _validateFinite(rx, '$path/rx');
        _validateFinite(ry, '$path/ry');
      case PillSource(:final w, :final h):
        _validateFinite(w, '$path/w');
        _validateFinite(h, '$path/h');
      case UnderlineSource(:final w, :final thickness):
        _validateFinite(w, '$path/w');
        _validateFinite(thickness, '$path/thickness');
      case EllipseSource(:final rx, :final ry):
        _validateFinite(rx, '$path/rx');
        _validateFinite(ry, '$path/ry');
      case SvgPathSource():
        break;
    }
  }

  void _validateBehavior(GroupBehaviorRef behavior, String path) {
    if (behavior.type.trim().isEmpty) {
      _add(
        CanvasSceneValidationCode.invalidBehaviorType,
        '$path/type',
        'Behavior type must be nonblank.',
      );
    }

    if (behavior.version < 1) {
      _add(
        CanvasSceneValidationCode.invalidBehaviorVersion,
        '$path/version',
        'Behavior version must be at least 1.',
      );
    }

    _validateJsonValue(behavior.data, '$path/data');
  }

  void _validateJsonValue(Object? value, String path) {
    if (value == null || value is bool || value is String || value is int) {
      return;
    }

    if (value is num) {
      _validateFinite(value, path);
      return;
    }

    if (value is List) {
      if (!_activeBehaviorContainers.add(value)) {
        _add(
          CanvasSceneValidationCode.cyclicBehaviorData,
          path,
          'Behavior data contains a cyclic list or map.',
        );
        return;
      }

      try {
        for (var index = 0; index < value.length; index++) {
          _validateJsonValue(value[index], '$path/$index');
        }
      } finally {
        _activeBehaviorContainers.remove(value);
      }
      return;
    }

    if (value is Map) {
      if (!_activeBehaviorContainers.add(value)) {
        _add(
          CanvasSceneValidationCode.cyclicBehaviorData,
          path,
          'Behavior data contains a cyclic list or map.',
        );
        return;
      }

      try {
        if (value.keys.any((key) => key is! String)) {
          _add(
            CanvasSceneValidationCode.nonJsonBehaviorValue,
            path,
            'Behavior data maps must contain only string keys.',
          );
        }

        final keys = value.keys.whereType<String>().toList()..sort();
        for (final key in keys) {
          _validateJsonValue(value[key], '$path/${_pointerSegment(key)}');
        }
      } finally {
        _activeBehaviorContainers.remove(value);
      }
      return;
    }

    _add(
      CanvasSceneValidationCode.nonJsonBehaviorValue,
      path,
      'Behavior data contains a non-JSON value of type ${value.runtimeType}.',
    );
  }

  void _validateFill(CanvasFill fill, String path) {
    switch (fill) {
      case CanvasFillNone():
        break;
      case CanvasFillSolid(:final color):
        _validateColor(color, '$path/color');
      case CanvasFillGradient(:final grad):
        _validateColor(grad.color1, '$path/grad/color1');
        _validateColor(grad.color2, '$path/grad/color2');
        _validateFinite(grad.angle, '$path/grad/angle');
        _validateRange(grad.width, '$path/grad/width', 0, 50);
    }
  }

  void _validateColor(int color, String path) {
    if (color < 0 || color > 0xFFFFFFFF) {
      _add(
        CanvasSceneValidationCode.invalidColor,
        path,
        'Color must be a 32-bit ARGB value.',
      );
    }
  }

  bool _validateFinite(num value, String path) {
    if (value.isFinite) return true;

    _add(
      CanvasSceneValidationCode.nonFiniteNumber,
      path,
      'Numeric value must be finite.',
    );
    return false;
  }

  void _validatePositive(num value, String path) {
    if (!_validateFinite(value, path)) return;
    if (value <= 0) {
      _add(
        CanvasSceneValidationCode.valueOutOfRange,
        path,
        'Numeric value must be greater than zero.',
      );
    }
  }

  void _validateNonNegative(num value, String path) {
    if (!_validateFinite(value, path)) return;
    if (value < 0) {
      _add(
        CanvasSceneValidationCode.valueOutOfRange,
        path,
        'Numeric value must be nonnegative.',
      );
    }
  }

  void _validateRange(num value, String path, num min, num max) {
    if (!_validateFinite(value, path)) return;
    if (value < min || value > max) {
      _add(
        CanvasSceneValidationCode.valueOutOfRange,
        path,
        'Numeric value must be between $min and $max.',
      );
    }
  }

  void _add(
    CanvasSceneValidationCode code,
    String path,
    String message, {
    String? relatedPath,
  }) {
    issues.add(
      CanvasSceneValidationIssue(
        code: code,
        path: path,
        message: message,
        relatedPath: relatedPath,
      ),
    );
  }
}

String _pointerSegment(String value) =>
    value.replaceAll('~', '~0').replaceAll('/', '~1');
