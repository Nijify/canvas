// Path: lib/src/runtime/validation/scene_document_validation.dart

import 'dart:collection';

import 'package:canvas_core/src/foundation/ids.dart' show CanvasAssetId;
import 'package:canvas_core/src/foundation/paint/canvas_fill.dart';
import 'package:canvas_core/src/runtime/validation/linear_gradient_semantics.dart';
import 'package:canvas_core/src/path/path_source.dart';
import 'package:canvas_core/src/runtime/model/node_model.dart';
import 'package:canvas_core/src/runtime/model/canvas_appearance.dart';
import 'package:canvas_core/src/runtime/model/canvas_stroke.dart';
import 'package:canvas_core/src/runtime/model/scene_document.dart';

/// Rejects invalid generic scene data before recursive processing or resource work.
///
/// Throws [ArgumentError] at the first integrity failure. Error messages provide
/// context for people; their wording, locations, and traversal order are not a
/// stable diagnostic API. Component availability is owned by the caller.
void requireCanvasSceneIntegrity(CanvasSceneDocument document) {
  _SceneValidator().validate(document);
}

final class _SceneValidator {
  final Set<String> _nodeIds = <String>{};
  final HashSet<Node> _activeNodes = HashSet<Node>.identity();
  final HashSet<Object> _activeBehaviorContainers = HashSet<Object>.identity();
  Map<CanvasAssetId, CanvasImageAsset> _assets =
      const <CanvasAssetId, CanvasImageAsset>{};

  void validate(CanvasSceneDocument document) {
    _assets = document.assets;

    _validatePositive(document.artboardSize.w, '/artboardSize/w');
    _validatePositive(document.artboardSize.h, '/artboardSize/h');
    _validateFill(document.backgroundFill, '/backgroundFill');
    _validateRange(document.backgroundOpacity, '/backgroundOpacity', 0, 1);

    for (final entry in document.assets.entries) {
      _validateImageAsset(entry.key, entry.value, '/assets/${entry.key}');
    }

    for (var index = 0; index < document.children.length; index++) {
      _validateNode(document.children[index], '/children/$index');
    }
  }

  void _validateImageAsset(
    CanvasAssetId assetId,
    CanvasImageAsset asset,
    String path,
  ) {
    if (assetId.trim().isEmpty) {
      _fail(path, 'Asset ID must be nonblank.');
    }

    if (asset.sourceRef.trim().isEmpty) {
      _fail(
        '$path/sourceRef',
        'Image asset source reference must be nonblank.',
      );
    }

    final intrinsicSize = asset.intrinsicSize;
    if (intrinsicSize != null) {
      _validatePositive(intrinsicSize.w, '$path/intrinsicSize/w');
      _validatePositive(intrinsicSize.h, '$path/intrinsicSize/h');
    }
  }

  void _validateNode(Node node, String path) {
    if (!_activeNodes.add(node)) {
      _fail(path, 'Scene node graph contains a cycle.');
    }

    try {
      final (label, expected) = switch (node) {
        TextNode(:final $type) => ($type, 'text'),
        ImageNode(:final $type) => ($type, 'image'),
        PathNode(:final $type) => ($type, 'path'),
        IconNode(:final $type) => ($type, 'icon'),
        GroupNode(:final $type) => ($type, 'group'),
      };
      if (label != expected) {
        _fail(
          '$path/runtimeType',
          'Expected $expected node label; got $label.',
        );
      }
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
      _fail(path, 'Node ID must be nonblank.');
    }

    if (!_nodeIds.add(id)) {
      _fail(path, 'Node ID must be globally unique within the document.');
    }
  }

