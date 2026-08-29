// Path: packages/canvas_editor_flutter/test/editor_asset_coordinator_test.dart

import 'dart:async';
import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/canvas_runtime_resources.dart';
import 'package:canvas_editor_flutter/src/runtime/editor_asset_coordinator.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeFonts implements CanvasFontAssets {
  final List<Set<String>> loadedRequests = <Set<String>>[];

  @override
  List<FontDef> get pickerFonts => const <FontDef>[];

  @override
  List<FontDef> get loadableFonts => const <FontDef>[];

  @override
  Iterable<String> get fallbackFontFamilies => const <String>[];

  @override
  Future<void> ensureLoaded(Iterable<String> families) async {
    loadedRequests.add(families.toSet());
  }
}

final class _FakeIcons implements IconCatalogPort {
  @override
  List<IconCatalogItem> get items => const <IconCatalogItem>[];

  @override
  Map<String, ResolvedIcon> get resolveMap => const <String, ResolvedIcon>{};

  @override
  ResolvedIcon? resolve(String iconRef) => null;
}

final class _FakeMedia implements CanvasMediaResolver {
  _FakeMedia({required this.urls, required this.intrinsicSizes});

  final Map<String, String> urls;
  final Map<String, Size2D> intrinsicSizes;

  final List<String> requestedUrls = <String>[];
  final List<String> requestedIntrinsicSizes = <String>[];

  @override
  Future<String?> resolveUrl(String ref) async {
    requestedUrls.add(ref);
    return urls[ref];
  }

  @override
  Future<Map<String, String>> resolveUrls(List<String> refs) async {
    requestedUrls.addAll(refs);

    final result = <String, String>{};

    for (final ref in refs) {
      final value = urls[ref];

      if (value != null) {
        result[ref] = value;
      }
    }

    return result;
  }

  @override
  Future<Size2D?> resolveIntrinsicSize(String ref) async {
    requestedIntrinsicSizes.add(ref);
    return intrinsicSizes[ref];
  }

  @override
  Future<Map<String, Size2D>> resolveIntrinsicSizes(List<String> refs) async {
    requestedIntrinsicSizes.addAll(refs);

    final result = <String, Size2D>{};

    for (final ref in refs) {
      final value = intrinsicSizes[ref];

      if (value != null) {
        result[ref] = value;
      }
    }

    return result;
  }
}

CanvasSceneDocument _imageScene(String sourceRef) {
  return CanvasSceneDocument(
    artboardSize: const Size2D(300, 200),
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1.0,
    assets: <CanvasAssetId, CanvasImageAsset>{
      'asset-0': CanvasImageAsset(sourceRef: sourceRef),
    },
    children: const [
      Node.image(
        id: 'image-0',
        data: ImageData(assetId: 'asset-0', size: Size2D(100, 100)),
      ),
    ],
  );
}

