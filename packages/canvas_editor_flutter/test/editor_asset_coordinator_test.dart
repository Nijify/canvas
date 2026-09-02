// Path: packages/canvas_editor_flutter/test/editor_asset_coordinator_test.dart

import 'dart:async';
import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/canvas_runtime_resources.dart';
import 'package:canvas_editor_flutter/src/runtime/editor_asset_coordinator.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeFonts implements FlutterFontLoader {
  final List<Set<String>> loadedRequests = <Set<String>>[];

  @override
  Iterable<String> get fallbackFontFamilies => const <String>[];

  @override
  Future<bool> ensureLoaded(Iterable<String> families) async {
    loadedRequests.add(families.toSet());
    return false;
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

final class _FakeImages implements CanvasImageAssetResolver {
  _FakeImages({
    required this.sources,
    required this.intrinsicSizes,
    this.resolveIntrinsicSizesCallback,
  });

  final Map<String, String> sources;
  final Map<String, Size2D> intrinsicSizes;

  final Future<Map<String, Size2D>> Function(List<String> sourceRefs)?
  resolveIntrinsicSizesCallback;

  final List<String> requestedSources = <String>[];
  final List<String> requestedIntrinsicSizes = <String>[];

  @override
  Future<Map<String, String>> resolveSources(List<String> sourceRefs) async {
    requestedSources.addAll(sourceRefs);

    return <String, String>{
      for (final sourceRef in sourceRefs)
        if (sources.containsKey(sourceRef)) sourceRef: sources[sourceRef]!,
    };
  }

  @override
  Future<Map<String, Size2D>> resolveIntrinsicSizes(
    List<String> sourceRefs,
  ) async {
    requestedIntrinsicSizes.addAll(sourceRefs);

    final callback = resolveIntrinsicSizesCallback;
    if (callback != null) {
      return callback(sourceRefs);
    }

    return <String, Size2D>{
      for (final sourceRef in sourceRefs)
        if (intrinsicSizes.containsKey(sourceRef))
          sourceRef: intrinsicSizes[sourceRef]!,
    };
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

    final images = _FakeImages(
      sources: const <String, String>{'media:one': 'asset:assets/resolved.png'},
      intrinsicSizes: const <String, Size2D>{'media:one': Size2D(640, 480)},
    );

    var decoderCalls = 0;

    final pool = FlutterImagePool(
      resolver: images,
      decoder: (_) async {
        decoderCalls++;
        return decoded;
      },
    );

    final resources = CanvasRuntimeResources(
      fonts: fonts,
      pickerFonts: const <FontPickerItem>[],
      icons: icons,
      images: images,
    );

    final coordinator = EditorAssetCoordinator(
      assets: resources,
      pool: pool,
      targetW: 1024,
      targetH: 1024,
    );

    final intrinsicEvents = <ElementId>[];
    final subscription = pool.onIntrinsicUpdated.listen(intrinsicEvents.add);

    final fontsChanged = await coordinator.ensureForScene(
      _imageScene('media:one'),
    );

    await pumpEventQueue();

    expect(fontsChanged, isFalse);
    expect(fonts.loadedRequests, hasLength(1));
    expect(fonts.loadedRequests.single, isEmpty);

    expect(images.requestedSources, ['media:one']);
    expect(images.requestedIntrinsicSizes, ['media:one']);

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
    final fontLoad = Completer<bool>();

    final fonts = _BlockingFonts(fontLoad.future);
    final icons = _FakeIcons();

    final images = _FakeImages(
      sources: const <String, String>{},
      intrinsicSizes: const <String, Size2D>{},
    );

    final pool = FlutterImagePool(
      resolver: images,
      decoder: (_) {
        throw StateError('Decoder must not be reached.');
      },
    );

    final resources = CanvasRuntimeResources(
      fonts: fonts,
      pickerFonts: const <FontPickerItem>[],
      icons: icons,
      images: images,
    );

    final coordinator = EditorAssetCoordinator(assets: resources, pool: pool);

    final future = coordinator.ensureForScene(_imageScene('media:one'));

    await fonts.started.future;

    coordinator.dispose();
    fontLoad.complete(false);

    final result = await future;

    expect(result, isFalse);
    expect(images.requestedSources, isEmpty);
    expect(images.requestedIntrinsicSizes, isEmpty);
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
      final images = _FakeImages(
        sources: const <String, String>{
          'media:one': 'asset:assets/resolved.png',
        },
        intrinsicSizes: const <String, Size2D>{},
        resolveIntrinsicSizesCallback: (_) {
          metadataStarted.complete();
          return metadata.future;
        },
      );

      final pool = FlutterImagePool(
        resolver: images,
        decoder: (_) async {
          decoderStarted.complete();
          return decoded;
        },
      );

      final coordinator = EditorAssetCoordinator(
        assets: CanvasRuntimeResources(
          fonts: fonts,
          pickerFonts: const <FontPickerItem>[],
          icons: icons,
          images: images,
        ),
        pool: pool,
      );

      final resultFuture = coordinator.ensureForScene(_imageScene('media:one'));

      await metadataStarted.future;
      await pumpEventQueue();

      expect(decoderStarted.isCompleted, isTrue);

      final result = await resultFuture;

      expect(result, isFalse);
      expect(identical(pool.images['image-0'], decoded), isTrue);

      metadata.complete(const <String, Size2D>{});
      await pumpEventQueue();

      coordinator.dispose();
      pool.dispose();
      expect(decoded.debugDisposed, isTrue);
    },
  );
}

final class _BlockingFonts implements FlutterFontLoader {
  _BlockingFonts(this.completion);

  final Future<bool> completion;
  final Completer<void> started = Completer<void>();

  @override
  Iterable<String> get fallbackFontFamilies => const <String>['TestFont'];

  @override
  Future<bool> ensureLoaded(Iterable<String> families) {
    if (!started.isCompleted) {
      started.complete();
    }

    return completion;
  }
}
