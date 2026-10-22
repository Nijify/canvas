// Path: private_packages/bg_remover_mlkit/lib/src/serialized_bg_remover.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:canvas_background_removal/background_removal.dart';

final class SerializedBackgroundRemovalByteProcessor implements BackgroundRemovalByteProcessor {
  SerializedBackgroundRemovalByteProcessor(this._delegate);

  final BackgroundRemovalByteProcessor _delegate;

  Future<void> _tail = Future<void>.value();

  @override
  Future<Uint8List> remove(Uint8List inputBytes) {
    final completer = Completer<Uint8List>();

    _tail = _tail.then((_) async {
      try {
        final result = await _delegate.remove(inputBytes);

        if (!completer.isCompleted) {
          completer.complete(result);
        }
      } catch (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      }
    });

    return completer.future;
  }
}
