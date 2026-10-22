// Path: packages/canvas_background_removal_isnet/example/lib/main.dart

import 'dart:async';
import 'dart:io';

import 'package:canvas_background_removal_isnet/background_removal_isnet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const IsnetBenchmarkApp());
}

class IsnetBenchmarkApp extends StatelessWidget {
  const IsnetBenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ISNet Benchmark',
      theme: ThemeData(useMaterial3: true),
      home: const BenchmarkPage(),
    );
  }
}

class BenchmarkPage extends StatefulWidget {
  const BenchmarkPage({super.key});

  @override
  State<BenchmarkPage> createState() => _BenchmarkPageState();
}

final class _PickedLocalFile {
  const _PickedLocalFile({required this.path, required this.name});

  final String path;
  final String name;
}

final class _AlphaParity {
  const _AlphaParity({
    required this.meanAbsoluteDifference,
    required this.maxAbsoluteDifference,
    required this.fractionAboveOne,
    required this.fractionAboveFive,
  });

  final double meanAbsoluteDifference;
  final int maxAbsoluteDifference;
  final double fractionAboveOne;
  final double fractionAboveFive;
}

class _BenchmarkPageState extends State<BenchmarkPage> {
  static const _fileChannel = MethodChannel('com.nijify.isnetbenchmark/files');

  _PickedLocalFile? _selectedModel;
  _PickedLocalFile? _selectedImage;
  Uint8List? _inputBytes;
  Uint8List? _outputBytes;
  Uint8List? _classicReferencePng;
  _AlphaParity? _alphaParity;
  IsnetWorker? _worker;
  List<IsnetRemovalResult> _runs = const <IsnetRemovalResult>[];
  IsnetEngineKind _engineKind = IsnetEngineKind.interpreter;

  bool _busy = false;
  String _status = Platform.isAndroid
      ? 'Select the verified FP16 model and an input image.'
      : 'This harness is intended for Android.';

  @override
  void dispose() {
    final worker = _worker;
    if (worker != null) {
      unawaited(worker.close());
    }

    final selectedModel = _selectedModel;
    if (selectedModel != null) {
      unawaited(_deleteLocalFile(selectedModel));
    }

    final selectedImage = _selectedImage;
    if (selectedImage != null) {
      unawaited(_deleteLocalFile(selectedImage));
    }

    super.dispose();
  }

  Future<void> _selectModel() async {
    if (_busy) {
      return;
    }

    await _runBusy(() async {
      final picked = await _pickLocalFile('pickModel');
      if (picked == null) {
        if (mounted) {
          setState(() {
            _status = 'Model selection cancelled.';
          });
        }
        return;
      }

      await _replaceWorker(null);

      final previous = _selectedModel;
      if (previous != null) {
        await _deleteLocalFile(previous);
      }

      if (!mounted) {
        await _deleteLocalFile(picked);
        return;
      }

      setState(() {
        _selectedModel = picked;
        _runs = const <IsnetRemovalResult>[];
        _outputBytes = null;
        _classicReferencePng = null;
        _alphaParity = null;
        _status =
            'Model selected. Open the Interpreter reference engine first.';
      });
    });
  }

  Future<void> _selectImage() async {
    if (_busy) {
      return;
    }

    await _runBusy(() async {
      final picked = await _pickLocalFile('pickImage');
      if (picked == null) {
        if (mounted) {
          setState(() {
            _status = 'Image selection cancelled.';
          });
        }
        return;
      }

      late final Uint8List bytes;
      try {
        bytes = await File(picked.path).readAsBytes();
      } catch (_) {
        await _deleteLocalFile(picked);
        rethrow;
      }

      final previous = _selectedImage;
      if (previous != null) {
        await _deleteLocalFile(previous);
      }

      if (!mounted) {
        await _deleteLocalFile(picked);
        return;
      }

      setState(() {
        _selectedImage = picked;
        _inputBytes = bytes;
        _runs = const <IsnetRemovalResult>[];
        _outputBytes = null;
        _classicReferencePng = null;
        _alphaParity = null;
        _status = 'Image selected. Run the Interpreter reference first.';
      });
    });
  }

