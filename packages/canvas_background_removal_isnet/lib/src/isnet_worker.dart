// Path: packages/canvas_background_removal_isnet/lib/src/isnet_worker.dart

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:canvas_background_removal_isnet/src/isnet_background_remover.dart';
import 'package:canvas_background_removal_isnet/src/isnet_failure.dart';
import 'package:canvas_background_removal_isnet/src/isnet_inference_engine.dart';

/// Async development/benchmark façade that owns one persistent ISNet isolate.
///
/// The worker isolate owns model verification, the selected inference engine,
/// reusable tensors, image decoding, Lanczos preprocessing, inference,
/// postprocessing, and PNG encoding. Requests serialize through one engine.
final class IsnetWorker {
  IsnetWorker._(
    this._isolate,
    this._commandPort, {
    required this.engineKind,
    required this.activeAccelerators,
    required this.isFullyAccelerated,
    required this.openDuration,
    required this.rssBeforeOpenBytes,
    required this.rssAfterOpenBytes,
    required this.maxRssAfterOpenBytes,
  });

  final Isolate _isolate;
  final SendPort _commandPort;

  final IsnetEngineKind engineKind;
  final List<String> activeAccelerators;
  final bool? isFullyAccelerated;

  /// Wall-clock time from worker spawn through verified engine readiness.
  final Duration openDuration;

  /// Process-wide RSS sampled immediately before spawning/opening the worker.
  final int rssBeforeOpenBytes;

  /// Process-wide RSS sampled after the verified engine is ready.
  final int rssAfterOpenBytes;

  /// Highest process RSS sampled during this engine-open operation.
  final int maxRssAfterOpenBytes;

  bool _closed = false;

  static Future<IsnetWorker> open({
    required File modelFile,
    IsnetEngineKind engineKind = IsnetEngineKind.interpreter,
  }) async {
    final readyPort = ReceivePort();
    final stopwatch = Stopwatch()..start();
    final rssBeforeOpenBytes = ProcessInfo.currentRss;
    final rssSampler = _RssSampler(initialBytes: rssBeforeOpenBytes);

    late final Isolate isolate;
    try {
      isolate = await Isolate.spawn<List<Object?>>(_isnetWorkerMain, <Object?>[
        modelFile.path,
        engineKind.name,
        readyPort.sendPort,
      ], debugName: 'nijify-isnet-worker-${engineKind.name}');

      final message = await readyPort.first;
      stopwatch.stop();

      if (message is Map<Object?, Object?> && message['type'] == 'ready') {
        final commandPort = message['port'];
        final acceleratorNames = message['accelerators'];
        final fullyAccelerated = message['fullyAccelerated'];
        if (commandPort is SendPort && acceleratorNames is List<Object?>) {
          final names = acceleratorNames.whereType<String>().toList(
            growable: false,
          );
          if (names.length != acceleratorNames.length) {
            isolate.kill(priority: Isolate.immediate);
            throw StateError(
              'ISNet worker returned invalid accelerator metadata: '
              '$acceleratorNames',
            );
          }

          final rssAfterOpenBytes = ProcessInfo.currentRss;
          final sampledPeak = rssSampler.stop(extraSample: rssAfterOpenBytes);
          return IsnetWorker._(
            isolate,
            commandPort,
            engineKind: engineKind,
            activeAccelerators: List<String>.unmodifiable(names),
            isFullyAccelerated: fullyAccelerated is bool
                ? fullyAccelerated
                : null,
            openDuration: stopwatch.elapsed,
            rssBeforeOpenBytes: rssBeforeOpenBytes,
            rssAfterOpenBytes: rssAfterOpenBytes,
            maxRssAfterOpenBytes: sampledPeak,
          );
        }
      }

      isolate.kill(priority: Isolate.immediate);
      _throwWorkerFailure(message, fallback: IsnetFailureKind.modelOpenFailed);
    } finally {
      rssSampler.stop();
      readyPort.close();
    }
  }

