// Path: flutter_frontend/test/features/design_editor/application/background_removal_processor_test.dart

import 'dart:typed_data';

import 'package:canvas_background_removal/background_removal.dart';
import 'package:flutter_test/flutter_test.dart';



void main() {
  group('ValidatedBackgroundRemovalProcessor', () {
    test('rejects empty input before provider invocation', () async {
      final remover = _RecordingBackgroundRemovalByteProcessor();
      final processor = ValidatedBackgroundRemovalProcessor(
        remover: remover,
        rasterInspector: _QueueRasterInspector(const <Object>[]),
      );

      final result = await processor.process(inputBytes: Uint8List(0));

      _expectFailure(
        result,
        BackgroundRemovalProcessFailureKind.unsupportedInput,
      );
      expect(remover.inputs, isEmpty);
    });

    test('rejects malformed input before provider invocation', () async {
      final remover = _RecordingBackgroundRemovalByteProcessor();
      final processor = ValidatedBackgroundRemovalProcessor(
        remover: remover,
        rasterInspector: _QueueRasterInspector(<Object>[
          const FormatException('malformed input'),
        ]),
      );

      final result = await processor.process(
        inputBytes: Uint8List.fromList(const <int>[1]),
      );

      _expectFailure(
        result,
        BackgroundRemovalProcessFailureKind.unsupportedInput,
      );
      expect(remover.inputs, isEmpty);
    });

    test('rejects animated input before provider invocation', () async {
      final remover = _RecordingBackgroundRemovalByteProcessor();
      final processor = ValidatedBackgroundRemovalProcessor(
        remover: remover,
        rasterInspector: _QueueRasterInspector(<Object>[
          const EncodedRasterInfo(
            format: EncodedRasterFormat.webp,
            width: 2,
            height: 3,
            frameCount: 2,
          ),
        ]),
      );

      final result = await processor.process(
        inputBytes: Uint8List.fromList(const <int>[1]),
      );

      _expectFailure(
        result,
        BackgroundRemovalProcessFailureKind.unsupportedInput,
      );
      expect(remover.inputs, isEmpty);
    });

    test('rejects unsupported input before provider invocation', () async {
      final remover = _RecordingBackgroundRemovalByteProcessor();

      final processor = ValidatedBackgroundRemovalProcessor(
        remover: remover,
        rasterInspector: _QueueRasterInspector(<Object>[
          const EncodedRasterInfo(
            format: EncodedRasterFormat.gif,
            width: 2,
            height: 3,
            frameCount: 1,
          ),
        ]),
      );

      final result = await processor.process(
        inputBytes: Uint8List.fromList(const <int>[1]),
      );

      _expectFailure(
        result,
        BackgroundRemovalProcessFailureKind.unsupportedInput,
      );
      expect(remover.inputs, isEmpty);
    });

    for (final format in <EncodedRasterFormat>[
      EncodedRasterFormat.png,
      EncodedRasterFormat.jpeg,
      EncodedRasterFormat.webp,
    ]) {
      test('accepts static ${format.name} input', () async {
        final output = _alphaPngBytes();
        final remover = _RecordingBackgroundRemovalByteProcessor(output: output);
        final processor = ValidatedBackgroundRemovalProcessor(
          remover: remover,
          rasterInspector: _QueueRasterInspector(<Object>[
            EncodedRasterInfo(
              format: format,
              width: 2,
              height: 3,
              frameCount: 1,
            ),
            _validOutputRaster,
          ]),
        );

        final input = Uint8List.fromList(const <int>[9, 8, 7]);
        final result = await processor.process(inputBytes: input);

        expect(result, isA<BackgroundRemovalProcessSuccess>());
        expect(remover.inputs, hasLength(1));
        expect(remover.inputs.single, orderedEquals(input));
      });
    }

    test('maps typed temporary provider failure', () async {
      final remover = _RecordingBackgroundRemovalByteProcessor(
        error: const BackgroundRemovalProviderException(
          BackgroundRemovalProviderFailureKind.temporarilyUnavailable,
        ),
      );

      final processor = ValidatedBackgroundRemovalProcessor(
        remover: remover,
        rasterInspector: _QueueRasterInspector(<Object>[_validInputRaster]),
      );

      final result = await processor.process(
        inputBytes: Uint8List.fromList(const <int>[1, 2, 3]),
      );

      _expectFailure(
        result,
        BackgroundRemovalProcessFailureKind.temporarilyUnavailable,
      );
    });

    test(
      'does not confuse provider unsupported with unsupported input',
      () async {
        final remover = _RecordingBackgroundRemovalByteProcessor(
          error: const BackgroundRemovalProviderException(BackgroundRemovalProviderFailureKind.unsupported),
        );

        final processor = ValidatedBackgroundRemovalProcessor(
          remover: remover,
          rasterInspector: _QueueRasterInspector(<Object>[_validInputRaster]),
        );

        final result = await processor.process(
          inputBytes: Uint8List.fromList(const <int>[1]),
        );

        _expectFailure(result, BackgroundRemovalProcessFailureKind.failed);
      },
    );

    test('maps typed generic provider failure to failed', () async {
      final remover = _RecordingBackgroundRemovalByteProcessor(
        error: const BackgroundRemovalProviderException(BackgroundRemovalProviderFailureKind.failed),
      );
      final processor = ValidatedBackgroundRemovalProcessor(
        remover: remover,
        rasterInspector: _QueueRasterInspector(<Object>[_validInputRaster]),
      );

      final result = await processor.process(
        inputBytes: Uint8List.fromList(const <int>[1]),
      );

      _expectFailure(result, BackgroundRemovalProcessFailureKind.failed);
    });

    test('maps unexpected provider exceptions to failed', () async {
      final remover = _RecordingBackgroundRemovalByteProcessor(
        error: StateError('unexpected provider failure'),
      );

      final processor = ValidatedBackgroundRemovalProcessor(
        remover: remover,
        rasterInspector: _QueueRasterInspector(<Object>[_validInputRaster]),
      );

      final result = await processor.process(
        inputBytes: Uint8List.fromList(const <int>[1]),
      );

      _expectFailure(result, BackgroundRemovalProcessFailureKind.failed);
    });

    test('rejects empty provider output', () async {
      final remover = _RecordingBackgroundRemovalByteProcessor(output: Uint8List(0));
      final processor = ValidatedBackgroundRemovalProcessor(
        remover: remover,
        rasterInspector: _QueueRasterInspector(<Object>[_validInputRaster]),
      );

      final result = await processor.process(
        inputBytes: Uint8List.fromList(const <int>[1]),
      );

      _expectFailure(result, BackgroundRemovalProcessFailureKind.failed);
    });

    test('rejects malformed provider output', () async {
      final remover = _RecordingBackgroundRemovalByteProcessor(
        output: Uint8List.fromList(const <int>[1, 2, 3]),
      );
      final processor = ValidatedBackgroundRemovalProcessor(
        remover: remover,
        rasterInspector: _QueueRasterInspector(<Object>[
          _validInputRaster,
          const FormatException('malformed output'),
        ]),
      );

      final result = await processor.process(
        inputBytes: Uint8List.fromList(const <int>[1]),
      );

      _expectFailure(result, BackgroundRemovalProcessFailureKind.failed);
    });

    test('rejects non-PNG provider output', () async {
      final remover = _RecordingBackgroundRemovalByteProcessor(output: _alphaPngBytes());
      final processor = ValidatedBackgroundRemovalProcessor(
        remover: remover,
        rasterInspector: _QueueRasterInspector(<Object>[
          _validInputRaster,
          const EncodedRasterInfo(
            format: EncodedRasterFormat.jpeg,
            width: 2,
            height: 3,
            frameCount: 1,
          ),
        ]),
      );

      final result = await processor.process(
        inputBytes: Uint8List.fromList(const <int>[1]),
      );

      _expectFailure(result, BackgroundRemovalProcessFailureKind.failed);
    });

    test('rejects animated provider output', () async {
      final remover = _RecordingBackgroundRemovalByteProcessor(output: _alphaPngBytes());
      final processor = ValidatedBackgroundRemovalProcessor(
        remover: remover,
        rasterInspector: _QueueRasterInspector(<Object>[
          _validInputRaster,
          const EncodedRasterInfo(
            format: EncodedRasterFormat.png,
            width: 2,
            height: 3,
            frameCount: 2,
          ),
        ]),
      );

      final result = await processor.process(
        inputBytes: Uint8List.fromList(const <int>[1]),
      );

      _expectFailure(result, BackgroundRemovalProcessFailureKind.failed);
    });

    test('rejects PNG output without transparency capability', () async {
      final remover = _RecordingBackgroundRemovalByteProcessor(output: _rgbPngBytes());
      final processor = ValidatedBackgroundRemovalProcessor(
        remover: remover,
        rasterInspector: _QueueRasterInspector(<Object>[
          _validInputRaster,
          _validOutputRaster,
        ]),
      );

      final result = await processor.process(
        inputBytes: Uint8List.fromList(const <int>[1]),
      );

      _expectFailure(result, BackgroundRemovalProcessFailureKind.failed);
    });

    test('rejects width-changing provider output', () async {
      final remover = _RecordingBackgroundRemovalByteProcessor(output: _alphaPngBytes());
      final processor = ValidatedBackgroundRemovalProcessor(
        remover: remover,
        rasterInspector: _QueueRasterInspector(<Object>[
          _validInputRaster,
          const EncodedRasterInfo(
            format: EncodedRasterFormat.png,
            width: 3,
            height: 3,
            frameCount: 1,
          ),
        ]),
      );

      final result = await processor.process(
        inputBytes: Uint8List.fromList(const <int>[1]),
      );

      _expectFailure(result, BackgroundRemovalProcessFailureKind.failed);
    });

    test('rejects height-changing provider output', () async {
      final remover = _RecordingBackgroundRemovalByteProcessor(output: _alphaPngBytes());
      final processor = ValidatedBackgroundRemovalProcessor(
        remover: remover,
        rasterInspector: _QueueRasterInspector(<Object>[
          _validInputRaster,
          const EncodedRasterInfo(
            format: EncodedRasterFormat.png,
            width: 2,
            height: 4,
            frameCount: 1,
          ),
        ]),
      );

      final result = await processor.process(
        inputBytes: Uint8List.fromList(const <int>[1]),
      );

      _expectFailure(result, BackgroundRemovalProcessFailureKind.failed);
    });

    test('returns exact provider bytes and authoritative dimensions', () async {
      final output = _alphaPngBytes();
      final remover = _RecordingBackgroundRemovalByteProcessor(output: output);

      final processor = ValidatedBackgroundRemovalProcessor(
        remover: remover,
        rasterInspector: _QueueRasterInspector(<Object>[
          _validInputRaster,
          _validOutputRaster,
        ]),
      );

      final input = Uint8List.fromList(const <int>[9, 8, 7]);
      final result = await processor.process(inputBytes: input);

      expect(result, isA<BackgroundRemovalProcessSuccess>());

      final image = (result as BackgroundRemovalProcessSuccess).image;

      expect(image.bytes, orderedEquals(output));
      expect(image.widthPx, 2);
      expect(image.heightPx, 3);
      expect(remover.inputs, hasLength(1));
      expect(remover.inputs.single, orderedEquals(input));
    });
  });
}