Future<ui.Image> _createImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 2, 2),
    ui.Paint()..color = const ui.Color(0xFF336699),
  );

  final picture = recorder.endRecording();

  try {
    return await picture.toImage(2, 2);
  } finally {
    picture.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('coordinator uses one pool for intrinsic and raster state', () async {
    final decoded = await _createImage();

    final fonts = _FakeFonts();
    final icons = _FakeIcons();

    final media = _FakeMedia(
      urls: const <String, String>{'media:one': 'asset:assets/resolved.png'},
      intrinsicSizes: const <String, Size2D>{'media:one': Size2D(640, 480)},
    );

    var decoderCalls = 0;

    final pool = FlutterImagePool(
      assetUrlResolver: media.resolveUrl,
      assetUrlsResolver: media.resolveUrls,
      assetMetaResolver: media.resolveIntrinsicSize,
      assetMetasResolver: media.resolveIntrinsicSizes,
      decoder: (_) async {
        decoderCalls++;
        return decoded;
      },
    );

    final resources = CanvasRuntimeResources(
      fonts: fonts,
      icons: icons,
      media: media,
    );

    final coordinator = EditorAssetCoordinator(
      assets: resources,
      pool: pool,
      targetW: 1024,
      targetH: 1024,
    );

    final intrinsicEvents = <ElementId>[];
    final subscription = pool.onIntrinsicUpdated.listen(intrinsicEvents.add);

    final result = await coordinator.ensureForScene(_imageScene('media:one'));

    await pumpEventQueue();

    expect(result.fontsLoaded, isFalse);
    expect(fonts.loadedRequests, isEmpty);

    expect(media.requestedUrls, ['media:one']);
    expect(media.requestedIntrinsicSizes, ['media:one']);

    expect(pool.intrinsicSize('image-0'), const Size2D(640, 480));

    expect(intrinsicEvents, ['image-0']);
    expect(decoderCalls, 1);

    expect(identical(pool.images['image-0'], decoded), isTrue);

    expect(pool.revision.value, 1);
    expect(decoded.debugDisposed, isFalse);

    await subscription.cancel();

    coordinator.dispose();
    pool.dispose();

    expect(decoded.debugDisposed, isTrue);
    expect(pool.images, isEmpty);
  });

  test('coordinator disposal invalidates blocked font preparation', () async {
    final fontLoad = Completer<void>();

    final fonts = _BlockingFonts(fontLoad.future);
    final icons = _FakeIcons();

    final media = _FakeMedia(
      urls: const <String, String>{},
      intrinsicSizes: const <String, Size2D>{},
    );

    final pool = FlutterImagePool(
      assetUrlResolver: media.resolveUrl,
      assetUrlsResolver: media.resolveUrls,
      assetMetaResolver: media.resolveIntrinsicSize,
      assetMetasResolver: media.resolveIntrinsicSizes,
      decoder: (_) {
        throw StateError('Decoder must not be reached.');
      },
    );

    final resources = CanvasRuntimeResources(
      fonts: fonts,
      icons: icons,
      media: media,
    );

    final coordinator = EditorAssetCoordinator(assets: resources, pool: pool);

    final future = coordinator.ensureForScene(_imageScene('media:one'));

    await fonts.started.future;

    coordinator.dispose();
    fontLoad.complete();

    final result = await future;

    expect(result.fontsLoaded, isFalse);
    expect(media.requestedUrls, isEmpty);
    expect(media.requestedIntrinsicSizes, isEmpty);
    expect(pool.images, isEmpty);

    pool.dispose();
  });

  test(
    'coordinator preloads raster while intrinsic metadata is pending',
    () async {
      final decoded = await _createImage();
      final metadata = Completer<Map<String, Size2D>>();
      final metadataStarted = Completer<void>();
      final decoderStarted = Completer<void>();

      final fonts = _FakeFonts();
      final icons = _FakeIcons();
      final media = _FakeMedia(
        urls: const <String, String>{
          'media:one': 'asset:assets/resolved.png',
        },
        intrinsicSizes: const <String, Size2D>{},
      );

      final pool = FlutterImagePool(
        assetUrlsResolver: media.resolveUrls,
        assetMetasResolver: (refs) {
          metadataStarted.complete();
          return metadata.future;
        },
        decoder: (_) async {
          decoderStarted.complete();
          return decoded;
        },
      );

      final coordinator = EditorAssetCoordinator(
        assets: CanvasRuntimeResources(
          fonts: fonts,
          icons: icons,
          media: media,
        ),
        pool: pool,
      );

      final resultFuture = coordinator.ensureForScene(
        _imageScene('media:one'),
      );

      await metadataStarted.future;
      await pumpEventQueue();

      expect(decoderStarted.isCompleted, isTrue);

      final result = await resultFuture;

      expect(result.fontsLoaded, isFalse);
      expect(identical(pool.images['image-0'], decoded), isTrue);

      metadata.complete(const <String, Size2D>{});
      await pumpEventQueue();

      coordinator.dispose();
      pool.dispose();
      expect(decoded.debugDisposed, isTrue);
    },
  );
}

final class _BlockingFonts implements CanvasFontAssets {
  _BlockingFonts(this.completion);

  final Future<void> completion;
  final Completer<void> started = Completer<void>();

  @override
  List<FontDef> get pickerFonts => const <FontDef>[];

  @override
  List<FontDef> get loadableFonts => const <FontDef>[];

  // This forces the coordinator to enter ensureLoaded().
  @override
  Iterable<String> get fallbackFontFamilies => const <String>['TestFont'];

  @override
  Future<void> ensureLoaded(Iterable<String> families) {
    if (!started.isCompleted) {
      started.complete();
    }

    return completion;
  }
}
