import 'dart:io';
import 'dart:isolate';

import 'package:test/test.dart';

Directory _packageRoot(String uri) {
  final resolved = Isolate.resolvePackageUriSync(Uri.parse(uri));
  if (resolved == null) throw StateError('Could not resolve $uri');
  return File.fromUri(resolved).parent.parent;
}

Iterable<File> _sources(Directory root) => Directory('${root.path}/lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'));

void main() {
  test('core has no dependency on optional or historical upgrade code', () {
    final core = _packageRoot('package:canvas_core/canvas_core_runtime.dart');
    final historicalImport = RegExp(
      r'(?:import|export)\s+[^;]*(?:canvas_scene_upgrade|'
      r'scene_migrations|migrations/|formats/scene_v[1234]\.dart)',
    );
    for (final source in _sources(core)) {
      expect(
        historicalImport.hasMatch(source.readAsStringSync()),
        isFalse,
        reason: source.path,
      );
    }
  });

  test(
    'upgrade code uses core public APIs and validates current output once',
    () {
      final upgrade = _packageRoot(
        'package:canvas_scene_upgrade/canvas_scene_upgrade.dart',
      );
      final currentDecoderCallers = <String>[];
      final decoderCall = RegExp(r'\bdecodeCanvasScene\s*\(');
      for (final source in _sources(upgrade)) {
        final text = source.readAsStringSync();
        expect(text, isNot(contains('package:canvas_core/src/')));
        if (decoderCall.hasMatch(text)) currentDecoderCallers.add(source.path);
      }
      expect(currentDecoderCallers, hasLength(1));
      expect(currentDecoderCallers.single, endsWith('src/upgrade_scene.dart'));
    },
  );
}