const _validInputRaster = EncodedRasterInfo(
  format: EncodedRasterFormat.png,
  width: 2,
  height: 3,
  frameCount: 1,
);

const _validOutputRaster = EncodedRasterInfo(
  format: EncodedRasterFormat.png,
  width: 2,
  height: 3,
  frameCount: 1,
);

void _expectFailure(
  BackgroundRemovalProcessResult result,
  BackgroundRemovalProcessFailureKind kind,
) {
  expect(
    result,
    isA<BackgroundRemovalProcessFailure>().having(
      (failure) => failure.kind,
      'kind',
      kind,
    ),
  );
}

final class _RecordingBackgroundRemovalByteProcessor implements BackgroundRemovalByteProcessor {
  _RecordingBackgroundRemovalByteProcessor({Uint8List? output, this.error})
    : output = output ?? _alphaPngBytes();

  final Uint8List output;
  final Object? error;

  final List<Uint8List> inputs = <Uint8List>[];

  @override
  Future<Uint8List> remove(Uint8List inputBytes) async {
    inputs.add(Uint8List.fromList(inputBytes));

    final failure = error;

    if (failure != null) {
      throw failure;
    }

    return output;
  }
}

final class _QueueRasterInspector implements EncodedRasterInspector {
  _QueueRasterInspector(List<Object> results)
    : _results = List<Object>.from(results);