  Future<IsnetRemovalResult> remove(Uint8List encodedBytes) async {
    _ensureOpen();

    final responsePort = ReceivePort();
    final rssSampler = _RssSampler(initialBytes: ProcessInfo.currentRss);
    try {
      _commandPort.send(<String, Object?>{
        'type': 'remove',
        'reply': responsePort.sendPort,
        'bytes': TransferableTypedData.fromList(<TypedData>[encodedBytes]),
      });

      final message = await responsePort.first;
      if (message is Map<Object?, Object?> && message['type'] == 'success') {
        final pngData = message['png'];
        final widthPx = message['widthPx'];
        final heightPx = message['heightPx'];
        final preprocessingMicros = message['preprocessingMicros'];
        final inferenceMicros = message['inferenceMicros'];
        final postprocessingMicros = message['postprocessingMicros'];
        final totalMicros = message['totalMicros'];
        final rssBeforeBytes = message['rssBeforeBytes'];
        final rssAfterBytes = message['rssAfterBytes'];

        if (pngData is TransferableTypedData &&
            widthPx is int &&
            heightPx is int &&
            preprocessingMicros is int &&
            inferenceMicros is int &&
            postprocessingMicros is int &&
            totalMicros is int &&
            rssBeforeBytes is int &&
            rssAfterBytes is int) {
          final sampledPeak = rssSampler.stop(
            extraSample: ProcessInfo.currentRss,
          );
          return IsnetRemovalResult(
            pngBytes: pngData.materialize().asUint8List(),
            widthPx: widthPx,
            heightPx: heightPx,
            metrics: IsnetRunMetrics(
              preprocessingDuration: Duration(
                microseconds: preprocessingMicros,
              ),
              inferenceDuration: Duration(microseconds: inferenceMicros),
              postprocessingDuration: Duration(
                microseconds: postprocessingMicros,
              ),
              totalDuration: Duration(microseconds: totalMicros),
              rssBeforeBytes: rssBeforeBytes,
              rssAfterBytes: rssAfterBytes,
              maxRssBytes: sampledPeak,
            ),
          );
        }
      }

      _throwWorkerFailure(message, fallback: IsnetFailureKind.inferenceFailed);
    } finally {
      rssSampler.stop();
      responsePort.close();
    }
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;

    final responsePort = ReceivePort();
    try {
      _commandPort.send(<String, Object?>{
        'type': 'close',
        'reply': responsePort.sendPort,
      });
      await responsePort.first;
    } finally {
      responsePort.close();
      _isolate.kill(priority: Isolate.immediate);
    }
  }

  void _ensureOpen() {
    if (_closed) {
      throw const IsnetException(
        IsnetFailureKind.closed,
        cause: 'ISNet worker is already closed.',
      );
    }
  }
}

final class _RssSampler {
  _RssSampler({required int initialBytes}) : _peakBytes = initialBytes {
    _timer = Timer.periodic(const Duration(milliseconds: 25), (_) => _sample());
  }

  late final Timer _timer;
  int _peakBytes;
  bool _stopped = false;

  void _sample() {
    final current = ProcessInfo.currentRss;
    if (current > _peakBytes) {
      _peakBytes = current;
    }
  }

  int stop({int? extraSample}) {
    if (extraSample != null && extraSample > _peakBytes) {
      _peakBytes = extraSample;
    }
    if (!_stopped) {
      _sample();
      _timer.cancel();
      _stopped = true;
    }
    return _peakBytes;
  }
}

