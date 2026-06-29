// Path: test/scene_contract_fixtures_test.dart

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

const _forbiddenLegacyKeys = {
  'solidColor',
  'textGradient',
  'fillGradient',
  'bgGradient',
  'bgOpacity',
};

const _fixtureNames = <String>[
  'text_solid.json',
  'text_gradient.json',
  'icon_solid.json',
  'path_none.json',
  'group_basic.json',
];

Directory _resolvePackageRoot() {
  final runtimeUri = Isolate.resolvePackageUriSync(
    Uri.parse('package:canvas_core/canvas_core_runtime.dart'),
  );

  if (runtimeUri == null) {
    throw StateError('Could not resolve package:canvas_core');
  }

  // package:canvas_core/canvas_core_runtime.dart -> <package-root>/lib/canvas_core_runtime.dart
  return File.fromUri(runtimeUri).parent.parent;
}

final Directory _packageRoot = _resolvePackageRoot();

File _fixtureFile(String name) {
  return File.fromUri(
    _packageRoot.uri.resolve('test/fixtures/scene_contract/$name'),
  );
}

Map<String, dynamic> _loadJson(String name) {
  final file = _fixtureFile(name);
  final raw = file.readAsStringSync();
  return jsonDecode(raw) as Map<String, dynamic>;
}

void _assertNoForbiddenKeys(Object? value) {
  if (value is Map) {
    for (final entry in value.entries) {
      if (_forbiddenLegacyKeys.contains(entry.key)) {
        fail('Found forbidden legacy key: ${entry.key}');
      }
      _assertNoForbiddenKeys(entry.value);
    }
    return;
  }

  if (value is List) {
    for (final item in value) {
      _assertNoForbiddenKeys(item);
    }
  }
}

Iterable<Node> _walkNodes(List<Node> roots) sync* {
  for (final node in roots) {
    yield node;
    if (node is GroupNode) {
      yield* _walkNodes(node.children);
    }
  }
}

void main() {
  group('scene contract fixtures', () {
    for (final name in _fixtureNames) {
      test('parses and contains no legacy keys: $name', () {
        final raw = _loadJson(name);
        _assertNoForbiddenKeys(raw);

        final scene = CanvasSceneDocument.fromJson(raw);

        expect(scene.backgroundFill, const CanvasFillNone());
        expect(scene.backgroundOpacity, 1.0);

        final nodes = _walkNodes(scene.children).toList();

        expect(nodes, isNotEmpty);

        for (final node in nodes) {
          switch (node) {
            case TextNode(:final data):
              expect(data.fill, isNot(isA<CanvasFillNone>()));
            case IconNode(:final data):
              expect(data.fill, isNot(isA<CanvasFillNone>()));
            case PathNode():
            case ImageNode():
            case GroupNode():
              break;
          }
        }
      });
    }
  });
}