  final List<Object> _results;

  @override
  Future<EncodedRasterInfo> inspect(Uint8List bytes) async {
    if (_results.isEmpty) {
      throw StateError('No raster inspection result configured.');
    }

    final next = _results.removeAt(0);

    if (next is EncodedRasterInfo) {
      return next;
    }

    throw next;
  }
}

/// Minimal PNG representation with RGBA color type.
///
/// It is intentionally not used for codec decoding in these tests because the
/// raster inspector is injected. It only needs to satisfy
/// pngSupportsTransparency().
Uint8List _alphaPngBytes() {
  return Uint8List.fromList(const <int>[
    // PNG signature.
    0x89, 0x50, 0x4E, 0x47,
    0x0D, 0x0A, 0x1A, 0x0A,

    // IHDR length = 13.
    0x00, 0x00, 0x00, 0x0D,

    // "IHDR".
    0x49, 0x48, 0x44, 0x52,

    // Width = 2.
    0x00, 0x00, 0x00, 0x02,

    // Height = 3.
    0x00, 0x00, 0x00, 0x03,

    // Bit depth = 8.
    0x08,

    // Color type = 6 (RGBA).
    0x06,

    // Compression, filter, interlace.
    0x00, 0x00, 0x00,

    // CRC placeholder. pngSupportsTransparency does not validate CRC.
    0x00, 0x00, 0x00, 0x00,
  ]);
}

/// Minimal PNG representation with RGB color type and no tRNS chunk.
Uint8List _rgbPngBytes() {
  return Uint8List.fromList(const <int>[
    // PNG signature.
    0x89, 0x50, 0x4E, 0x47,
    0x0D, 0x0A, 0x1A, 0x0A,

    // IHDR length = 13.
    0x00, 0x00, 0x00, 0x0D,

    // "IHDR".
    0x49, 0x48, 0x44, 0x52,

    // Width = 2.
    0x00, 0x00, 0x00, 0x02,

    // Height = 3.
    0x00, 0x00, 0x00, 0x03,

    // Bit depth = 8.
    0x08,

    // Color type = 2 (RGB, no alpha).
    0x02,

    // Compression, filter, interlace.
    0x00, 0x00, 0x00,

    // CRC placeholder.
    0x00, 0x00, 0x00, 0x00,
  ]);
}