  Future<void> _changeEngine(IsnetEngineKind engineKind) async {
    if (_busy || engineKind == _engineKind) {
      return;
    }

    await _replaceWorker(null);
    if (!mounted) {
      return;
    }

    setState(() {
      _engineKind = engineKind;
      _runs = const <IsnetRemovalResult>[];
      _outputBytes = null;
      _alphaParity = null;
      _status = engineKind == IsnetEngineKind.interpreter
          ? 'Interpreter selected.'
          : _classicReferencePng == null
          ? 'CompiledModel selected. Run Interpreter first to capture a reference.'
          : 'CompiledModel selected. Open the engine and benchmark against the stored reference.';
    });
  }

  Future<void> _openModel() async {
    final selectedModel = _selectedModel;
    if (selectedModel == null || _busy) {
      return;
    }

    await _runBusy(() async {
      await _replaceWorker(null);

      final worker = await IsnetWorker.open(
        modelFile: File(selectedModel.path),
        engineKind: _engineKind,
      );
      await _replaceWorker(worker);

      if (!mounted) {
        return;
      }

      setState(() {
        _runs = const <IsnetRemovalResult>[];
        _outputBytes = null;
        _alphaParity = null;
        _status = '${_engineKind.label} opened successfully.';
      });
    });
  }

  Future<void> _runBenchmark() async {
    final worker = _worker;
    final inputBytes = _inputBytes;
    if (worker == null || inputBytes == null || _busy) {
      return;
    }

    if (_engineKind != IsnetEngineKind.interpreter &&
        _classicReferencePng == null) {
      setState(() {
        _status =
            'Run the Interpreter benchmark on this image before CompiledModel.';
      });
      return;
    }

    await _runBusy(() async {
      final runs = <IsnetRemovalResult>[];

      // Run 0 is cold for this freshly opened engine. Runs 1-5 are warm.
      for (var index = 0; index < 6; index++) {
        runs.add(await worker.remove(inputBytes));
      }

      final output = runs.last.pngBytes;
      final reference = _classicReferencePng;
      final parity =
          _engineKind == IsnetEngineKind.interpreter || reference == null
          ? null
          : _compareAlpha(reference, output);

      if (!mounted) {
        return;
      }

      setState(() {
        _runs = List<IsnetRemovalResult>.unmodifiable(runs);
        _outputBytes = output;
        _alphaParity = parity;

        if (_engineKind == IsnetEngineKind.interpreter) {
          _classicReferencePng = Uint8List.fromList(output);
          _status =
              'Interpreter benchmark complete; correctness reference captured.';
        } else {
          _status =
              '${_engineKind.label} benchmark complete; compare parity and performance.';
        }
      });
    });
  }

