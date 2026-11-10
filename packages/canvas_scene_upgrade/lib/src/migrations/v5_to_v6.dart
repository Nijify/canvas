/// Flatten the validated v5 node envelopes while preserving extension payloads.
Map<String, Object?> convertCanvasSceneV5ToV6(Map<String, Object?> input) => {
  ...input,
  'sceneFormatVersion': 6,
  'children': _flattenChildren(input['children'] as List),
};

List<Map<String, Object?>> _flattenChildren(List children) => [
  for (final node in children)
    _flattenNode(Map<String, Object?>.from(node as Map)),
];

Map<String, Object?> _flattenNode(Map<String, Object?> node) {
  final type = node.remove('runtimeType') as String;
  node['type'] = type;
  if (type == 'group') {
    node['children'] = _flattenChildren(node['children'] as List);
  } else {
    final data = Map<String, Object?>.from(node.remove('data') as Map);
    if (type == 'path') data['geometry'] = data.remove('source');
    node.addAll(data);
  }
  return node;
}
