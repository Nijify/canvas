// Path: private_packages/bg_remover_isnet/test/isnet_worker_test.dart

import 'dart:io';

import 'package:canvas_background_removal_isnet/bg_remover_isnet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final engineKind in IsnetEngineKind.values) {
    test(
      'worker preserves model-missing failure for ${engineKind.name}',
      () async {
        final tempDirectory = await Directory.systemTemp.createTemp(
          'bg_remover_isnet_worker_test_',
        );

        try {
          final missingModel = File('${tempDirectory.path}/missing.tflite');

          await expectLater(
            IsnetWorker.open(modelFile: missingModel, engineKind: engineKind),
            throwsA(
              isA<IsnetException>().having(
                (error) => error.kind,
                'kind',
                IsnetFailureKind.modelMissing,
              ),
            ),
          );
        } finally {
          await tempDirectory.delete(recursive: true);
        }
      },
    );
  }
}
