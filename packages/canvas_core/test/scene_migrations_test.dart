// Path: packages/canvas_core/test/scene_migrations_test.dart

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

Directory _resolvePackageRoot() {
  final runtimeUri = Isolate.resolvePackageUriSync(
    Uri.parse('package:canvas_core/canvas_core_runtime.dart'),
  );

  if (runtimeUri == null) {
    throw StateError('Could not resolve package:canvas_core');
  }

  return File.fromUri(runtimeUri).parent.parent;
}

final Directory _packageRoot = _resolvePackageRoot();

Map<String, dynamic> _loadFixture(String name) {
  final file = File.fromUri(
    _packageRoot.uri.resolve('test/fixtures/scene_migration/$name'),
  );

  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

Map<String, dynamic> _deepCopy(Map<String, dynamic> value) {
  return jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
}

List<Map<String, dynamic>> _legacyGroupChildren(Map<String, dynamic> scene) {
  final roots = scene['children'] as List<dynamic>;
  final group = roots.single as Map<String, dynamic>;

  return (group['children'] as List<dynamic>).cast<Map<String, dynamic>>();
}

bool? _resolveLegacyIconWasGlyph(String iconRef) {
  return switch (iconRef) {
    'icon.glyph' => true,
    'icon.path' => false,
    _ => null,
  };
}

Map<String, Object?> _firstNestedTextForeground(
  Map<String, Object?> scene,
) {
  final roots = scene['children'] as List<Object?>;
  final group = roots.single as Map<String, Object?>;
  final children = group['children'] as List<Object?>;
  final text = children.first as Map<String, Object?>;
  final data = text['data'] as Map<String, Object?>;
  final appearance = data['appearance'] as Map<String, Object?>;
  return appearance['foreground'] as Map<String, Object?>;
}

void main() {
  group('scene migration', () {
    test('upgrades literal canvas_core 0.10.x JSON through v1 to v2', () {
      final legacy = _loadFixture('legacy_v010_nested.json');
      final legacyBefore = _deepCopy(legacy);

      final migrated = upgradeCanvasScene(
        Map<String, Object?>.from(legacy),
        legacyUnversioned: true,
        resolveLegacyIconWasGlyph: _resolveLegacyIconWasGlyph,
      );

      expect(migrated['sceneFormatVersion'], currentCanvasSceneFormatVersion);
      final migratedForeground = _firstNestedTextForeground(migrated);
      expect(
        migratedForeground,
        <String, Object?>{
          'type': 'gradient',
          'grad': <String, Object?>{
            'start': <String, double>{
              'x': -223.67532368147135,
              'y': -223.67532368147135,
            },
            'end': <String, double>{
              'x': 1303.6753236814714,
              'y': 1303.6753236814714,
            },
            'stops': <Map<String, Object?>>[
              <String, Object?>{'offset': 0.3, 'color': 4279312947},
              <String, Object?>{'offset': 0.7, 'color': 4282668390},
            ],
          },
        },
      );

      // Migration must not mutate persisted input supplied by the caller.
      expect(legacy, equals(legacyBefore));

      final scene = decodeCanvasScene(migrated);
      final validationIssues = validateCanvasSceneDocument(scene);

      expect(validationIssues, isEmpty);
    });

    test('requires explicit opt-in for an unversioned legacy scene', () {
      final legacy = _loadFixture('legacy_v010_nested.json');

      expect(
        () => upgradeCanvasScene(Map<String, Object?>.from(legacy)),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects unsupported pre-0.10 image sourcePath', () {
      final legacy = _loadFixture('legacy_v010_nested.json');

      _legacyGroupChildren(legacy).add(<String, dynamic>{
        'id': 'image-pre-v010-1',
        'name': 'Older image',
        'hidden': false,
        'locked': false,
        'xf': <String, dynamic>{
          'position': <String, double>{'x': 0.0, 'y': 0.0},
          'rotationRad': 0.0,
          'scale': <String, double>{'x': 1.0, 'y': 1.0},
          'origin': 'center',
          'customPivotPx': null,
        },
        'data': <String, dynamic>{
          'size': <String, double>{'w': 320.0, 'h': 180.0},
          'sourcePath': 'legacy/image.png',
          'fit': 'contain',
          'align': <String, double>{'x': 0.5, 'y': 0.5},
        },
        'role': null,
        'runtimeType': 'image',
      });

      expect(
        () => upgradeCanvasScene(
          Map<String, Object?>.from(legacy),
          legacyUnversioned: true,
          resolveLegacyIconWasGlyph: _resolveLegacyIconWasGlyph,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('sourcePath'),
          ),
        ),
      );
    });

    test('requires legacy icon rendering knowledge for nonzero shadows', () {
      final legacy = _loadFixture('legacy_v010_nested.json');

      expect(
        () => upgradeCanvasScene(
          Map<String, Object?>.from(legacy),
          legacyUnversioned: true,
          resolveLegacyIconWasGlyph: (_) => null,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('cannot migrate a nonzero icon shadow'),
          ),
        ),
      );
    });

    test('does not require an icon resolver for zero legacy shadows', () {
      final legacy = _loadFixture('legacy_v010_nested.json');

      for (final node in _legacyGroupChildren(legacy)) {
        if (node['runtimeType'] != 'icon') continue;

        final data = node['data'] as Map<String, dynamic>;
        data['shadowOffset'] = 0.0;
      }

      final migrated = upgradeCanvasScene(
        Map<String, Object?>.from(legacy),
        legacyUnversioned: true,
      );

      final roots = migrated['children'] as List<Object?>;
      final group = roots.single as Map<String, Object?>;
      final children = group['children'] as List<Object?>;

      for (final rawNode in children) {
        final node = rawNode as Map<String, Object?>;
        if (node['runtimeType'] != 'icon') continue;

        final data = node['data'] as Map<String, Object?>;
        final appearance = data['appearance'] as Map<String, Object?>;
        final underlays = appearance['underlays'] as List<Object?>;

        expect(underlays, isEmpty);
      }
    });

    test('rejects mixed legacy and current appearance fields', () {
      final legacy = _loadFixture('legacy_v010_nested.json');

      final text = _legacyGroupChildren(
        legacy,
      ).firstWhere((node) => node['runtimeType'] == 'text');

      final data = text['data'] as Map<String, dynamic>;

      data['appearance'] = <String, Object?>{
        'foreground': data['fill'],
        'underlays': <Object?>[],
      };

      expect(
        () => upgradeCanvasScene(
          Map<String, Object?>.from(legacy),
          legacyUnversioned: true,
          resolveLegacyIconWasGlyph: _resolveLegacyIconWasGlyph,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects legacy JSON mislabeled as the current scene format', () {
      final legacy = _loadFixture('legacy_v010_nested.json');
      legacy['sceneFormatVersion'] = currentCanvasSceneFormatVersion;

      expect(
        () => upgradeCanvasScene(Map<String, Object?>.from(legacy)),
        throwsA(isA<FormatException>()),
      );
    });

    test('upgrades an already-versioned v1 scene to v2', () {
      final current = _loadFixture('v1_nested.json');

      final upgraded = upgradeCanvasScene(Map<String, Object?>.from(current));

      expect(upgraded['sceneFormatVersion'], currentCanvasSceneFormatVersion);
      expect(upgraded, isNot(equals(current)));
    });

    test('accepts an already-current v2 scene without migration', () {
      final v1 = _loadFixture('v1_nested.json');
      final current = upgradeCanvasScene(Map<String, Object?>.from(v1));

      final upgraded = upgradeCanvasScene(Map<String, Object?>.from(current));

      expect(upgraded, equals(current));
    });
  });
}