  void _validateName(String? name, String path) {
    if (name != null && name.runes.length > 80) {
      _fail(path, 'Node name must be at most 80 characters.');
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
    _validateAppearance(data.appearance, '$path/appearance');
  }

  void _validateIconData(CanvasIconData data, String path) {
    _validatePositive(data.sizePx, '$path/sizePx');
    _validateAppearance(data.appearance, '$path/appearance');
  }

  void _validateAppearance(
    CanvasAppearance appearance,
    String path, {
    bool supportsStroke = false,
    bool supportsUnderlays = true,
  }) {
    _validateFill(appearance.foreground, '$path/foreground');

    final stroke = appearance.stroke;
    if (stroke != null) {
      if (!supportsStroke) {
        _fail('$path/stroke', 'This node does not support stroke.');
      }
      _validateStroke(stroke, '$path/stroke');
    }

    if (!supportsUnderlays && appearance.underlays.isNotEmpty) {
      _fail(
        '$path/underlays',
        'This node does not support appearance underlays.',
      );
    }
    _validateUnderlays(appearance.underlays, '$path/underlays');
  }

  void _validateStroke(CanvasStroke stroke, String path) {
    // Invisible configurations remain authored data and are still validated.
    _validateColor(stroke.color, '$path/color');
    _validateNonNegative(stroke.width, '$path/width');
    _validateFinite(stroke.miterLimit, '$path/miterLimit');
    if (stroke.miterLimit < 1) {
      _fail('$path/miterLimit', 'Stroke miter limit must be at least 1.');
    }

    for (var index = 0; index < stroke.dash.length; index++) {
      _validateNonNegative(stroke.dash[index], '$path/dash/$index');
    }
  }

  void _validateUnderlays(List<CanvasSourceUnderlay> underlays, String path) {
    final ids = <String>{};

    for (var index = 0; index < underlays.length; index++) {
      final underlay = underlays[index];
      final itemPath = '$path/$index';

      switch (underlay) {
        case ShadowEffect(
          :final id,
          :final offset,
          :final blurSigma,
          :final color,
        ):
          final idPath = '$itemPath/id';

          if (id.trim().isEmpty) {
            _fail(idPath, 'Appearance underlay ID must be nonblank.');
          }
          if (!ids.add(id)) {
            _fail(
              idPath,
              'Appearance underlay ID must be unique within its appearance.',
            );
          }

          // Disabled effects remain valid authored data and are still validated.
          _validateFinite(offset.x, '$itemPath/offset/x');
          _validateFinite(offset.y, '$itemPath/offset/y');
          _validateNonNegative(blurSigma, '$itemPath/blurSigma');
          _validateColor(color, '$itemPath/color');
      }
    }
  }

  void _validateImageData(ImageData data, String path) {
    _validatePositive(data.size.w, '$path/size/w');
    _validatePositive(data.size.h, '$path/size/h');

    final assetId = data.assetId;
    if (assetId != null && !_assets.containsKey(assetId)) {
      _fail(
        '$path/assetId',
        'Image asset reference must resolve in the document asset registry.',
      );
    }

    _validateRange(data.align.x, '$path/align/x', 0, 1);
    _validateRange(data.align.y, '$path/align/y', 0, 1);
  }

  void _validatePathData(PathData data, String path) {
    _validatePathSource(data.source, '$path/source');
    _validateAppearance(
      data.appearance,
      '$path/appearance',
      supportsStroke: true,
      supportsUnderlays: false,
    );
  }

  void _validatePathSource(PathSource source, String path) {
    try {
      requirePathSourceIntegrity(source);
    } on ArgumentError catch (error) {
      _fail(path, error.message.toString());
    }
  }

  void _validateBehavior(GroupBehaviorRef behavior, String path) {
    if (behavior.type.trim().isEmpty) {
      _fail('$path/type', 'Behavior type must be nonblank.');
    }

    if (behavior.version < 1) {
      _fail('$path/version', 'Behavior version must be at least 1.');
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
        _fail(path, 'Behavior data contains a cyclic list or map.');
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
        _fail(path, 'Behavior data contains a cyclic list or map.');
      }

      try {
        if (value.keys.any((key) => key is! String)) {
          _fail(path, 'Behavior data maps must contain only string keys.');
        }

        for (final entry in value.entries) {
          _validateJsonValue(entry.value, '$path/${entry.key}');
        }
      } finally {
        _activeBehaviorContainers.remove(value);
      }
      return;
    }

    _fail(
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
        requireLinearGradientIntegrity(grad, context: '$path/grad');
    }
  }

  void _validateColor(int color, String path) {
    if (color < 0 || color > 0xFFFFFFFF) {
      _fail(path, 'Color must be a 32-bit ARGB value.');
    }
  }

  void _validateFinite(num value, String path) {
    if (!value.isFinite) _fail(path, 'Numeric value must be finite.');
  }

  void _validatePositive(num value, String path) {
    _validateFinite(value, path);
    if (value <= 0) {
      _fail(path, 'Numeric value must be greater than zero.');
    }
  }

  void _validateNonNegative(num value, String path) {
    _validateFinite(value, path);
    if (value < 0) {
      _fail(path, 'Numeric value must be nonnegative.');
    }
  }

  void _validateRange(num value, String path, num min, num max) {
    _validateFinite(value, path);
    if (value < min || value > max) {
      _fail(path, 'Numeric value must be between $min and $max.');
    }
  }

  Never _fail(String path, String message) =>
      throw ArgumentError('$path: $message');
}
