import 'dart:typed_data';

import 'package:canvas_background_removal/background_removal.dart';
import 'package:canvas_background_removal_isnet/src/isnet_worker.dart';

/// Experimental adapter for a host-opened worker. The host supplies and
/// verifies the model and remains responsible for worker lifecycle.
final class IsnetByteProcessor implements BackgroundRemovalByteProcessor {
  const IsnetByteProcessor(this.worker);

  final IsnetWorker worker;

  @override
  Future<Uint8List> remove(Uint8List inputBytes) async {
    try {
      return (await worker.remove(inputBytes)).pngBytes;
    } catch (_) {
      throw const BackgroundRemovalProviderException(
        BackgroundRemovalProviderFailureKind.failed,
      );
    }
  }
}
