// Path: packages/canvas_background_removal_isnet/lib/src/lanczos3.dart

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Pillow-compatible 8-bit Lanczos-3 resampling for the pinned rembg path.
///
/// rembg uses Pillow's `Image.Resampling.LANCZOS` for both the RGB model input
/// resize and the final 8-bit mask resize. Pillow's 8-bit implementation is not
/// just a floating-point separable Lanczos convolution: coefficients are
/// normalized and quantized to fixed-point, and the horizontal pass is rounded
/// back to 8-bit before the vertical pass. Reproducing those details keeps the
/// Flutter runtime aligned with the frozen Python reference pipeline.
abstract final class Lanczos3 {
  static const double _radius = 3.0;
  static const int _precisionBits = 22;
  static const int _coefficientScale = 1 << _precisionBits;
  static const int _roundingBias = 1 << (_precisionBits - 1);

  static img.Image resizeRgb8(
    img.Image source, {
    required int width,
    required int height,
  }) {
    _validateDimensions(width, height);

    if (source.width == width && source.height == height) {
      return img.Image.from(source, noAnimation: true);
    }

    final horizontal = _buildCoefficients(source.width, width);
    final vertical = _buildCoefficients(source.height, height);
    final temporary = Uint8List(width * source.height * 3);

    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < width; x++) {
        final coefficients = horizontal[x];
        var red = _roundingBias;
        var green = _roundingBias;
        var blue = _roundingBias;

        for (var index = 0; index < coefficients.weights.length; index++) {
          final pixel = source.getPixel(coefficients.start + index, y);
          final weight = coefficients.weights[index];
          red += pixel.r.toInt() * weight;
          green += pixel.g.toInt() * weight;
          blue += pixel.b.toInt() * weight;
        }

        final offset = (y * width + x) * 3;
        temporary[offset] = _clip8(red);
        temporary[offset + 1] = _clip8(green);
        temporary[offset + 2] = _clip8(blue);
      }
    }

    final result = img.Image(width: width, height: height, numChannels: 3);

    for (var y = 0; y < height; y++) {
      final coefficients = vertical[y];

      for (var x = 0; x < width; x++) {
        var red = _roundingBias;
        var green = _roundingBias;
        var blue = _roundingBias;

        for (var index = 0; index < coefficients.weights.length; index++) {
          final offset = ((coefficients.start + index) * width + x) * 3;
          final weight = coefficients.weights[index];
          red += temporary[offset] * weight;
          green += temporary[offset + 1] * weight;
          blue += temporary[offset + 2] * weight;
        }

        result.setPixelRgb(x, y, _clip8(red), _clip8(green), _clip8(blue));
      }
    }

    return result;
  }

  /// Resizes an 8-bit single-channel image using Pillow-compatible Lanczos.
  ///
  /// This mirrors rembg's postprocessing path after it converts the normalized
  /// model mask to `uint8` and constructs a Pillow `L` image.
  static Uint8List resizeGray8(
    Uint8List source, {
    required int sourceWidth,
    required int sourceHeight,
    required int width,
    required int height,
  }) {
    _validateDimensions(sourceWidth, sourceHeight);
    _validateDimensions(width, height);

    if (source.length != sourceWidth * sourceHeight) {
      throw ArgumentError.value(
        source.length,
        'source.length',
        'Expected ${sourceWidth * sourceHeight} grayscale values.',
      );
    }

    if (sourceWidth == width && sourceHeight == height) {
      return Uint8List.fromList(source);
    }

    final horizontal = _buildCoefficients(sourceWidth, width);
    final vertical = _buildCoefficients(sourceHeight, height);
    final temporary = Uint8List(width * sourceHeight);

    for (var y = 0; y < sourceHeight; y++) {
      for (var x = 0; x < width; x++) {
        final coefficients = horizontal[x];
        var value = _roundingBias;

        for (var index = 0; index < coefficients.weights.length; index++) {
          value +=
              source[y * sourceWidth + coefficients.start + index] *
              coefficients.weights[index];
        }

        temporary[y * width + x] = _clip8(value);
      }
    }

    final result = Uint8List(width * height);

    for (var y = 0; y < height; y++) {
      final coefficients = vertical[y];

      for (var x = 0; x < width; x++) {
        var value = _roundingBias;

        for (var index = 0; index < coefficients.weights.length; index++) {
          value +=
              temporary[(coefficients.start + index) * width + x] *
              coefficients.weights[index];
        }

        result[y * width + x] = _clip8(value);
      }
    }

    return result;
  }

  static List<_Coefficients> _buildCoefficients(
    int sourceSize,
    int destinationSize,
  ) {
    final scale = sourceSize / destinationSize;
    final filterScale = math.max(1.0, scale);
    final support = _radius * filterScale;
    final inverseFilterScale = 1.0 / filterScale;

    return List<_Coefficients>.generate(destinationSize, (destination) {
      final center = (destination + 0.5) * scale;

      var start = (center - support + 0.5).toInt();
      if (start < 0) {
        start = 0;
      }

      var end = (center + support + 0.5).toInt();
      if (end > sourceSize) {
        end = sourceSize;
      }

      final count = end - start;
      final floatingWeights = List<double>.filled(count, 0.0, growable: false);
      var total = 0.0;

      for (var index = 0; index < count; index++) {
        final distance = (index + start - center + 0.5) * inverseFilterScale;
        final weight = _lanczos(distance);
        floatingWeights[index] = weight;
        total += weight;
      }

      if (total != 0.0) {
        for (var index = 0; index < floatingWeights.length; index++) {
          floatingWeights[index] /= total;
        }
      }

      final quantized = Int32List(count);
      for (var index = 0; index < floatingWeights.length; index++) {
        final weight = floatingWeights[index];
        final scaled = weight * _coefficientScale;
        quantized[index] = weight < 0.0
            ? (scaled - 0.5).toInt()
            : (scaled + 0.5).toInt();
      }

      return _Coefficients(start: start, weights: quantized);
    }, growable: false);
  }

  static double _lanczos(double x) {
    if (x < -_radius || x >= _radius) {
      return 0.0;
    }
    return _sinc(x) * _sinc(x / _radius);
  }

  static double _sinc(double x) {
    if (x == 0.0) {
      return 1.0;
    }
    final angle = math.pi * x;
    return math.sin(angle) / angle;
  }

  static int _clip8(int accumulator) {
    final value = accumulator >> _precisionBits;
    return value.clamp(0, 255).toInt();
  }

  static void _validateDimensions(int width, int height) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError(
        'Image dimensions must be positive: $width x $height.',
      );
    }
  }
}

final class _Coefficients {
  const _Coefficients({required this.start, required this.weights});

  final int start;
  final Int32List weights;
}