void _isnetWorkerMain(List<Object?> bootstrap) async {
  final modelPath = bootstrap[0] as String;
  final engineKindName = bootstrap[1] as String;
  final readyPort = bootstrap[2] as SendPort;
  final commandPort = ReceivePort();

  final engineKind = _engineKindByName(engineKindName);
  if (engineKind == null) {
    readyPort.send(
      _serializeWorkerFailure(
        StateError('Unknown ISNet engine kind: $engineKindName'),
        StackTrace.current,
      ),
    );
    commandPort.close();
    return;
  }

  late final IsnetBackgroundRemover remover;
  try {
    remover = await IsnetBackgroundRemover.open(
      modelFile: File(modelPath),
      engineKind: engineKind,
    );
  } catch (error, stackTrace) {
    readyPort.send(_serializeWorkerFailure(error, stackTrace));
    commandPort.close();
    return;
  }

  readyPort.send(<String, Object?>{
    'type': 'ready',
    'port': commandPort.sendPort,
    'accelerators': remover.activeAccelerators,
    'fullyAccelerated': remover.isFullyAccelerated,
  });

  try {
    await for (final message in commandPort) {
      if (message is! Map<Object?, Object?>) {
        continue;
      }

      final type = message['type'];
      final replyPort = message['reply'];
      if (replyPort is! SendPort) {
        continue;
      }

      if (type == 'remove') {
        final transferredBytes = message['bytes'];
        if (transferredBytes is! TransferableTypedData) {
          replyPort.send(
            _serializeWorkerFailure(
              const IsnetException(
                IsnetFailureKind.invalidInput,
                cause: 'Worker received invalid image bytes.',
              ),
              StackTrace.current,
            ),
          );
          continue;
        }

        try {
          final result = remover.remove(
            transferredBytes.materialize().asUint8List(),
          );
          replyPort.send(<String, Object?>{
            'type': 'success',
            'png': TransferableTypedData.fromList(<TypedData>[result.pngBytes]),
            'widthPx': result.widthPx,
            'heightPx': result.heightPx,
            'preprocessingMicros':
                result.metrics.preprocessingDuration.inMicroseconds,
            'inferenceMicros': result.metrics.inferenceDuration.inMicroseconds,
            'postprocessingMicros':
                result.metrics.postprocessingDuration.inMicroseconds,
            'totalMicros': result.metrics.totalDuration.inMicroseconds,
            'rssBeforeBytes': result.metrics.rssBeforeBytes,
            'rssAfterBytes': result.metrics.rssAfterBytes,
          });
        } catch (error, stackTrace) {
          replyPort.send(_serializeWorkerFailure(error, stackTrace));
        }
        continue;
      }

      if (type == 'close') {
        remover.close();
        replyPort.send(const <String, Object?>{'type': 'closed'});
        commandPort.close();
        break;
      }
    }
  } finally {
    remover.close();
  }
}

Map<String, Object?> _serializeWorkerFailure(
  Object error,
  StackTrace stackTrace,
) {
  final kind = error is IsnetException
      ? error.kind
      : IsnetFailureKind.inferenceFailed;
  final cause = error is IsnetException
      ? error.cause?.toString() ?? error.toString()
      : error.toString();

  return <String, Object?>{
    'type': 'error',
    'kind': kind.name,
    'cause': cause,
    'stack': stackTrace.toString(),
  };
}

Never _throwWorkerFailure(
  Object? message, {
  required IsnetFailureKind fallback,
}) {
  if (message is Map<Object?, Object?>) {
    final cause = message['cause'];
    final stack = message['stack'];
    final kind = _failureKindByName(message['kind']) ?? fallback;

    throw IsnetException(kind, cause: stack == null ? cause : '$cause\n$stack');
  }

  throw IsnetException(
    fallback,
    cause: 'ISNet worker returned an invalid response: $message',
  );
}

IsnetFailureKind? _failureKindByName(Object? value) {
  if (value is! String) {
    return null;
  }

  for (final kind in IsnetFailureKind.values) {
    if (kind.name == value) {
      return kind;
    }
  }
  return null;
}

IsnetEngineKind? _engineKindByName(String value) {
  for (final kind in IsnetEngineKind.values) {
    if (kind.name == value) {
      return kind;
    }
  }
  return null;
}
