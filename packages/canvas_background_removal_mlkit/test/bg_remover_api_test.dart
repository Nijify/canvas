import 'package:canvas_background_removal/background_removal.dart';
// Path: private_packages/bg_remover_mlkit/test/bg_remover_api_test.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:canvas_background_removal_mlkit/background_removal_mlkit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('factory returns BackgroundRemovalByteProcessor', () {
    final remover = createBackgroundRemovalByteProcessor();

    expect(remover, isA<BackgroundRemovalByteProcessor>());
  });

  test('unsupported host platforms return typed unsupported failure', () async {
    if (Platform.isAndroid) {
      return;
    }

    final remover = createBackgroundRemovalByteProcessor();

    await expectLater(
      remover.remove(Uint8List.fromList(const <int>[1, 2, 3])),
      throwsA(
        isA<BackgroundRemovalProviderException>().having(
          (error) => error.kind,
          'kind',
          BackgroundRemovalProviderFailureKind.unsupported,
        ),
      ),
    );
  });

  test('provider failure preserves diagnostic cause', () {
    final cause = StateError('native diagnostic');

    final error = BackgroundRemovalProviderException(BackgroundRemovalProviderFailureKind.failed, cause: cause);

    expect(error.kind, BackgroundRemovalProviderFailureKind.failed);
    expect(identical(error.cause, cause), isTrue);
  });
}