  Future<_PickedLocalFile?> _pickLocalFile(String method) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('The ISNet benchmark picker is Android-only.');
    }

    final response = await _fileChannel.invokeMethod<Object?>(method);
    if (response == null) {
      return null;
    }

    if (response is! Map<Object?, Object?>) {
      throw StateError(
        'Android picker returned an invalid response: $response',
      );
    }

    final path = response['path'];
    final name = response['name'];
    if (path is! String || name is! String) {
      throw StateError(
        'Android picker returned invalid file metadata: $response',
      );
    }

    return _PickedLocalFile(path: path, name: name);
  }

  Future<void> _runBusy(Future<void> Function() operation) async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Working…';
    });

    try {
      await operation();
    } catch (error) {
      if (mounted) {
        setState(() {
          _status = 'Failed: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _replaceWorker(IsnetWorker? replacement) async {
    final previous = _worker;
    _worker = replacement;
    if (previous != null && !identical(previous, replacement)) {
      await previous.close();
    }
  }

  Future<void> _deleteLocalFile(_PickedLocalFile file) async {
    final localFile = File(file.path);
    if (await localFile.exists()) {
      await localFile.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final worker = _worker;
    final cold = _runs.isEmpty ? null : _runs.first;
    final warm = _runs.length <= 1
        ? const <IsnetRemovalResult>[]
        : _runs.sublist(1);
    final requiresReference = _engineKind != IsnetEngineKind.interpreter;
    final canRun =
        !_busy &&
        worker != null &&
        _inputBytes != null &&
        (!requiresReference || _classicReferencePng != null);

    return Scaffold(
      appBar: AppBar(title: const Text('ISNet Android benchmark')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(_status),
          const SizedBox(height: 16),
          _SelectionRow(
            label: 'Model',
            value: _selectedModel?.name ?? 'Not selected',
            buttonLabel: 'Select model',
            onPressed: _busy ? null : _selectModel,
          ),
          const SizedBox(height: 8),
          _SelectionRow(
            label: 'Image',
            value: _selectedImage?.name ?? 'Not selected',
            buttonLabel: 'Select image',
            onPressed: _busy ? null : _selectImage,
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              const SizedBox(width: 72, child: Text('Engine:')),
              Expanded(
                child: DropdownButton<IsnetEngineKind>(
                  value: _engineKind,
                  isExpanded: true,
                  items: <DropdownMenuItem<IsnetEngineKind>>[
                    for (final kind in IsnetEngineKind.values)
                      DropdownMenuItem<IsnetEngineKind>(
                        value: kind,
                        child: Text(kind.label),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) {
                          if (value != null) {
                            unawaited(_changeEngine(value));
                          }
                        },
                ),
              ),
            ],
          ),
          if (requiresReference && _classicReferencePng == null)
            const Text(
              'Correctness gate: run Interpreter on this image first.',
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              FilledButton(
                onPressed: _busy || _selectedModel == null ? null : _openModel,
                child: const Text('Open selected engine'),
              ),
              FilledButton.tonal(
                onPressed: canRun ? _runBenchmark : null,
                child: const Text('Run 1 cold + 5 warm'),
              ),
            ],
          ),
          if (_busy) ...<Widget>[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (worker != null) ...<Widget>[
            const SizedBox(height: 24),
            Text(
              'Open metrics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('Engine: ${worker.engineKind.label}'),
            Text('Accelerators: ${worker.activeAccelerators.join(', ')}'),
            if (worker.isFullyAccelerated != null)
              Text('Fully accelerated: ${worker.isFullyAccelerated}'),
            Text('Open: ${_ms(worker.openDuration)} ms'),
            Text(
              'RSS: ${_mib(worker.rssBeforeOpenBytes)} → '
              '${_mib(worker.rssAfterOpenBytes)} MiB',
            ),
            Text(
              'Peak RSS after open: ${_mib(worker.maxRssAfterOpenBytes)} MiB',
            ),
          ],
          if (cold != null) ...<Widget>[
            const SizedBox(height: 24),
            Text('Cold run', style: Theme.of(context).textTheme.titleMedium),
            _MetricsView(metrics: cold.metrics),
          ],
          if (warm.isNotEmpty) ...<Widget>[
            const SizedBox(height: 24),
            Text('Warm runs', style: Theme.of(context).textTheme.titleMedium),
            Text('Count: ${warm.length}'),
            Text(
              'Median total: '
              '${_medianMs(warm, (run) => run.metrics.totalDuration)} ms',
            ),
            Text(
              'P95 total: '
              '${_percentileMs(warm, (run) => run.metrics.totalDuration, 0.95)} ms',
            ),
            Text(
              'Median inference: '
              '${_medianMs(warm, (run) => run.metrics.inferenceDuration)} ms',
            ),
            Text(
              'Peak RSS: '
              '${_mib(warm.map((run) => run.metrics.maxRssBytes).reduce(_max))} MiB',
            ),
          ],
          if (_alphaParity case final parity?) ...<Widget>[
            const SizedBox(height: 24),
            Text(
              'Correctness vs Interpreter',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Mean |alpha diff|: '
              '${parity.meanAbsoluteDifference.toStringAsFixed(3)} / 255',
            ),
            Text('Max |alpha diff|: ${parity.maxAbsoluteDifference} / 255'),
            Text('Pixels diff > 1: ${_percent(parity.fractionAboveOne)}'),
            Text('Pixels diff > 5: ${_percent(parity.fractionAboveFive)}'),
          ],
          if (_inputBytes != null || _outputBytes != null) ...<Widget>[
            const SizedBox(height: 24),
            Text(
              'Visual check',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (_inputBytes != null)
                  Expanded(
                    child: _Preview(label: 'Input', bytes: _inputBytes!),
                  ),
                if (_inputBytes != null && _outputBytes != null)
                  const SizedBox(width: 12),
                if (_outputBytes != null)
                  Expanded(
                    child: _Preview(label: 'Output', bytes: _outputBytes!),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectionRow extends StatelessWidget {
  const _SelectionRow({
    required this.label,
    required this.value,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String label;
  final String value;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text('$label: $value')),
        const SizedBox(width: 12),
        OutlinedButton(onPressed: onPressed, child: Text(buttonLabel)),
      ],
    );
  }
}

class _MetricsView extends StatelessWidget {
  const _MetricsView({required this.metrics});

  final IsnetRunMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Preprocess: ${_ms(metrics.preprocessingDuration)} ms'),
        Text('Inference: ${_ms(metrics.inferenceDuration)} ms'),
        Text('Postprocess: ${_ms(metrics.postprocessingDuration)} ms'),
        Text('Total: ${_ms(metrics.totalDuration)} ms'),
        Text(
          'RSS: ${_mib(metrics.rssBeforeBytes)} → '
          '${_mib(metrics.rssAfterBytes)} MiB',
        ),
        Text('Peak RSS: ${_mib(metrics.maxRssBytes)} MiB'),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.label, required this.bytes});

  final String label;
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(label),
        const SizedBox(height: 4),
        AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }
}

_AlphaParity _compareAlpha(Uint8List referencePng, Uint8List candidatePng) {
  final reference = img.decodePng(referencePng);
  final candidate = img.decodePng(candidatePng);
  if (reference == null || candidate == null) {
    throw StateError('Could not decode benchmark PNG output for parity check.');
  }

  if (reference.width != candidate.width ||
      reference.height != candidate.height) {
    throw StateError(
      'Output dimensions differ: Interpreter '
      '${reference.width}x${reference.height}, CompiledModel '
      '${candidate.width}x${candidate.height}.',
    );
  }

  var sumAbsoluteDifference = 0;
  var maxAbsoluteDifference = 0;
  var aboveOne = 0;
  var aboveFive = 0;
  final pixelCount = reference.width * reference.height;

  for (var y = 0; y < reference.height; y++) {
    for (var x = 0; x < reference.width; x++) {
      final left = reference.getPixel(x, y).a.toInt();
      final right = candidate.getPixel(x, y).a.toInt();
      final difference = (left - right).abs();
      sumAbsoluteDifference += difference;
      if (difference > maxAbsoluteDifference) {
        maxAbsoluteDifference = difference;
      }
      if (difference > 1) {
        aboveOne++;
      }
      if (difference > 5) {
        aboveFive++;
      }
    }
  }

  return _AlphaParity(
    meanAbsoluteDifference: sumAbsoluteDifference / pixelCount,
    maxAbsoluteDifference: maxAbsoluteDifference,
    fractionAboveOne: aboveOne / pixelCount,
    fractionAboveFive: aboveFive / pixelCount,
  );
}

String _ms(Duration value) => (value.inMicroseconds / 1000).toStringAsFixed(1);

String _mib(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

String _percent(double fraction) => '${(fraction * 100).toStringAsFixed(3)}%';

int _max(int left, int right) => left > right ? left : right;

String _medianMs(
  List<IsnetRemovalResult> runs,
  Duration Function(IsnetRemovalResult run) selector,
) {
  final values =
      runs.map((run) => selector(run).inMicroseconds).toList(growable: false)
        ..sort();
  final middle = values.length ~/ 2;
  final micros = values.length.isOdd
      ? values[middle].toDouble()
      : (values[middle - 1] + values[middle]) / 2;
  return (micros / 1000).toStringAsFixed(1);
}

String _percentileMs(
  List<IsnetRemovalResult> runs,
  Duration Function(IsnetRemovalResult run) selector,
  double percentile,
) {
  final values =
      runs.map((run) => selector(run).inMicroseconds).toList(growable: false)
        ..sort();
  final index = ((values.length - 1) * percentile).ceil();
  return (values[index] / 1000).toStringAsFixed(1);
}
