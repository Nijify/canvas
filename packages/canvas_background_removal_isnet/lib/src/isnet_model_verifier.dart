// Path: private_packages/bg_remover_isnet/lib/src/isnet_model_verifier.dart

import 'dart:io';

import 'package:canvas_background_removal_isnet/src/isnet_failure.dart';
import 'package:canvas_background_removal_isnet/src/isnet_model_contract.dart';
import 'package:crypto/crypto.dart';

final class IsnetVerifiedModel {
  const IsnetVerifiedModel({
    required this.file,
    required this.sizeBytes,
    required this.sha256,
  });

  final File file;
  final int sizeBytes;
  final String sha256;
}

final class IsnetModelVerifier {
  const IsnetModelVerifier({
    this.expectedIdentity = IsnetModelContract.candidateIdentity,
  });

  final IsnetModelIdentity expectedIdentity;

  Future<IsnetVerifiedModel> verify(File modelFile) async {
    if (!await modelFile.exists()) {
      throw IsnetException(
        IsnetFailureKind.modelMissing,
        cause: 'Model file does not exist: ${modelFile.path}',
      );
    }

    final actualSize = await modelFile.length();
    if (actualSize != expectedIdentity.sizeBytes) {
      throw IsnetException(
        IsnetFailureKind.modelIdentityMismatch,
        cause:
            'Model size mismatch: expected ${expectedIdentity.sizeBytes} '
            'bytes, found $actualSize bytes.',
      );
    }

    final digest = await sha256.bind(modelFile.openRead()).first;
    final actualSha256 = digest.toString();

    if (actualSha256 != expectedIdentity.sha256) {
      throw IsnetException(
        IsnetFailureKind.modelIdentityMismatch,
        cause:
            'Model SHA-256 mismatch: expected ${expectedIdentity.sha256}, '
            'found $actualSha256.',
      );
    }

    return IsnetVerifiedModel(
      file: modelFile,
      sizeBytes: actualSize,
      sha256: actualSha256,
    );
  }
}
