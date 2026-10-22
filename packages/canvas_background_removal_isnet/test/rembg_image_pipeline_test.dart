// Path: private_packages/bg_remover_isnet/test/rembg_image_pipeline_test.dart

import 'dart:typed_data';

import 'package:canvas_background_removal_isnet/src/isnet_failure.dart';
import 'package:canvas_background_removal_isnet/src/isnet_model_contract.dart';
import 'package:canvas_background_removal_isnet/src/rembg_image_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  const pipeline = RembgImagePipeline();

  test('prepareInto uses resized-image max normalization and NHWC order', () {
    final source = img.Image(width: 2, height: 3, numChannels: 3);
    for (final pixel in source) {
      pixel.setRgb(128, 64, 0);
    }

    final encoded = img.encodePng(source, singleFrame: true);
    final input = Float32List(IsnetModelContract.inputElementCount);

    final prepared = pipeline.prepareInto(
      encodedBytes: encoded,
      inputTensor: input,
    );

    expect(prepared.width, 2);
    expect(prepared.height, 3);

    expect(input[0], closeTo(0.5, 1e-6));
    expect(input[1], closeTo(0.0, 1e-6));
    expect(input[2], closeTo(-0.5, 1e-6));

    final last = input.length - 3;
    expect(input[last], closeTo(0.5, 1e-6));
    expect(input[last + 1], closeTo(0.0, 1e-6));
    expect(input[last + 2], closeTo(-0.5, 1e-6));
  });

  test('composePng rejects a constant primary mask', () {
    final source = img.Image(width: 2, height: 2, numChannels: 3)
      ..setPixelRgb(0, 0, 255, 0, 0)
      ..setPixelRgb(1, 0, 0, 255, 0)
      ..setPixelRgb(0, 1, 0, 0, 255)
      ..setPixelRgb(1, 1, 255, 255, 255);

    final prepared = pipeline.prepareInto(
      encodedBytes: img.encodePng(source, singleFrame: true),
      inputTensor: Float32List(IsnetModelContract.inputElementCount),
    );

    final rawMask = Float32List(IsnetModelContract.primaryOutputElementCount)
      ..fillRange(0, IsnetModelContract.primaryOutputElementCount, 0.25);

    expect(
      () => pipeline.composePng(prepared: prepared, rawMask: rawMask),
      throwsA(
        isA<IsnetException>().having(
          (error) => error.kind,
          'kind',
          IsnetFailureKind.invalidOutput,
        ),
      ),
    );
  });

  test('composePng rejects non-finite primary-mask values', () {
    final source = img.Image(width: 1, height: 1, numChannels: 3)
      ..setPixelRgb(0, 0, 255, 255, 255);

    final prepared = pipeline.prepareInto(
      encodedBytes: img.encodePng(source, singleFrame: true),
      inputTensor: Float32List(IsnetModelContract.inputElementCount),
    );

    final rawMask = Float32List(IsnetModelContract.primaryOutputElementCount);
    rawMask[0] = double.nan;

    expect(
      () => pipeline.composePng(prepared: prepared, rawMask: rawMask),
      throwsA(
        isA<IsnetException>().having(
          (error) => error.kind,
          'kind',
          IsnetFailureKind.invalidOutput,
        ),
      ),
    );
  });

  test('composePng returns display-oriented dimensions with alpha', () {
    final source = img.Image(width: 2, height: 3, numChannels: 3);
    for (final pixel in source) {
      pixel.setRgb(30 + pixel.x * 40, 50 + pixel.y * 20, 90);
    }

    final prepared = pipeline.prepareInto(
      encodedBytes: img.encodePng(source, singleFrame: true),
      inputTensor: Float32List(IsnetModelContract.inputElementCount),
    );

    final rawMask = Float32List(IsnetModelContract.primaryOutputElementCount);
    for (var y = 0; y < RembgImagePipeline.modelHeight; y++) {
      for (var x = 0; x < RembgImagePipeline.modelWidth; x++) {
        rawMask[y * RembgImagePipeline.modelWidth + x] =
            x / (RembgImagePipeline.modelWidth - 1);
      }
    }

    final png = pipeline.composePng(prepared: prepared, rawMask: rawMask);
    final decoded = img.decodePng(png);

    expect(decoded, isNotNull);
    expect(decoded!.width, 2);
    expect(decoded.height, 3);
    expect(decoded.numChannels, 4);
    expect(decoded.getPixel(0, 1).a, lessThan(decoded.getPixel(1, 1).a));
  });
}
