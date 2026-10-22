// Path: private_packages/bg_remover_isnet/lib/src/isnet_background_remover.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:canvas_background_removal_isnet/src/compiled_isnet_engine.dart';
import 'package:canvas_background_removal_isnet/src/isnet_failure.dart';
import 'package:canvas_background_removal_isnet/src/isnet_inference_engine.dart';
import 'package:canvas_background_removal_isnet/src/isnet_model_contract.dart';
import 'package:canvas_background_removal_isnet/src/isnet_model_verifier.dart';
import 'package:canvas_background_removal_isnet/src/litert_isnet_engine.dart';
import 'package:canvas_background_removal_isnet/src/rembg_image_pipeline.dart';

final class IsnetRunMetrics {
  const IsnetRunMetrics({
    required this.preprocessingDuration,
    required this.inferenceDuration,
    required this.postprocessingDuration,
    required this.totalDuration,
    required this.rssBeforeBytes,
    required this.rssAfterBytes,
    required this.maxRssBytes,
  });

  final Duration preprocessingDuration;
  final Duration inferenceDuration;
  final Duration postprocessingDuration;
  final Duration totalDuration;

  /// Process-wide resident set size sampled immediately before preprocessing.
  final int rssBeforeBytes;

  /// Process-wide resident set size sampled after PNG composition completes.
  final int rssAfterBytes;

  /// Highest process RSS observed for this operation.
  ///
  /// Direct synchronous removals observe stage boundaries. [IsnetWorker]
  /// replaces this with a higher-frequency caller-isolate sampler so benchmark
  /// backend comparisons are not contaminated by process-lifetime max RSS.
  final int maxRssBytes;
}

final class IsnetRemovalResult {
  const IsnetRemovalResult({
    required this.pngBytes,
    required this.widthPx,
    required this.heightPx,
    required this.metrics,
  });

  final Uint8List pngBytes;
  final int widthPx;
  final int heightPx;
  final IsnetRunMetrics metrics;
}

/// Development-only local-file ISNet background remover.
///
/// The default remains the verified classic Interpreter reference. Compiled
/// engines exist only so #1209 can measure LiteRT Next CPU/GPU precision modes
/// on the same frozen image pipeline before any production promotion decision.
final class IsnetBackgroundRemover {
  IsnetBackgroundRemover._(this._engine, this._pipeline)
    : _inputTensor = Float32List(IsnetModelContract.inputElementCount),
      _rawMask = Float32List(IsnetModelContract.primaryOutputElementCount);

  final IsnetInferenceEngine _engine;
  final RembgImagePipeline _pipeline;
  final Float32List _inputTensor;
  final Float32List _rawMask;

  bool _closed = false;

  static Future<IsnetBackgroundRemover> open({
    required File modelFile,
    IsnetEngineKind engineKind = IsnetEngineKind.interpreter,
    IsnetModelVerifier verifier = const IsnetModelVerifier(),
    RembgImagePipeline pipeline = const RembgImagePipeline(),
  }) async {
    final IsnetInferenceEngine engine = switch (engineKind) {
      IsnetEngineKind.interpreter => await LiteRtIsnetEngine.open(
        modelFile: modelFile,
        verifier: verifier,
      ),
      IsnetEngineKind.compiledCpu ||
      IsnetEngineKind.compiledGpu ||
      IsnetEngineKind.compiledGpuFp16 => await CompiledIsnetEngine.open(
        modelFile: modelFile,
        kind: engineKind,
        verifier: verifier,
      ),
    };

    return IsnetBackgroundRemover._(engine, pipeline);
  }

  IsnetEngineKind get engineKind => _engine.kind;

  List<String> get activeAccelerators => _engine.activeAccelerators;

  bool? get isFullyAccelerated => _engine.isFullyAccelerated;

  IsnetRemovalResult remove(Uint8List encodedBytes) {
    _ensureOpen();

    final rssBeforeBytes = ProcessInfo.currentRss;
    var maxRssBytes = rssBeforeBytes;
    final totalStopwatch = Stopwatch()..start();
    final preprocessingStopwatch = Stopwatch()..start();

    final prepared = _pipeline.prepareInto(
      encodedBytes: encodedBytes,
      inputTensor: _inputTensor,
    );

    preprocessingStopwatch.stop();
    maxRssBytes = _maxInt(maxRssBytes, ProcessInfo.currentRss);

    _engine.runInto(input: _inputTensor, output: _rawMask);
    maxRssBytes = _maxInt(maxRssBytes, ProcessInfo.currentRss);

    final postprocessingStopwatch = Stopwatch()..start();
    final pngBytes = _pipeline.composePng(
      prepared: prepared,
      rawMask: _rawMask,
    );
    postprocessingStopwatch.stop();
    totalStopwatch.stop();

    final rssAfterBytes = ProcessInfo.currentRss;
    maxRssBytes = _maxInt(maxRssBytes, rssAfterBytes);

    return IsnetRemovalResult(
      pngBytes: pngBytes,
      widthPx: prepared.width,
      heightPx: prepared.height,
      metrics: IsnetRunMetrics(
        preprocessingDuration: preprocessingStopwatch.elapsed,
        inferenceDuration: _engine.lastInferenceDuration,
        postprocessingDuration: postprocessingStopwatch.elapsed,
        totalDuration: totalStopwatch.elapsed,
        rssBeforeBytes: rssBeforeBytes,
        rssAfterBytes: rssAfterBytes,
        maxRssBytes: maxRssBytes,
      ),
    );
  }

  void close() {
    if (_closed) {
      return;
    }

    _engine.close();
    _closed = true;
  }

  void _ensureOpen() {
    if (_closed) {
      throw const IsnetException(
        IsnetFailureKind.closed,
        cause: 'ISNet background remover is already closed.',
      );
    }
  }
}

int _maxInt(int left, int right) => left > right ? left : right;
