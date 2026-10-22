// Path: private_packages/bg_remover_isnet/lib/src/rembg_image_pipeline.dart

import 'dart:typed_data';

import 'package:canvas_background_removal_isnet/src/isnet_failure.dart';
import 'package:canvas_background_removal_isnet/src/isnet_model_contract.dart';
import 'package:canvas_background_removal_isnet/src/lanczos3.dart';
import 'package:image/image.dart' as img;

final class RembgPreparedImage {
  RembgPreparedImage._(this._displayRgb);

  final img.Image _displayRgb;

  int get width => _displayRgb.width;
  int get height => _displayRgb.height;
}

/// Pure image preprocessing/postprocessing for the pinned rembg ISNet recipe.
///
/// This layer owns no model loading, LiteRT lifecycle, storage, downloading, or
/// provider selection. It converts encoded image bytes into the frozen NHWC
/// float32 tensor contract and converts the raw primary mask back into a PNG.
final class RembgImagePipeline {
  const RembgImagePipeline();

  static const int modelWidth = 1024;
  static const int modelHeight = 1024;
  static const double _normalizationFloor = 1e-6;
  static const double _maskRangeFloor = 1e-12;

  RembgPreparedImage prepareInto({
    required Uint8List encodedBytes,
    required Float32List inputTensor,
  }) {
    if (inputTensor.length != IsnetModelContract.inputElementCount) {
      throw IsnetException(
        IsnetFailureKind.invalidInput,
        cause:
            'Input tensor element count mismatch: expected '
            '${IsnetModelContract.inputElementCount}, '
            'found ${inputTensor.length}.',
      );
    }

    if (encodedBytes.isEmpty) {
      throw const IsnetException(
        IsnetFailureKind.invalidInput,
        cause: 'Input image bytes are empty.',
      );
    }

    late final img.Image displayOriented;
    try {
      final decoded = img.decodeImage(encodedBytes);
      if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
        throw const IsnetException(
          IsnetFailureKind.invalidInput,
          cause: 'Input bytes are not a decodable image.',
        );
      }
      displayOriented = img.bakeOrientation(decoded);
    } on IsnetException {
      rethrow;
    } catch (error) {
      throw IsnetException(IsnetFailureKind.invalidInput, cause: error);
    }

    final displayRgb = _toRgb8(displayOriented);
    final resized = Lanczos3.resizeRgb8(
      displayRgb,
      width: modelWidth,
      height: modelHeight,
    );

    var maxValue = 0.0;
    for (final pixel in resized) {
      final red = pixel.r.toDouble();
      final green = pixel.g.toDouble();
      final blue = pixel.b.toDouble();
      if (red > maxValue) maxValue = red;
      if (green > maxValue) maxValue = green;
      if (blue > maxValue) maxValue = blue;
    }

    final divisor = maxValue > _normalizationFloor
        ? maxValue
        : _normalizationFloor;

    var offset = 0;
    for (var y = 0; y < modelHeight; y++) {
      for (var x = 0; x < modelWidth; x++) {
        final pixel = resized.getPixel(x, y);
        inputTensor[offset++] = pixel.r.toDouble() / divisor - 0.5;
        inputTensor[offset++] = pixel.g.toDouble() / divisor - 0.5;
        inputTensor[offset++] = pixel.b.toDouble() / divisor - 0.5;
      }
    }

    return RembgPreparedImage._(displayRgb);
  }

  Uint8List composePng({
    required RembgPreparedImage prepared,
    required Float32List rawMask,
  }) {
    if (rawMask.length != IsnetModelContract.primaryOutputElementCount) {
      throw IsnetException(
        IsnetFailureKind.invalidOutput,
        cause:
            'Mask element count mismatch: expected '
            '${IsnetModelContract.primaryOutputElementCount}, '
            'found ${rawMask.length}.',
      );
    }

    var minimum = double.infinity;
    var maximum = double.negativeInfinity;

    for (final value in rawMask) {
      if (!value.isFinite) {
        throw const IsnetException(
          IsnetFailureKind.invalidOutput,
          cause: 'Primary mask contains NaN or infinite values.',
        );
      }
      if (value < minimum) minimum = value;
      if (value > maximum) maximum = value;
    }

    final range = maximum - minimum;
    if (!range.isFinite || range.abs() <= _maskRangeFloor) {
      throw IsnetException(
        IsnetFailureKind.invalidOutput,
        cause:
            'Primary mask has no usable dynamic range: '
            'min=$minimum max=$maximum.',
      );
    }

    // Match rembg exactly: normalize in floating point, multiply by 255, cast
    // to uint8 (truncating positive values), then resize the Pillow `L` image.
    final normalizedMask8 = Uint8List(rawMask.length);
    for (var index = 0; index < rawMask.length; index++) {
      final normalized = (rawMask[index] - minimum) / range;
      normalizedMask8[index] = (normalized * 255.0)
          .toInt()
          .clamp(0, 255)
          .toInt();
    }

    final resizedMask = Lanczos3.resizeGray8(
      normalizedMask8,
      sourceWidth: modelWidth,
      sourceHeight: modelHeight,
      width: prepared.width,
      height: prepared.height,
    );

    final output = img.Image(
      width: prepared.width,
      height: prepared.height,
      numChannels: 4,
    );

    for (var y = 0; y < prepared.height; y++) {
      for (var x = 0; x < prepared.width; x++) {
        final source = prepared._displayRgb.getPixel(x, y);
        final alpha = resizedMask[y * prepared.width + x];
        output.setPixelRgba(x, y, source.r, source.g, source.b, alpha);
      }
    }

    try {
      return img.encodePng(output, singleFrame: true);
    } catch (error) {
      throw IsnetException(IsnetFailureKind.invalidOutput, cause: error);
    }
  }

  static img.Image _toRgb8(img.Image source) {
    final result = img.Image(
      width: source.width,
      height: source.height,
      numChannels: 3,
    );

    for (final pixel in source) {
      result.setPixelRgb(
        pixel.x,
        pixel.y,
        (pixel.rNormalized * 255.0).round(),
        (pixel.gNormalized * 255.0).round(),
        (pixel.bNormalized * 255.0).round(),
      );
    }

    return result;
  }
}
