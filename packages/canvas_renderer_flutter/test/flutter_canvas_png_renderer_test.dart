import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

final class _RecordingFontLoader implements FlutterFontLoader {
  _RecordingFontLoader({
    Iterable<String> fallbackFontFamilies = const <String>[],
    this.onEnsure,
  }) : fallbackFontFamilies = List<String>.unmodifiable(fallbackFontFamilies);

  @override
  final Iterable<String> fallbackFontFamilies;

  final FutureOr<bool> Function(Set<String> families)? onEnsure;

  final List<Set<String>> requests = <Set<String>>[];

  @override
  Future<bool> ensureLoaded(Iterable<String> families) async {
    final request = <String>{};

    for (final raw in families) {
      final family = raw.trim();

      if (family.isNotEmpty) {
        request.add(family);
      }
    }

    requests.add(Set<String>.unmodifiable(request));

    final callback = onEnsure;

    if (callback == null) {
      return false;
    }

    return await callback(request);
  }
}

final class _RecordingImageResolver implements CanvasImageAssetResolver {
  _RecordingImageResolver({
    this.sources = const <String, String>{},
    this.intrinsics = const <String, Size2D>{},
  });

  final Map<String, String> sources;
  final Map<String, Size2D> intrinsics;

  final List<List<String>> sourceRequests = <List<String>>[];

  final List<List<String>> intrinsicRequests = <List<String>>[];

  @override
  Future<Map<String, String>> resolveSources(List<String> sourceRefs) async {
    sourceRequests.add(List<String>.unmodifiable(sourceRefs));

    return <String, String>{
      for (final sourceRef in sourceRefs)
        if (sources.containsKey(sourceRef)) sourceRef: sources[sourceRef]!,
    };
  }

  @override
  Future<Map<String, Size2D>> resolveIntrinsicSizes(
    List<String> sourceRefs,
  ) async {
    intrinsicRequests.add(List<String>.unmodifiable(sourceRefs));

    return <String, Size2D>{
      for (final sourceRef in sourceRefs)
        if (intrinsics.containsKey(sourceRef))
          sourceRef: intrinsics[sourceRef]!,
    };
  }
}

final class _MapIconResolver implements IconResolver {
  const _MapIconResolver(this.icons);

  final Map<String, ResolvedIcon> icons;

  @override
  ResolvedIcon? resolve(String iconRef) {
    return icons[iconRef];
  }
}

CanvasSceneDocument _emptyScene({Size2D size = const Size2D(64, 64)}) {
  return CanvasSceneDocument(
    artboardSize: size,
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1,
  );
}

CanvasSceneDocument _backgroundScene({
  required Size2D size,
  required int color,
}) {
  return CanvasSceneDocument(
    artboardSize: size,
    backgroundFill: CanvasFill.solid(color),
    backgroundOpacity: 1,
  );
}

CanvasSceneDocument _textScene(String family) {
  return CanvasSceneDocument(
    artboardSize: const Size2D(100, 60),
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1,
    children: <Node>[
      Node.text(
        id: 'text-1',
        data: TextData(
          text: 'Hello',
          fontFamily: family,
          fontWeight: 400,
          fontSize: 20,
        ),
      ),
    ],
  );
}

CanvasSceneDocument _imageScene({
  String elementId = 'image-1',
  String assetId = 'asset-1',
  String sourceRef = 'media:image',
  Size2D? intrinsicSize,
  bool hidden = false,
}) {
  final image = Node.image(
    id: elementId,
    data: ImageData(assetId: assetId, size: const Size2D(32, 32)),
  );

  return CanvasSceneDocument(
    artboardSize: const Size2D(64, 64),
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1,
    assets: <CanvasAssetId, CanvasImageAsset>{
      assetId: CanvasImageAsset(
        sourceRef: sourceRef,
        intrinsicSize: intrinsicSize,
      ),
    },
    children: <Node>[
      if (hidden)
        Node.group(id: 'hidden-group', hidden: true, children: <Node>[image])
      else
        image,
    ],
  );
}

