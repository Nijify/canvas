// Path: packages/canvas_background_removal/lib/src/background_removal_processor.dart

import 'dart:typed_data';

import 'background_removal_provider.dart';

import 'encoded_raster_inspector.dart';

enum BackgroundRemovalProcessFailureKind {
  unsupportedInput,
  temporarilyUnavailable,
  failed,
}

final class BackgroundRemovalProcessedImage {
  const BackgroundRemovalProcessedImage({
    required this.bytes,
    required this.widthPx,
    required this.heightPx,
  });

  final Uint8List bytes;
  final int widthPx;
  final int heightPx;
}

sealed class BackgroundRemovalProcessResult {
  const BackgroundRemovalProcessResult();
}

final class BackgroundRemovalProcessSuccess
    extends BackgroundRemovalProcessResult {
  const BackgroundRemovalProcessSuccess(this.image);

  final BackgroundRemovalProcessedImage image;
}

final class BackgroundRemovalProcessFailure
    extends BackgroundRemovalProcessResult {
  const BackgroundRemovalProcessFailure(this.kind);

  final BackgroundRemovalProcessFailureKind kind;
}

abstract interface class BackgroundRemovalProcessor {
  Future<BackgroundRemovalProcessResult> process({
    required Uint8List inputBytes,
  });
}

final class ValidatedBackgroundRemovalProcessor
    implements BackgroundRemovalProcessor {
  ValidatedBackgroundRemovalProcessor({
    required BackgroundRemovalByteProcessor remover,
    EncodedRasterInspector? rasterInspector,
  }) : _remover = remover,
       _rasterInspector =
           rasterInspector ?? const FlutterEncodedRasterInspector();

  final BackgroundRemovalByteProcessor _remover;
  final EncodedRasterInspector _rasterInspector;

  @override
  Future<BackgroundRemovalProcessResult> process({
    required Uint8List inputBytes,
  }) async {
    if (inputBytes.isEmpty) {
      return const BackgroundRemovalProcessFailure(
        BackgroundRemovalProcessFailureKind.unsupportedInput,
      );
    }

    final EncodedRasterInfo inputRaster;

    try {
      inputRaster = await _rasterInspector.inspect(inputBytes);
    } catch (_) {
      return const BackgroundRemovalProcessFailure(
        BackgroundRemovalProcessFailureKind.unsupportedInput,
      );
    }

    if (!_isSupportedBackgroundRemovalInput(inputRaster)) {
      return const BackgroundRemovalProcessFailure(
        BackgroundRemovalProcessFailureKind.unsupportedInput,
      );
    }

    final Uint8List foregroundPng;

    try {
      foregroundPng = await _remover.remove(inputBytes);
    } on BackgroundRemovalProviderException catch (error) {
      return BackgroundRemovalProcessFailure(switch (error.kind) {
        BackgroundRemovalProviderFailureKind.temporarilyUnavailable =>
          BackgroundRemovalProcessFailureKind.temporarilyUnavailable,

        // Provider/platform availability is not the same thing as an
        // unsupported encoded input.
        BackgroundRemovalProviderFailureKind.unsupported ||
        BackgroundRemovalProviderFailureKind.failed =>
          BackgroundRemovalProcessFailureKind.failed,
      });
    } catch (_) {
      return const BackgroundRemovalProcessFailure(
        BackgroundRemovalProcessFailureKind.failed,
      );
    }

    if (foregroundPng.isEmpty) {
      return const BackgroundRemovalProcessFailure(
        BackgroundRemovalProcessFailureKind.failed,
      );
    }

    final EncodedRasterInfo outputRaster;

    try {
      outputRaster = await _rasterInspector.inspect(foregroundPng);
    } catch (_) {
      return const BackgroundRemovalProcessFailure(
        BackgroundRemovalProcessFailureKind.failed,
      );
    }

    if (!_isValidBackgroundRemovalOutput(
      input: inputRaster,
      output: outputRaster,
      outputBytes: foregroundPng,
    )) {
      return const BackgroundRemovalProcessFailure(
        BackgroundRemovalProcessFailureKind.failed,
      );
    }

    return BackgroundRemovalProcessSuccess(
      BackgroundRemovalProcessedImage(
        bytes: foregroundPng,
        widthPx: outputRaster.width,
        heightPx: outputRaster.height,
      ),
    );
  }
}

bool _isSupportedBackgroundRemovalInput(EncodedRasterInfo raster) {
  if (!raster.hasPositiveDimensions || !raster.isStatic) {
    return false;
  }

  return switch (raster.format) {
    EncodedRasterFormat.png ||
    EncodedRasterFormat.jpeg ||
    EncodedRasterFormat.webp => true,

    EncodedRasterFormat.gif || EncodedRasterFormat.unknown => false,
  };
}

bool _isValidBackgroundRemovalOutput({
  required EncodedRasterInfo input,
  required EncodedRasterInfo output,
  required Uint8List outputBytes,
}) {
  if (!output.hasPositiveDimensions || !output.isStatic) {
    return false;
  }

  if (output.format != EncodedRasterFormat.png) {
    return false;
  }

  if (!pngSupportsTransparency(outputBytes)) {
    return false;
  }

  if (output.width != input.width || output.height != input.height) {
    return false;
  }

  return true;
}
