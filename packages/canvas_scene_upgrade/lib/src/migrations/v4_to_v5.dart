import 'package:canvas_core/canvas_core_runtime.dart';

import '../formats/scene_v4.dart';

/// Bake v4 TRS and pivots into local affine matrices using historical layout.
Map<String, Object?> convertCanvasSceneV4ToV5(
  Map<String, Object?> input, {
  CoreServices? services,
  Size2D? Function(String sourceRef)? resolveImageIntrinsicSize,
}) {
  validateSceneV4Json(input);
  final assets = input['assets'] as Map?;
  final roots = input['children'] as List;

  ({Map<String, Object?> json, Affine2D xf, Rect2D? bounds}) convert(
    Map<String, Object?> node, {
    bool needsBounds = false,
    bool ancestorHidden = false,
  }) {
    final type = node['runtimeType'];
    final id = node['id'] as String;
    final hidden = ancestorHidden || node['hidden'] == true;
    final legacy = node['xf'] as Map? ?? const {};
    final position = _point(legacy['position'], Vec2.zero);
    final scale = _point(legacy['scale'], const Vec2(1, 1));
    final rotation = _number(legacy['rotationRad'], 0);
    final customPivot = _point(legacy['customPivotPx'], Vec2.zero);
    final hasLinearTransform = rotation != 0 || scale != const Vec2(1, 1);
    final useCenter = hasLinearTransform && legacy['origin'] != 'custom';
    final measure =
        !hidden &&
        (needsBounds || (useCenter && type != 'text' && type != 'icon'));

    final output = Map<String, Object?>.of(node)..remove('xf');
    Rect2D? bounds;
    if (type == 'group') {
      final children = <Map<String, Object?>>[];
      for (final raw in node['children'] as List) {
        final child = convert(
          Map<String, Object?>.from(raw as Map),
          needsBounds: measure,
          ancestorHidden: hidden,
        );
        children.add(child.json);
        final childBounds = child.bounds;
        if (measure && childBounds != null) {
          final placed = aabbOfTransformedRect(childBounds, child.xf);
          bounds = bounds == null ? placed : Rect2DX.union(bounds, placed);
        }
      }
      output['children'] = children;
    } else if (measure) {
      bounds = _leafBounds(
        type as String,
        id,
        node['data'] as Map,
        assets,
        services,
        resolveImageIntrinsicSize,
      );
    }

    var xf = Affine2D.translation(position.x, position.y);
    if (hasLinearTransform) {
      final pivot = legacy['origin'] == 'custom'
          ? customPivot
          : bounds == null || type == 'text' || type == 'icon'
          ? Vec2.zero
          : Vec2(
              bounds.left / 2 + bounds.right / 2,
              bounds.top / 2 + bounds.bottom / 2,
            );
      xf =
          xf *
          affineAround(
            pivot,
            Affine2D.rotation(rotation) * Affine2D.scale(scale.x, scale.y),
          );
    }
    if (!xf.isIdentity) output['xf'] = xf.toJson();
    return (json: output, xf: xf, bounds: bounds);
  }

  return {
    ...input,
    'sceneFormatVersion': 5,
    'children': [
      for (final root in roots)
        convert(Map<String, Object?>.from(root as Map)).json,
    ],
  };
}

Rect2D? _leafBounds(
  String type,
  String id,
  Map data,
  Map? assets,
  CoreServices? services,
  Size2D? Function(String sourceRef)? resolveImageIntrinsicSize,
) {
  switch (type) {
    case 'path':
      final source = PathSource.fromJson(
        Map<String, Object?>.from(data['source'] as Map),
      );
      return compilePath(source).localBounds();
    case 'text':
      final measurer = services?.textMeasurer;
      if (measurer == null) {
        throw FormatException(
          'Scene v4 text node $id needs text metrics to resolve a group pivot. '
          'Pass CoreServices to upgradeCanvasScene.',
        );
      }
      return _centered(
        measurer.measure(
          text: data['text'] as String,
          fontFamily: data['fontFamily'] as String,
          fontWeight: data['fontWeight'] as int,
          fontSize: (data['fontSize'] as num).toDouble(),
          letterSpacing: (data['letterSpacing'] as num?)?.toDouble() ?? 0,
        ),
      );
    case 'icon':
      final size = (data['sizePx'] as num?)?.toDouble() ?? 96;
      return _centered(Size2D(size, size));
    case 'image':
      final layout = Size2D.fromJson(
        Map<String, dynamic>.from(data['size'] as Map),
      );
      final fit = ImageFit.values.byName(data['fit'] as String? ?? 'contain');
      final assetId = data['assetId'];
      final asset = assets?[assetId] as Map?;
      final storedSize = asset?['intrinsicSize'] as Map?;
      final intrinsic = storedSize == null
          ? asset == null
                ? null
                : resolveImageIntrinsicSize?.call(asset['sourceRef'] as String)
          : Size2D.fromJson(Map<String, dynamic>.from(storedSize));
      if (fit == ImageFit.contain && assetId != null && intrinsic == null) {
        throw FormatException(
          'Scene v4 image node $id needs intrinsic image dimensions to resolve '
          'a pivot. Supply resolveImageIntrinsicSize or persist intrinsicSize.',
        );
      }
      return imageSrcDst(
        intrinsic: intrinsic ?? layout,
        layout: layout,
        fit: fit,
        align: _point(data['align'], const Vec2(0.5, 0.5)),
      ).dst;
  }
  return null;
}

Rect2D _centered(Size2D size) =>
    Rect2D.fromLTWH(-size.w / 2, -size.h / 2, size.w, size.h);

double _number(Object? value, double fallback) {
  if (value == null) return fallback;
  if (value is! num || !value.toDouble().isFinite) {
    throw const FormatException('Legacy transforms require finite numbers.');
  }
  return value.toDouble();
}

Vec2 _point(Object? value, Vec2 fallback) {
  if (value == null) return fallback;
  if (value is! Map) {
    throw const FormatException('Legacy transform point must be an object.');
  }
  return Vec2(_number(value['x'], fallback.x), _number(value['y'], fallback.y));
}
