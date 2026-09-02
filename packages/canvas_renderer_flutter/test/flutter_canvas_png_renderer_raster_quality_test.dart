import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

final class _NoopFontLoader implements FlutterFontLoader {
  const _NoopFontLoader();

  @override
  Iterable<String> get fallbackFontFamilies => const <String>[];

  @override
  Future<bool> ensureLoaded(Iterable<String> families) async => false;
}

final class _MapImageResolver implements CanvasImageAssetResolver {
  const _MapImageResolver({required this.sources});

  final Map<String, String> sources;

  @override
  Future<Map<String, String>> resolveSources(List<String> sourceRefs) async {
    return <String, String>{
      for (final sourceRef in sourceRefs)
        if (sources.containsKey(sourceRef)) sourceRef: sources[sourceRef]!,
    };
  }

  @override
  Future<Map<String, Size2D>> resolveIntrinsicSizes(
    List<String> sourceRefs,
  ) async {
    return const <String, Size2D>{};
  }
}

Future<ui.Image> _decodePng(Uint8List bytes) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromList(bytes, completer.complete);
  return completer.future;
}

Future<int> _pixelAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

  if (data == null) {
    throw StateError('Pixel read failed.');
  }

  final offset = (y * image.width + x) * 4;
  final r = data.getUint8(offset);
  final g = data.getUint8(offset + 1);
  final b = data.getUint8(offset + 2);
  final a = data.getUint8(offset + 3);

  return (a << 24) | (r << 16) | (g << 8) | b;
}

Future<String> _createStripedPngDataUri() async {
  const colors = <int>[
    0xFFFF0000,
    0xFF00FF00,
    0xFF0000FF,
    0xFFFFFF00,
    0xFFFF00FF,
    0xFF00FFFF,
    0xFF000000,
    0xFFFFFFFF,
  ];

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  for (var x = 0; x < colors.length; x++) {
    canvas.drawRect(
      ui.Rect.fromLTWH(x.toDouble(), 0, 1, 2),
      ui.Paint()..color = ui.Color(colors[x]),
    );
  }

  final picture = recorder.endRecording();

  final ui.Image image;

  try {
    image = await picture.toImage(8, 2);
  } finally {
    picture.dispose();
  }

  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);

    if (data == null) {
      throw StateError('Unable to encode striped PNG fixture.');
    }

    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    return 'data:image/png;base64,${base64Encode(bytes)}';
  } finally {
    image.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('final PNG preserves native raster detail at high density', () async {
    const sourceRef = 'media:striped';

    const expectedColors = <int>[
      0xFFFF0000,
      0xFF00FF00,
      0xFF0000FF,
      0xFFFFFF00,
      0xFFFF00FF,
      0xFF00FFFF,
      0xFF000000,
      0xFFFFFFFF,
    ];

    final dataUri = await _createStripedPngDataUri();

    final scene = CanvasSceneDocument(
      artboardSize: const Size2D(8, 2),
      backgroundFill: const CanvasFill.none(),
      backgroundOpacity: 1,
      assets: const <CanvasAssetId, CanvasImageAsset>{
        'asset-1': CanvasImageAsset(
          sourceRef: sourceRef,
          intrinsicSize: Size2D(8, 2),
        ),
      },
      children: const <Node>[
        Node.image(
          id: 'image-1',
          xf: Transform2D(position: Vec2(4, 1)),
          data: ImageData(
            assetId: 'asset-1',
            size: Size2D(8, 2),
            fit: ImageFit.fill,
          ),
        ),
      ],
    );

    final renderer = FlutterCanvasPngRenderer(
      fonts: const _NoopFontLoader(),
      images: _MapImageResolver(
        sources: <String, String>{sourceRef: dataUri},
      ),
    );

    final bytes = await renderer.renderPng(
      scene: scene,
      spec: const CanvasPngSpec(
        widthPx: 4,
        heightPx: 1,
        pixelRatio: 2,
        transparent: true,
        fit: CanvasFit.contain,
      ),
    );

    final output = await _decodePng(bytes);

    try {
      expect(output.width, 8);
      expect(output.height, 2);

      for (var x = 0; x < expectedColors.length; x++) {
        expect(
          await _pixelAt(output, x, 0),
          expectedColors[x],
          reason:
              'Final PNG must not downsample the source raster before '
              'high-density painting.',
        );
      }
    } finally {
      output.dispose();
    }
  });
}
