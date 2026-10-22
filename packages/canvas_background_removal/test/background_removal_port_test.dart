import 'dart:convert';
import 'dart:typed_data';

import 'package:canvas_background_removal/background_removal.dart';
import 'package:canvas_editor_flutter/image_tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final input = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAYAAAC56t6BAAAAFklEQVR4nGP8z8Dwn4GBgYGJAQrgDAAxOwIE7x6DkQAAAABJRU5ErkJggg==',
  );

  test('persists only validated PNG output', () async {
    var writes = 0;
    final port = CanvasBackgroundRemovalPort(
      readSource: (_) async => input,
      persistPng: (image) async {
        writes++;
        expect(image.widthPx, 2);
        expect(image.heightPx, 3);
        return 'media:new';
      },
      processor: _Processor(input),
    );
    final result = await port.removeBackground(sourceRef: ' media:old ');
    expect(result, isA<BackgroundRemovalSuccess>());
    expect((result as BackgroundRemovalSuccess).sourceRef, 'media:new');
    expect(writes, 1);
  });

  test('invalid output never persists', () async {
    var writes = 0;
    final port = CanvasBackgroundRemovalPort(
      readSource: (_) async => input,
      persistPng: (_) async { writes++; return 'media:new'; },
      processor: _Processor(Uint8List.fromList([1, 2, 3])),
    );
    final result = await port.removeBackground(sourceRef: 'media:old');
    expect((result as BackgroundRemovalFailure).kind,
        BackgroundRemovalFailureKind.failed);
    expect(writes, 0);
  });

  test('unreadable sources do not invoke provider', () async {
    var providerCalls = 0;
    final port = CanvasBackgroundRemovalPort(
      readSource: (_) async => null,
      persistPng: (_) async => 'media:new',
      processor: _CallbackProcessor((_) {
        providerCalls++;
        return input;
      }),
    );
    expect(await port.removeBackground(sourceRef: 'media:missing'),
        isA<BackgroundRemovalFailure>());
    expect(providerCalls, 0);
  });

  test('provider temporary unavailability has typed safe feedback', () async {
    final port = CanvasBackgroundRemovalPort(
      readSource: (_) async => input,
      persistPng: (_) async => 'media:new',
      processor: _CallbackProcessor((_) => throw
          const BackgroundRemovalProviderException(
            BackgroundRemovalProviderFailureKind.temporarilyUnavailable)),
    );
    final failure = await port.removeBackground(sourceRef: 'media:old')
        as BackgroundRemovalFailure;
    expect(failure.kind, BackgroundRemovalFailureKind.temporarilyUnavailable);
    expect(failure.message, isNot(contains('Exception')));
  });

  test('persistence failure returns a safe failure', () async {
    final port = CanvasBackgroundRemovalPort(
      readSource: (_) async => input,
      persistPng: (_) async => throw StateError('secret storage error'),
      processor: _Processor(input),
    );
    final failure = await port.removeBackground(sourceRef: 'media:old')
        as BackgroundRemovalFailure;
    expect(failure.kind, BackgroundRemovalFailureKind.failed);
    expect(failure.message, isNot(contains('secret')));
  });
}

final class _Processor implements BackgroundRemovalByteProcessor {
  const _Processor(this.bytes);
  final Uint8List bytes;
  @override
  Future<Uint8List> remove(Uint8List _) async => bytes;
}

final class _CallbackProcessor implements BackgroundRemovalByteProcessor {
  const _CallbackProcessor(this.callback);
  final Uint8List Function(Uint8List) callback;
  @override
  Future<Uint8List> remove(Uint8List bytes) async => callback(bytes);
}
