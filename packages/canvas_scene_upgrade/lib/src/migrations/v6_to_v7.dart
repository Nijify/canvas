import '../formats/scene_v6.dart';

/// Projects a prepared v6 scene to ordinary v7 layers.
///
/// Host behavior must be prepared by the caller before this boundary. Omitted
/// subtrees remain recoverable from the caller's original input document.
Map<String, Object?> convertCanvasSceneV6ToV7(Map<String, Object?> input) {
  validateSceneV6Json(input);
  final children = _children(input['children'] as List);
  return {
    ...input,
    'sceneFormatVersion': 7,
    'artboardSize': input['artboardSize'] ?? {'w': 740, 'h': 360},
    'children': children,
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