Matcher _stateErrorContaining(String text) {
  return isA<StateError>().having(
    (error) => error.toString(),
    'message',
    contains(text),
  );
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

Future<String> _createPngDataUri({int color = 0xFF336699}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 4, 4),
    ui.Paint()..color = ui.Color(color),
  );

  final picture = recorder.endRecording();

  final ui.Image image;

  try {
    image = await picture.toImage(4, 4);
  } finally {
    picture.dispose();
  }

  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);

    if (data == null) {
      throw StateError('Unable to encode PNG fixture.');
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

  group('FlutterCanvasPngRenderer output', () {
    test('applies pixel ratio, bleed, and opaque backing', () async {
      final renderer = FlutterCanvasPngRenderer(fonts: _RecordingFontLoader());

      final bytes = await renderer.renderPng(
        scene: _backgroundScene(size: const Size2D(40, 20), color: 0xFF00FF00),
        spec: const CanvasPngSpec(
          widthPx: 100,
          heightPx: 50,
          bleedPx: 8,
          pixelRatio: 2.5,
          transparent: false,
          fit: CanvasFit.contain,
        ),
      );

      final image = await _decodePng(bytes);

      try {
        expect(image.width, ((100 + 16) * 2.5).round());

        expect(image.height, ((50 + 16) * 2.5).round());

        expect(await _pixelAt(image, 1, 1), 0xFFFFFFFF);
      } finally {
        image.dispose();
      }
    });

    test('contain fit centers artboard inside target', () async {
      final renderer = FlutterCanvasPngRenderer(fonts: _RecordingFontLoader());

      final bytes = await renderer.renderPng(
        scene: _backgroundScene(size: const Size2D(100, 50), color: 0xFFFF0000),
        spec: const CanvasPngSpec(
          widthPx: 200,
          heightPx: 200,
          pixelRatio: 1,
          transparent: false,
          fit: CanvasFit.contain,
        ),
      );

      final image = await _decodePng(bytes);

      try {
        expect(image.width, 200);
        expect(image.height, 200);

        expect(await _pixelAt(image, 10, 10), 0xFFFFFFFF);

        expect(await _pixelAt(image, 10, 60), 0xFFFF0000);

        expect(await _pixelAt(image, 10, 180), 0xFFFFFFFF);
      } finally {
        image.dispose();
      }
    });

    test('transparent output leaves transparent backing', () async {
      final renderer = FlutterCanvasPngRenderer(fonts: _RecordingFontLoader());

      final bytes = await renderer.renderPng(
        scene: _emptyScene(),
        spec: const CanvasPngSpec(
          widthPx: 32,
          heightPx: 32,
          pixelRatio: 1,
          transparent: true,
        ),
      );

      final image = await _decodePng(bytes);

      try {
        final pixel = await _pixelAt(image, 1, 1);

        expect((pixel >> 24) & 0xFF, 0);
      } finally {
        image.dispose();
      }
    });
  });

  group('FlutterCanvasPngRenderer preparation', () {
    test('invokes ScenePreparer exactly once', () async {
      var preparationCalls = 0;

      final renderer = FlutterCanvasPngRenderer(
        fonts: _RecordingFontLoader(),
        scenePreparer: (scene, services) {
          preparationCalls++;
          return scene;
        },
      );

      await renderer.renderPng(
        scene: _backgroundScene(size: const Size2D(32, 32), color: 0xFF123456),
        spec: const CanvasPngSpec(widthPx: 32, heightPx: 32, pixelRatio: 1),
      );

      expect(preparationCalls, 1);
    });

    test('propagates ScenePreparer exceptions', () async {
      final renderer = FlutterCanvasPngRenderer(
        fonts: _RecordingFontLoader(),
        scenePreparer: (_, _) {
          throw StateError('preparation exploded');
        },
      );

      await expectLater(
        renderer.renderPng(
          scene: _emptyScene(),
          spec: const CanvasPngSpec(widthPx: 32, heightPx: 32),
        ),
        throwsA(_stateErrorContaining('preparation exploded')),
      );
    });

    test('canonical fonts are ensured before preparation', () async {
      var fontsEnsured = false;

      final loader = _RecordingFontLoader(
        onEnsure: (families) {
          expect(families, contains('CanonicalFont'));

          fontsEnsured = true;
          return true;
        },
      );

      final renderer = FlutterCanvasPngRenderer(
        fonts: loader,
        scenePreparer: (scene, services) {
          expect(fontsEnsured, isTrue);

          // Remove the text from final paint so this test is only about
          // ordering rather than platform font registration.
          return scene.copyWith(children: const <Node>[]);
        },
      );

      await renderer.renderPng(
        scene: _textScene('CanonicalFont'),
        spec: const CanvasPngSpec(widthPx: 100, heightPx: 60, pixelRatio: 1),
      );

      expect(loader.requests, hasLength(1));
    });
  });

  group('FlutterCanvasPngRenderer validation', () {
    test('rejects invalid canonical scene', () async {
      final renderer = FlutterCanvasPngRenderer(fonts: _RecordingFontLoader());

      final invalid = CanvasSceneDocument(
        artboardSize: const Size2D(0, 40),
        backgroundFill: const CanvasFill.none(),
        backgroundOpacity: 1,
      );

      await expectLater(
        renderer.renderPng(
          scene: invalid,
          spec: const CanvasPngSpec(widthPx: 40, heightPx: 40),
        ),
        throwsA(_stateErrorContaining('Invalid canonical canvas scene')),
      );
    });

    test('rejects invalid prepared scene', () async {
      final renderer = FlutterCanvasPngRenderer(
        fonts: _RecordingFontLoader(),
        scenePreparer: (scene, services) {
          return scene.copyWith(artboardSize: const Size2D(0, 40));
        },
      );

      await expectLater(
        renderer.renderPng(
          scene: _emptyScene(),
          spec: const CanvasPngSpec(widthPx: 40, heightPx: 40),
        ),
        throwsA(_stateErrorContaining('Invalid prepared canvas scene')),
      );
    });

    test('propagates unknown font failure', () async {
      final loader = _RecordingFontLoader(
        onEnsure: (_) {
          throw StateError('unknown font');
        },
      );

      final renderer = FlutterCanvasPngRenderer(fonts: loader);

      await expectLater(
        renderer.renderPng(
          scene: _textScene('MissingFont'),
          spec: const CanvasPngSpec(widthPx: 100, heightPx: 60),
        ),
        throwsA(_stateErrorContaining('unknown font')),
      );
    });

    test('rejects unresolved canonical icon', () async {
      final renderer = FlutterCanvasPngRenderer(
        fonts: _RecordingFontLoader(),
        icons: const _MapIconResolver(<String, ResolvedIcon>{}),
      );

      final scene = _emptyScene().copyWith(
        children: <Node>[
          const Node.icon(
            id: 'icon-1',
            data: CanvasIconData(iconRef: 'missing-icon'),
          ),
        ],
      );

      await expectLater(
        renderer.renderPng(
          scene: scene,
          spec: const CanvasPngSpec(widthPx: 64, heightPx: 64),
        ),
        throwsA(
          _stateErrorContaining('unresolved icon reference "missing-icon"'),
        ),
      );
    });
  });

  group('FlutterCanvasPngRenderer resource preservation', () {
    test('rejects new prepared font family', () async {
      final renderer = FlutterCanvasPngRenderer(
        fonts: _RecordingFontLoader(),
        scenePreparer: (scene, services) {
          return _textScene('PreparedFont');
        },
      );

      await expectLater(
        renderer.renderPng(
          scene: _textScene('CanonicalFont'),
          spec: const CanvasPngSpec(widthPx: 100, heightPx: 60),
        ),
        throwsA(_stateErrorContaining('unapproved font family')),
      );
    });

    test('rejects new prepared icon reference', () async {
      const iconFont = 'IconFont';

      const icons = _MapIconResolver(<String, ResolvedIcon>{
        'new-icon': ResolvedIconText(glyph: '*', fontFamily: iconFont),
      });

      final renderer = FlutterCanvasPngRenderer(
        fonts: _RecordingFontLoader(
          fallbackFontFamilies: const <String>[iconFont],
        ),
        icons: icons,
        scenePreparer: (scene, services) {
          return scene.copyWith(
            children: <Node>[
              const Node.icon(
                id: 'prepared-icon',
                data: CanvasIconData(iconRef: 'new-icon'),
              ),
            ],
          );
        },
      );

      await expectLater(
        renderer.renderPng(
          scene: _emptyScene(),
          spec: const CanvasPngSpec(widthPx: 64, heightPx: 64),
        ),
        throwsA(_stateErrorContaining('unapproved icon reference')),
      );
    });

    test('rejects new prepared image source before resolving it', () async {
      final images = _RecordingImageResolver();

      final renderer = FlutterCanvasPngRenderer(
        fonts: _RecordingFontLoader(),
        images: images,
        scenePreparer: (scene, services) {
          return _imageScene(sourceRef: 'media:unapproved');
        },
      );

      await expectLater(
        renderer.renderPng(
          scene: _emptyScene(),
          spec: const CanvasPngSpec(widthPx: 64, heightPx: 64),
        ),
        throwsA(_stateErrorContaining('unapproved image source reference')),
      );

      expect(
        images.intrinsicRequests,
        isEmpty,
        reason:
            'Prepared unapproved sources must be rejected before metadata '
            'resolution.',
      );

      expect(
        images.sourceRequests,
        isEmpty,
        reason:
            'Prepared unapproved sources must be rejected before raster '
            'source resolution.',
      );
    });

    test(
      'allows new element and asset ids reusing approved sourceRef',
      () async {
        final dataUri = await _createPngDataUri();

        final images = _RecordingImageResolver(
          sources: <String, String>{'media:logo': dataUri},
          intrinsics: const <String, Size2D>{'media:logo': Size2D(4, 4)},
        );

        final renderer = FlutterCanvasPngRenderer(
          fonts: _RecordingFontLoader(),
          images: images,
          scenePreparer: (scene, services) {
            return _imageScene(
              elementId: 'prepared-image',
              assetId: 'prepared-asset',
              sourceRef: 'media:logo',
            );
          },
        );

        final bytes = await renderer.renderPng(
          scene: _imageScene(
            elementId: 'canonical-image',
            assetId: 'canonical-asset',
            sourceRef: 'media:logo',
          ),
          spec: const CanvasPngSpec(widthPx: 64, heightPx: 64, pixelRatio: 1),
        );

        expect(bytes, isNotEmpty);

        expect(
          images.intrinsicRequests,
          hasLength(1),
          reason:
              'Stable metadata should be cached by logical sourceRef, while '
              'the second prepared intrinsic pass binds it to the new '
              'ElementId.',
        );

        expect(images.sourceRequests, hasLength(1));
      },
    );

    test('allows preparer to remove canonical dependency', () async {
      final renderer = FlutterCanvasPngRenderer(
        fonts: _RecordingFontLoader(),
        scenePreparer: (scene, services) {
          return scene.copyWith(
            assets: const <CanvasAssetId, CanvasImageAsset>{},
            children: const <Node>[],
          );
        },
      );

      final bytes = await renderer.renderPng(
        scene: _imageScene(
          sourceRef: 'media:removed',
          intrinsicSize: const Size2D(4, 4),
        ),
        spec: const CanvasPngSpec(widthPx: 64, heightPx: 64, pixelRatio: 1),
      );

      expect(bytes, isNotEmpty);
    });

    test('allows preparer to generate path geometry', () async {
      final renderer = FlutterCanvasPngRenderer(
        fonts: _RecordingFontLoader(),
        scenePreparer: (scene, services) {
          return scene.copyWith(
            children: <Node>[
              const Node.path(
                id: 'generated-shape',
                xf: Transform2D(position: Vec2(20, 20)),
                data: PathData(
                  source: RectSource(20, 20),
                  fill: CanvasFill.solid(0xFF336699),
                ),
              ),
            ],
          );
        },
      );

      final bytes = await renderer.renderPng(
        scene: _emptyScene(),
        spec: const CanvasPngSpec(widthPx: 64, heightPx: 64, pixelRatio: 1),
      );

      expect(bytes, isNotEmpty);
    });
  });

  group('FlutterCanvasPngRenderer images', () {
    test('fails when a required visible raster cannot resolve', () async {
      final images = _RecordingImageResolver();

      final renderer = FlutterCanvasPngRenderer(
        fonts: _RecordingFontLoader(),
        images: images,
      );

      await expectLater(
        renderer.renderPng(
          scene: _imageScene(
            sourceRef: 'media:missing',
            intrinsicSize: const Size2D(4, 4),
          ),
          spec: const CanvasPngSpec(widthPx: 64, heightPx: 64),
        ),
        throwsA(_stateErrorContaining('could not decode required image nodes')),
      );
    });

    test(
      'does not require raster decoding for hidden prepared image',
      () async {
        final images = _RecordingImageResolver();

        final renderer = FlutterCanvasPngRenderer(
          fonts: _RecordingFontLoader(),
          images: images,
        );

        final bytes = await renderer.renderPng(
          scene: _imageScene(
            sourceRef: 'media:hidden',
            intrinsicSize: const Size2D(4, 4),
            hidden: true,
          ),
          spec: const CanvasPngSpec(widthPx: 64, heightPx: 64, pixelRatio: 1),
        );

        expect(bytes, isNotEmpty);

        expect(
          images.sourceRequests,
          isEmpty,
          reason:
              'Hidden final images require logical/intrinsic validation but '
              'not decoded rasters.',
        );
      },
    );

    test('preserves exact HTTPS logical sourceRef through resolver', () async {
      const sourceRef =
          'https://images.unsplash.com/photo-123'
          '?ixid=test-value&auto=format&fit=crop&w=1200&q=80';

      final dataUri = await _createPngDataUri();

      final images = _RecordingImageResolver(
        sources: <String, String>{sourceRef: dataUri},
        intrinsics: const <String, Size2D>{sourceRef: Size2D(4, 4)},
      );

      final renderer = FlutterCanvasPngRenderer(
        fonts: _RecordingFontLoader(),
        images: images,
      );

      final bytes = await renderer.renderPng(
        scene: _imageScene(sourceRef: sourceRef),
        spec: const CanvasPngSpec(widthPx: 64, heightPx: 64, pixelRatio: 1),
      );

      expect(bytes, isNotEmpty);

      expect(images.intrinsicRequests.single, <String>[sourceRef]);

      expect(images.sourceRequests.single, <String>[sourceRef]);
    });
  });
}
