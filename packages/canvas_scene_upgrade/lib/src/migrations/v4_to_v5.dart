import 'package:canvas_core/canvas_core_runtime.dart';
import '../formats/scene_v4.dart';

/// Bake historical TRS+pivot placement into complete local affine matrices.
/// Geometry stays unchanged. Missing layout resources are reported, not guessed.
Map<String, Object?> convertCanvasSceneV4ToV5(
  Map<String, Object?> input, {CoreServices? services,
}) {
  validateSceneV4Json(input);
  final result = _copy(input) as Map<String, Object?>;
  result['sceneFormatVersion'] = 5;
  final legacy = <ElementId, Map<String, Object?>>{};
  final hidden = <ElementId, bool>{};
  final wires = <ElementId, Map<String, Object?>>{};
  void collect(List children, bool ancestorHidden) {
    for (final value in children) {
      final node = value as Map<String, Object?>;
      final id = node['id'] as String;
      legacy[id] = node['xf'] == null ? {} : Map<String, Object?>.from(node['xf'] as Map);
      hidden[id] = ancestorHidden || node['hidden'] == true;
      wires[id] = node;
      node.remove('xf');
      if (node['runtimeType'] == 'group') collect(node['children'] as List, hidden[id]!);
    }
  }
  collect(result['children'] as List, false);
  // Wire structure was checked as v4. The unchanged geometry/appearance uses
  // current primitives; no historical scene decoder is installed in core.
  final scene = CanvasSceneDocument.fromJson(Map<String, dynamic>.from(result));
  requireCanvasSceneIntegrity(scene);
  final imageSizes = _UpgradeImageSizes(scene, services?.images);
  final geometry = NodeGeometry(CoreServices(
    textMeasurer: services?.textMeasurer ?? const _MissingTextMetrics(),
    images: imageSizes, icons: services?.icons,
  ));
  final bounds = <ElementId, Rect2D?>{};
  final matrices = <ElementId, Affine2D>{};

  late Rect2D? Function(Node) layout;
  Affine2D local(Node node) {
    final cached = matrices[node.id];
    if (cached != null) return cached;
    final xf = legacy[node.id]!;
    final position = _point(xf['position'], const Vec2(0, 0));
    final scale = _point(xf['scale'], const Vec2(1, 1));
    final rotation = _number(xf['rotationRad'], 0);
    var matrix = Affine2D.translation(position.x, position.y);
    if (rotation != 0 || scale != const Vec2(1, 1)) {
      var pivot = const Vec2(0, 0);
      if (xf['origin'] == 'custom') {
        pivot = _point(xf['customPivotPx'], pivot);
      } else if (!hidden[node.id]! && node is! TextNode && node is! IconNode) {
        // Text and nominal icon bounds are always centered at local zero.
        final box = layout(node);
        if (box != null) pivot = Vec2(box.left / 2 + box.right / 2, box.top / 2 + box.bottom / 2);
      }
      matrix = matrix * affineAround(pivot,
        Affine2D.rotation(rotation) * Affine2D.scale(scale.x, scale.y));
    }
    matrices[node.id] = matrix;
    return matrix;
  }

  layout = (Node node) {
    if (hidden[node.id]!) return null;
    if (bounds.containsKey(node.id)) return bounds[node.id];
    Rect2D? box;
    if (node is GroupNode) {
      for (final child in node.children) {
        final childBounds = layout(child);
        if (childBounds == null) continue;
        final placed = aabbOfTransformedRect(childBounds, local(child));
        box = box == null ? placed : Rect2DX.union(box, placed);
      }
    } else {
      box = geometry.leafBounds(node)?.layout;
    }
    bounds[node.id] = box;
    return box;
  };
  void write(Node node) {
    // Validate every legacy coefficient even when its pivot cancels at identity.
    final xf = legacy[node.id]!;
    _point(xf['customPivotPx'], const Vec2(0, 0));
    final matrix = local(node);
    if (!matrix.isIdentity) wires[node.id]!['xf'] = matrix.toJson();
    for (final child in node.childrenOrEmpty) write(child);
  }
  for (final root in scene.children) write(root);
  return result;
}

final class _MissingTextMetrics implements TextMeasurer {
  const _MissingTextMetrics();
  @override
  Size2D measure({required String text, required String fontFamily,
    required int fontWeight, required double fontSize, required double letterSpacing}) =>
      throw const FormatException('Historical group pivots need text metrics. Pass CoreServices to upgradeCanvasScene.');
}

final class _UpgradeImageSizes implements ImageIntrinsics {
  _UpgradeImageSizes(this.scene, this.delegate);
  final CanvasSceneDocument scene;
  final ImageIntrinsics? delegate;
  @override
  Size2D? intrinsicSize(ElementId id) {
    final external = delegate?.intrinsicSize(id);
    if (external != null) return external;
    final node = findById(scene, id);
    if (node is! ImageNode || node.data.assetId == null) return null;
    final size = scene.assets[node.data.assetId]?.intrinsicSize;
    if (size == null && node.data.fit == ImageFit.contain) {
      throw const FormatException('Historical contain-fit bounds need intrinsic image metadata. Pass CoreServices or persist intrinsicSize.');
    }
    return size;
  }
}

double _number(Object? value, double fallback) {
  if (value == null) return fallback;
  if (value is! num || !value.toDouble().isFinite) throw const FormatException('Legacy transforms require finite numbers.');
  return value.toDouble();
}
Vec2 _point(Object? value, Vec2 fallback) {
  if (value == null) return fallback;
  if (value is! Map) throw const FormatException('Legacy transform point must be an object.');
  return Vec2(_number(value['x'], fallback.x), _number(value['y'], fallback.y));
}
Object? _copy(Object? value) {
  if (value is Map) return <String, Object?>{for (final entry in value.entries) entry.key as String: _copy(entry.value)};
  if (value is List) return <Object?>[for (final item in value) _copy(item)];
  return value;
}
