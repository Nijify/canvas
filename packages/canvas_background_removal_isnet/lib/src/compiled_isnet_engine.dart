// Path: private_packages/bg_remover_isnet/lib/src/compiled_isnet_engine.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:canvas_background_removal_isnet/src/isnet_failure.dart';
import 'package:canvas_background_removal_isnet/src/isnet_inference_engine.dart';
import 'package:canvas_background_removal_isnet/src/isnet_model_contract.dart';
import 'package:canvas_background_removal_isnet/src/isnet_model_verifier.dart';
import 'package:flutter_litert/flutter_litert.dart';

/// Experimental LiteRT Next engine used only by the #1209 benchmark harness.
///
/// The classic Interpreter remains the reference implementation. This engine
/// uses host-memory tensor buffers so the 12-output ISNet graph does not create
/// fresh Dart buffers for every declared output on each dispatch; only output
/// ordinal 0 is copied into the caller-owned primary-mask buffer.
final class CompiledIsnetEngine implements IsnetInferenceEngine {
  CompiledIsnetEngine._(
    this._model,
    this._kind,
    this._activeAccelerators,
    this._isFullyAccelerated,
  );

  final CompiledModel _model;
  final IsnetEngineKind _kind;
  final List<String> _activeAccelerators;
  final bool _isFullyAccelerated;

  bool _closed = false;
  Duration _lastInferenceDuration = Duration.zero;

  static Future<CompiledIsnetEngine> open({
    required File modelFile,
    required IsnetEngineKind kind,
    IsnetModelVerifier verifier = const IsnetModelVerifier(),
  }) async {
    if (kind != IsnetEngineKind.compiledCpu &&
        kind != IsnetEngineKind.compiledGpu &&
        kind != IsnetEngineKind.compiledGpuFp16) {
      throw ArgumentError.value(
        kind,
        'kind',
        'CompiledIsnetEngine requires a compiled engine kind.',
      );
    }

    await verifier.verify(modelFile);

    late final CompiledModel model;
    try {
      model = CompiledModel.fromFile(
        modelFile.path,
        accelerators: switch (kind) {
          IsnetEngineKind.compiledCpu => const <Accelerator>{Accelerator.cpu},
          IsnetEngineKind.compiledGpu || IsnetEngineKind.compiledGpuFp16 =>
            const <Accelerator>{Accelerator.gpu},
          IsnetEngineKind.interpreter => throw StateError(
            'Interpreter cannot be opened as a CompiledModel.',
          ),
        },
        precision: switch (kind) {
          IsnetEngineKind.compiledGpuFp16 => Precision.fp16,
          IsnetEngineKind.compiledCpu ||
          IsnetEngineKind.compiledGpu => Precision.fp32,
          IsnetEngineKind.interpreter => throw StateError(
            'Interpreter does not have a CompiledModel precision.',
          ),
        },
        tensorBufferMode: TensorBufferMode.hostMemory,
      );
    } catch (error) {
      throw IsnetException(IsnetFailureKind.modelOpenFailed, cause: error);
    }

    try {
      _validateCompiledContract(model);
      final activeAccelerators = List<String>.unmodifiable(
        model.accelerators.map((accelerator) => accelerator.name),
      );
      final isFullyAccelerated = model.isFullyAccelerated;
      return CompiledIsnetEngine._(
        model,
        kind,
        activeAccelerators,
        isFullyAccelerated,
      );
    } on IsnetException {
      _bestEffortClose(model);
      rethrow;
    } catch (error) {
      _bestEffortClose(model);
      throw IsnetException(
        IsnetFailureKind.modelContractMismatch,
        cause: error,
      );
    }
  }

  @override
  IsnetEngineKind get kind => _kind;

  @override
  List<String> get activeAccelerators => _activeAccelerators;

  @override
  bool get isFullyAccelerated => _isFullyAccelerated;

  @override
  Duration get lastInferenceDuration => _lastInferenceDuration;

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
      _model.writeInput(
        IsnetModelContract.inputOrdinal,
        (buffer) => buffer.setAll(0, input),
      );

      final stopwatch = Stopwatch()..start();
      _model.dispatch();
      stopwatch.stop();
      _lastInferenceDuration = stopwatch.elapsed;

      _model.readOutput(IsnetModelContract.primaryOutputOrdinal, (buffer) {
        output.setAll(0, buffer);
      });
    } catch (error) {
      throw IsnetException(IsnetFailureKind.inferenceFailed, cause: error);
    }
  }

  @override
  void close() {
    if (_closed) {
      return;
    }

    _model.close();
    _closed = true;
  }

  void _ensureOpen() {
    if (_closed) {
      throw const IsnetException(
        IsnetFailureKind.closed,
        cause: 'ISNet CompiledModel engine is already closed.',
      );
    }
  }

  static void _validateCompiledContract(CompiledModel model) {
    final inputByteSizes = model.inputByteSizes;
    final outputByteSizes = model.outputByteSizes;

    if (inputByteSizes.length != 1) {
      throw IsnetException(
        IsnetFailureKind.modelContractMismatch,
        cause:
            'CompiledModel expected 1 input tensor, found '
            '${inputByteSizes.length}.',
      );
    }

    final expectedInputBytes = IsnetModelContract.inputElementCount * 4;
    if (inputByteSizes[IsnetModelContract.inputOrdinal] != expectedInputBytes) {
      throw IsnetException(
        IsnetFailureKind.modelContractMismatch,
        cause:
            'CompiledModel input ordinal 0 byte-size mismatch: expected '
            '$expectedInputBytes, found '
            '${inputByteSizes[IsnetModelContract.inputOrdinal]}.',
      );
    }

    if (outputByteSizes.length != IsnetModelContract.outputs.length) {
      throw IsnetException(
        IsnetFailureKind.modelContractMismatch,
        cause:
            'CompiledModel expected ${IsnetModelContract.outputs.length} '
            'output tensors, found ${outputByteSizes.length}.',
      );
    }

    for (
      var ordinal = 0;
      ordinal < IsnetModelContract.outputs.length;
      ordinal++
    ) {
      final expectedBytes =
          _elementCount(IsnetModelContract.outputs[ordinal].shape) * 4;
      if (outputByteSizes[ordinal] != expectedBytes) {
        throw IsnetException(
          IsnetFailureKind.modelContractMismatch,
          cause:
              'CompiledModel output ordinal $ordinal byte-size mismatch: '
              'expected $expectedBytes, found ${outputByteSizes[ordinal]}.',
        );
      }
    }
  }

  static int _elementCount(List<int> shape) {
    var count = 1;
    for (final dimension in shape) {
      count *= dimension;
    }
    return count;
  }

  static void _bestEffortClose(CompiledModel model) {
    try {
      model.close();
    } catch (_) {
      // Preserve the original compile/contract failure.
    }
  }
}
