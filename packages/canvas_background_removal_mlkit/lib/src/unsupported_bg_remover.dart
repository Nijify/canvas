// Path: packages/canvas_background_removal_mlkit/lib/src/unsupported_bg_remover.dart

import 'dart:typed_data';

import 'package:canvas_background_removal/background_removal.dart';

BackgroundRemovalByteProcessor createBackgroundRemovalByteProcessor() => const _UnsupportedBackgroundRemovalByteProcessor();

final class _UnsupportedBackgroundRemovalByteProcessor implements BackgroundRemovalByteProcessor {
  const _UnsupportedBackgroundRemovalByteProcessor();

  @override
  Future<Uint8List> remove(Uint8List inputBytes) async {
    throw const BackgroundRemovalProviderException(BackgroundRemovalProviderFailureKind.unsupported);
  }
}
