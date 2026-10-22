// Path: private_packages/bg_remover_isnet/lib/src/isnet_inference_engine.dart

import 'dart:typed_data';

enum IsnetEngineKind {
  interpreter,
  compiledCpu,
  compiledGpu,
  compiledGpuFp16;

  String get label => switch (this) {
    IsnetEngineKind.interpreter => 'Interpreter',
    IsnetEngineKind.compiledCpu => 'CompiledModel CPU fp32',
    IsnetEngineKind.compiledGpu => 'CompiledModel GPU fp32',
    IsnetEngineKind.compiledGpuFp16 => 'CompiledModel GPU fp16',
  };
}

abstract interface class IsnetInferenceEngine {
  IsnetEngineKind get kind;

  Duration get lastInferenceDuration;

  /// Effective accelerator names reported by the runtime.
  List<String> get activeAccelerators;

  /// Whether LiteRT Next reports the whole graph as accelerator-backed.
  ///
  /// `null` for the classic Interpreter path where the property does not apply.
  bool? get isFullyAccelerated;

  void runInto({required Float32List input, required Float32List output});

  void close();
}
