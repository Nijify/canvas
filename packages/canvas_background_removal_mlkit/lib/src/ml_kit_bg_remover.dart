// Path: packages/canvas_background_removal_mlkit/lib/src/ml_kit_bg_remover.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:canvas_background_removal/background_removal.dart';
import 'package:canvas_background_removal_mlkit/src/serialized_bg_remover.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';

BackgroundRemovalByteProcessor createBackgroundRemovalByteProcessor() {
  if (!Platform.isAndroid) {
    return const _UnsupportedBackgroundRemovalByteProcessor();
  }

  return SerializedBackgroundRemovalByteProcessor(
    _MlKitBackgroundRemovalByteProcessor(),
  );
}

final class _MlKitBackgroundRemovalByteProcessor
    implements BackgroundRemovalByteProcessor {
  @override
  Future<Uint8List> remove(Uint8List inputBytes) async {
    if (inputBytes.isEmpty) {
      throw ArgumentError.value(inputBytes, 'inputBytes', 'must not be empty');
    }

    try {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'canvas-bg-remover-',
      );

      try {
        final inputFile = File(
          '${temporaryDirectory.path}'
          '${Platform.pathSeparator}'
          'input.${_encodedImageExtension(inputBytes)}',
        );

        await inputFile.writeAsBytes(inputBytes, flush: true);

        final segmenter = SubjectSegmenter(
          options: SubjectSegmenterOptions(
            enableForegroundBitmap: true,
            enableForegroundConfidenceMask: false,
            enableMultipleSubjects: SubjectResultOptions(
              enableConfidenceMask: false,
              enableSubjectBitmap: false,
            ),
          ),
        );

        try {
          final result = await segmenter.processImage(
            InputImage.fromFile(inputFile),
          );

          final foregroundPng = result.foregroundBitmap;

          if (foregroundPng == null || foregroundPng.isEmpty) {
            // Interim ML-Kit-specific readiness heuristic.
            //
            // The unbundled model may still be becoming available through
            // Play services. Keep this classification inside the provider;
            // callers must only depend on the typed failure kind.
            throw BackgroundRemovalProviderException(
              BackgroundRemovalProviderFailureKind.temporarilyUnavailable,
              cause: StateError('ML Kit returned no foreground bitmap.'),
            );
          }

          return foregroundPng;
        } finally {
          await _closeSegmenterQuietly(segmenter);
        }
      } finally {
        await _deleteTemporaryDirectoryQuietly(temporaryDirectory);
      }
    } on BackgroundRemovalProviderException {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        BackgroundRemovalProviderException(
          BackgroundRemovalProviderFailureKind.failed,
          cause: error,
        ),
        stackTrace,
      );
    }
  }
}

final class _UnsupportedBackgroundRemovalByteProcessor
    implements BackgroundRemovalByteProcessor {
  const _UnsupportedBackgroundRemovalByteProcessor();

  @override
  Future<Uint8List> remove(Uint8List inputBytes) async {
    throw const BackgroundRemovalProviderException(
      BackgroundRemovalProviderFailureKind.unsupported,
    );
  }
}

String _encodedImageExtension(Uint8List bytes) {
  if (_hasPrefix(bytes, const <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ])) {
    return 'png';
  }

  if (_hasPrefix(bytes, const <int>[0xFF, 0xD8, 0xFF])) {
    return 'jpg';
  }

  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'webp';
  }

  return 'img';
}

bool _hasPrefix(Uint8List bytes, List<int> prefix) {
  if (bytes.length < prefix.length) {
    return false;
  }

  for (var index = 0; index < prefix.length; index++) {
    if (bytes[index] != prefix[index]) {
      return false;
    }
  }

  return true;
}

Future<void> _closeSegmenterQuietly(SubjectSegmenter segmenter) async {
  try {
    await segmenter.close();
  } on Object {
    // Cleanup must not replace the processing result or original exception.
  }
}

Future<void> _deleteTemporaryDirectoryQuietly(Directory directory) async {
  try {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  } on Object {
    // Cleanup must not replace the processing result or original exception.
  }
}
