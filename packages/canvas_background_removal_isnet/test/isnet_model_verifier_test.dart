// Path: private_packages/bg_remover_isnet/test/isnet_model_verifier_test.dart

import 'dart:io';

import 'package:canvas_background_removal_isnet/background_removal_isnet.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'bg_remover_isnet_test_',
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('accepts a file with matching size and SHA-256', () async {
    final bytes = <int>[1, 2, 3, 4, 5, 6];
    final file = File('${tempDirectory.path}/model.tflite');
    await file.writeAsBytes(bytes, flush: true);

    final expectedHash = sha256.convert(bytes).toString();
    final verifier = IsnetModelVerifier(
      expectedIdentity: IsnetModelIdentity(
        sizeBytes: bytes.length,
        sha256: expectedHash,
      ),
    );

    final verified = await verifier.verify(file);

    expect(verified.file.path, file.path);
    expect(verified.sizeBytes, bytes.length);
    expect(verified.sha256, expectedHash);
  });

  test('rejects a missing file', () async {
    final file = File('${tempDirectory.path}/missing.tflite');
    const verifier = IsnetModelVerifier(
      expectedIdentity: IsnetModelIdentity(
        sizeBytes: 1,
        sha256:
            '0000000000000000000000000000000000000000000000000000000000000000',
      ),
    );

    await expectLater(
      verifier.verify(file),
      throwsA(
        isA<IsnetException>().having(
          (error) => error.kind,
          'kind',
          IsnetFailureKind.modelMissing,
        ),
      ),
    );
  });

  test('rejects a size mismatch before hashing', () async {
    final file = File('${tempDirectory.path}/model.tflite');
    await file.writeAsBytes(<int>[1, 2, 3], flush: true);

    const verifier = IsnetModelVerifier(
      expectedIdentity: IsnetModelIdentity(
        sizeBytes: 100,
        sha256:
            '0000000000000000000000000000000000000000000000000000000000000000',
      ),
    );

    await expectLater(
      verifier.verify(file),
      throwsA(
        isA<IsnetException>().having(
          (error) => error.kind,
          'kind',
          IsnetFailureKind.modelIdentityMismatch,
        ),
      ),
    );
  });

  test('rejects a SHA-256 mismatch', () async {
    final bytes = <int>[1, 2, 3];
    final file = File('${tempDirectory.path}/model.tflite');
    await file.writeAsBytes(bytes, flush: true);

    final verifier = IsnetModelVerifier(
      expectedIdentity: IsnetModelIdentity(
        sizeBytes: bytes.length,
        sha256:
            '0000000000000000000000000000000000000000000000000000000000000000',
      ),
    );

    await expectLater(
      verifier.verify(file),
      throwsA(
        isA<IsnetException>().having(
          (error) => error.kind,
          'kind',
          IsnetFailureKind.modelIdentityMismatch,
        ),
      ),
    );
  });
}
