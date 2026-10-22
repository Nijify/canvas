import 'package:canvas_background_removal/background_removal.dart';
// Path: private_packages/bg_remover_mlkit/test/serialized_bg_remover_test.dart

import 'dart:typed_data';

import 'package:canvas_background_removal_mlkit/src/serialized_bg_remover.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes overlapping provider calls', () async {
    final delegate = _RecordingConcurrentBackgroundRemovalByteProcessor();
    final remover = SerializedBackgroundRemovalByteProcessor(delegate);

    final first = remover.remove(Uint8List.fromList(const <int>[1]));

    final second = remover.remove(Uint8List.fromList(const <int>[2]));

    final results = await Future.wait(<Future<Uint8List>>[first, second]);

    expect(delegate.calls, 2);
    expect(delegate.maxConcurrentCalls, 1);

    expect(results[0], orderedEquals(const <int>[1]));
    expect(results[1], orderedEquals(const <int>[2]));
  });

  test('releases serialization gate after failure', () async {
    final delegate = _RecordingConcurrentBackgroundRemovalByteProcessor(
      firstCallError: StateError('first failed'),
    );

    final remover = SerializedBackgroundRemovalByteProcessor(delegate);

    final first = remover.remove(Uint8List.fromList(const <int>[1]));

    final second = remover.remove(Uint8List.fromList(const <int>[2]));

    await expectLater(first, throwsA(isA<StateError>()));

    final secondResult = await second;

    expect(secondResult, orderedEquals(const <int>[2]));
    expect(delegate.calls, 2);
    expect(delegate.maxConcurrentCalls, 1);
  });
}

final class _RecordingConcurrentBackgroundRemovalByteProcessor implements BackgroundRemovalByteProcessor {
  _RecordingConcurrentBackgroundRemovalByteProcessor({this.firstCallError});

  final Object? firstCallError;

  int calls = 0;
  int concurrentCalls = 0;
  int maxConcurrentCalls = 0;

  @override
  Future<Uint8List> remove(Uint8List inputBytes) async {
    final callNumber = ++calls;

    concurrentCalls++;

    if (concurrentCalls > maxConcurrentCalls) {
      maxConcurrentCalls = concurrentCalls;
    }

    try {
      await Future<void>.delayed(const Duration(milliseconds: 10));

      if (callNumber == 1 && firstCallError != null) {
        throw firstCallError!;
      }

      return Uint8List.fromList(inputBytes);
    } finally {
      concurrentCalls--;
    }
  }
}
