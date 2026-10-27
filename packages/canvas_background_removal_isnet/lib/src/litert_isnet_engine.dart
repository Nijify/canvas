// Path: packages/canvas_background_removal_isnet/lib/src/litert_isnet_engine.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:canvas_background_removal_isnet/src/isnet_failure.dart';
import 'package:canvas_background_removal_isnet/src/isnet_inference_engine.dart';
import 'package:canvas_background_removal_isnet/src/isnet_model_contract.dart';
import 'package:canvas_background_removal_isnet/src/isnet_model_verifier.dart';
import 'package:flutter_litert/flutter_litert.dart';

final class LiteRtIsnetEngine implements IsnetInferenceEngine {
  LiteRtIsnetEngine._(this._interpreter);

  final Interpreter _interpreter;
  bool _closed = false;

  static Future<LiteRtIsnetEngine> open({
    required File modelFile,
    IsnetModelVerifier verifier = const IsnetModelVerifier(),
  }) async {
    await verifier.verify(modelFile);

    late final Interpreter interpreter;
    try {
      interpreter = Interpreter.fromFile(modelFile);
    } catch (error) {
      throw IsnetException(IsnetFailureKind.modelOpenFailed, cause: error);
    }

    try {
      IsnetModelContract.validate(
        inputs: interpreter
            .getInputTensors()
            .map(_describeTensor)
            .toList(growable: false),
        outputs: interpreter
            .getOutputTensors()
            .map(_describeTensor)
            .toList(growable: false),
      );
    } on IsnetException {
      _bestEffortClose(interpreter);
      rethrow;
    } catch (error) {
      _bestEffortClose(interpreter);
      throw IsnetException(
        IsnetFailureKind.modelContractMismatch,
        cause: error,
      );
    }

    return LiteRtIsnetEngine._(interpreter);
  }

  @override
  IsnetEngineKind get kind => IsnetEngineKind.interpreter;

  @override
  List<String> get activeAccelerators => const <String>['classic'];

  @override
  bool? get isFullyAccelerated => null;

  int get inputElementCount => IsnetModelContract.inputElementCount;

  int get primaryOutputElementCount =>
      IsnetModelContract.primaryOutputElementCount;

  @override
  Duration get lastInferenceDuration =>
      Duration(microseconds: _interpreter.lastInferenceDurationMicroseconds);

  /// Runs one already-preprocessed NHWC float32 tensor and copies only the
  /// frozen primary output ordinal into [output].
  @override
  void runInto({required Float32List input, required Float32List output}) {
    _ensureOpen();

    if (input.length != IsnetModelContract.inputElementCount) {
      throw IsnetException(
        IsnetFailureKind.invalidInput,
        cause:
            'Input element count mismatch: expected '
            '${IsnetModelContract.inputElementCount}, found ${input.length}.',
      );
    }

    if (output.length != IsnetModelContract.primaryOutputElementCount) {
      throw IsnetException(
        IsnetFailureKind.invalidInput,
        cause:
            'Output buffer element count mismatch: expected '
            '${IsnetModelContract.primaryOutputElementCount}, '
            'found ${output.length}.',
      );
    }

    try {
      // The model declares 12 outputs. flutter_litert's classic
      // runForMultipleInputs implementation copies every declared output, so
      // a map containing only ordinal 0 is not sufficient for this graph.
      // Invoke once, then copy only the verified primary output ordinal.
      _interpreter.runInference(<Object>[input]);
      _interpreter
          .getOutputTensor(IsnetModelContract.primaryOutputOrdinal)
          .copyTo(output);
    } catch (error) {
      throw IsnetException(IsnetFailureKind.inferenceFailed, cause: error);
    }
  }

  @override
  void close() {
    if (_closed) {
      return;
    }

    _interpreter.close();
    _closed = true;
  }

  void _ensureOpen() {
    if (_closed) {
      throw const IsnetException(
        IsnetFailureKind.closed,
        cause: 'ISNet LiteRT engine is already closed.',
      );
    }
  }

  static IsnetTensorDescriptor _describeTensor(Tensor tensor) {
    return IsnetTensorDescriptor(
      name: tensor.name,
      dtype: tensor.type.name,
      shape: List<int>.unmodifiable(tensor.shape),
    );
  }

  static void _bestEffortClose(Interpreter interpreter) {
    try {
      interpreter.close();
    } catch (_) {
      // Preserve the original open/contract failure.
    }
  }
}
