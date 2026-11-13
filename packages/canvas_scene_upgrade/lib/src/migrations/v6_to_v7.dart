import 'package:canvas_core/canvas_core_runtime.dart' show Size2D;

import '../formats/scene_v6.dart';

/// Projects a prepared v6 scene to ordinary v7 layers.
///
/// Host behavior must be prepared by the caller before this boundary. Omitted
/// subtrees remain recoverable from the caller's original input document.
Map<String, Object?> convertCanvasSceneV6ToV7(
  Map<String, Object?> input, {
  Size2D? Function(String sourceRef)? resolveImageIntrinsicSize,
}) {
  validateSceneV6Json(input);
  final children = _children(input['children'] as List);
  final usedAssets = <String>{};
  void collect(List<Map<String, Object?>> nodes) {
    for (final node in nodes) {
      if (node['type'] == 'image' && node['assetId'] != null) {
        usedAssets.add(node['assetId'] as String);
      }
      if (node['type'] == 'group') {
        collect((node['children'] as List).cast<Map<String, Object?>>());
      }
    }
  }

  collect(children);
  final sourceAssets = input['assets'] as Map? ?? const {};
  final assets = <String, Object?>{};
  for (final id in usedAssets) {
    final asset = sourceAssets[id] as Map?;
    if (asset == null) {
      throw FormatException('Image asset $id is missing from the v6 scene.');
    }
    final sourceRef = asset['sourceRef'] as String;
    final stored = asset['intrinsicSize'] as Map?;
    final size = stored == null
        ? resolveImageIntrinsicSize?.call(sourceRef)
        : Size2D.fromJson(Map<String, dynamic>.from(stored));
    if (size == null) {
      throw FormatException(
        'Image asset $id needs intrinsicSize. Supply resolveImageIntrinsicSize '
        'for its logical source reference.',
      );
    }
    assets[id] = <String, Object?>{...asset, 'intrinsicSize': size.toJson()};
  }
  return {
    ...input,
    'sceneFormatVersion': 7,
    'artboardSize': input['artboardSize'] ?? {'w': 740, 'h': 360},
    'children': children,
    'assets': assets,
  };
}

List<Map<String, Object?>> _children(List input) {
  final result = <Map<String, Object?>>[];
  for (final raw in input) {
    final node = Map<String, Object?>.from(raw as Map);
    if (node['behavior'] != null) {
      throw FormatException(
        'Node ${node['id']} requires host preparation before upgrading to v7. '
        'Supply prepareV6Scene to resolve its behavior into ordinary layers.',
      );
    }
    node.remove('role');
    node.remove('behavior');
    if (node['type'] == 'group') {
      node['children'] = _children(node['children'] as List);
    }
    if (node.remove('hidden') == true) continue;
    result.add(node);
  }
  return result;
}
