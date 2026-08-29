// Path: packages/canvas_renderer_flutter/test/flutter_image_pool_test.dart

import 'dart:async';
import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

CanvasSceneDocument _sceneWithImages(List<String> sourceRefs) {
  return CanvasSceneDocument(
    artboardSize: const Size2D(300, 200),
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1.0,
    assets: <CanvasAssetId, CanvasImageAsset>{
      for (var i = 0; i < sourceRefs.length; i++)
        'asset-$i': CanvasImageAsset(sourceRef: sourceRefs[i]),
    },
    children: [
      for (var i = 0; i < sourceRefs.length; i++)
        Node.image(
          id: 'image-$i',
          data: ImageData(assetId: 'asset-$i', size: const Size2D(100, 100)),
        ),
    ],
  );
}

Future<ui.Image> _createImage({
  int width = 2,
  int height = 2,
  int color = 0xFF336699,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = ui.Color(color),
  );

  final picture = recorder.endRecording();

  try {
    return await picture.toImage(width, height);
  } finally {
    picture.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterImagePool intrinsic metadata', () {
    test('implements ImageIntrinsics directly', () {
      final pool = FlutterImagePool();

      expect(pool, isA<ImageIntrinsics>());

      pool.dispose();
    });

    test('passes opaque media refs to resolver unchanged', () async {
      final requestedRefs = <String>[];

      final pool = FlutterImagePool(
        assetMetaResolver: (sourceRef) async {
          requestedRefs.add(sourceRef);
          return const Size2D(640, 480);
        },
      );

      await pool.resolveSceneIntrinsics(_sceneWithImages(['media:abc123']));

      expect(requestedRefs, ['media:abc123']);
      expect(pool.intrinsicSize('image-0'), const Size2D(640, 480));

      pool.dispose();
    });

    test('passes opaque asset refs to resolver unchanged', () async {
      final requestedRefs = <String>[];

      final pool = FlutterImagePool(
        assetMetaResolver: (sourceRef) async {
          requestedRefs.add(sourceRef);
          return const Size2D(1024, 1024);
        },
      );

      await pool.resolveSceneIntrinsics(
        _sceneWithImages(['asset:assets/samples/sample_image.png']),
      );

      expect(requestedRefs, ['asset:assets/samples/sample_image.png']);

      expect(pool.intrinsicSize('image-0'), const Size2D(1024, 1024));

      pool.dispose();
    });

    test('emits only when intrinsic metadata actually changes', () async {
      final events = <ElementId>[];

      final pool = FlutterImagePool(
        assetMetaResolver: (_) async => const Size2D(640, 480),
      );

      final subscription = pool.onIntrinsicUpdated.listen(events.add);
      final scene = _sceneWithImages(['media:one']);

      expect(pool.revision.value, 0);

      await pool.resolveSceneIntrinsics(scene);
      await pumpEventQueue();

      expect(events, ['image-0']);
      expect(pool.intrinsicSize('image-0'), const Size2D(640, 480));
      expect(pool.revision.value, 0);

      await pool.resolveSceneIntrinsics(scene);
      await pumpEventQueue();

      expect(events, [
        'image-0',
      ], reason: 'Identical cached metadata must not emit again.');
      expect(pool.revision.value, 0);

      await pool.resolveSceneIntrinsics(_sceneWithImages(const []));
      await pumpEventQueue();

      expect(events, ['image-0', 'image-0']);
      expect(pool.intrinsicSize('image-0'), isNull);
      expect(pool.revision.value, 0);

      await subscription.cancel();
      pool.dispose();
    });

    test('latest intrinsic request wins', () async {
      final firstResult = Completer<Size2D?>();
      final secondResult = Completer<Size2D?>();

      final firstStarted = Completer<void>();
      final secondStarted = Completer<void>();

      final pool = FlutterImagePool(
        assetMetaResolver: (sourceRef) {
          switch (sourceRef) {
            case 'media:first':
              firstStarted.complete();
              return firstResult.future;

            case 'media:second':
              secondStarted.complete();
              return secondResult.future;

            default:
              throw StateError('Unexpected source: $sourceRef');
          }
        },
      );

      final firstFuture = pool.resolveSceneIntrinsics(
        _sceneWithImages(['media:first']),
      );

      await firstStarted.future;

      final secondFuture = pool.resolveSceneIntrinsics(
        _sceneWithImages(['media:second']),
      );

      await secondStarted.future;

      secondResult.complete(const Size2D(800, 600));
      await secondFuture;

      expect(pool.intrinsicSize('image-0'), const Size2D(800, 600));

      firstResult.complete(const Size2D(320, 200));
      await firstFuture;

      expect(
        pool.intrinsicSize('image-0'),
        const Size2D(800, 600),
        reason: 'The older request must not overwrite the newer scene.',
      );

      pool.dispose();
    });

    test('late intrinsic completion cannot write after disposal', () async {
      final resolver = Completer<Map<String, Size2D>>();

      final pool = FlutterImagePool(assetMetasResolver: (_) => resolver.future);

      final future = pool.resolveSceneIntrinsics(
        _sceneWithImages(['media:late']),
      );

      pool.dispose();

      resolver.complete(const <String, Size2D>{'media:late': Size2D(640, 480)});

      await expectLater(future, completes);
      expect(pool.intrinsicSize('image-0'), isNull);
    });

    test('falls back to isolated resolvers when bulk metadata fails', () async {
      final requestedRefs = <String>[];

      final pool = FlutterImagePool(
        assetMetasResolver: (_) async {
          throw StateError('Bulk metadata unavailable');
        },
        assetMetaResolver: (sourceRef) async {
          requestedRefs.add(sourceRef);

          if (sourceRef == 'media:one') {
            return const Size2D(640, 480);
          }

          throw StateError('Metadata unavailable for $sourceRef');
        },
      );

      await pool.resolveSceneIntrinsics(
        _sceneWithImages(['media:one', 'media:two']),
      );

      expect(requestedRefs, unorderedEquals(['media:one', 'media:two']));
      expect(pool.intrinsicSize('image-0'), const Size2D(640, 480));
      expect(pool.intrinsicSize('image-1'), isNull);

      pool.dispose();
    });
  });

  group('FlutterImagePool decoded image ownership', () {
    test('images view is live and externally immutable', () async {
      final decoded = await _createImage();

      final pool = FlutterImagePool(decoder: (_) async => decoded);

      final images = pool.images;

      expect(identical(images, pool.images), isTrue);
      expect(images, isEmpty);

      expect(() => images['image-0'] = null, throwsUnsupportedError);

      await pool.preloadScene(_sceneWithImages(['asset:assets/test.png']));

      expect(identical(images['image-0'], decoded), isTrue);

      pool.dispose();

      expect(images, isEmpty);
      expect(decoded.debugDisposed, isTrue);
    });

    test('raster changes update revision without intrinsic events', () async {
      final decoded = await _createImage();
      final intrinsicEvents = <ElementId>[];

      final pool = FlutterImagePool(decoder: (_) async => decoded);

      final subscription = pool.onIntrinsicUpdated.listen(intrinsicEvents.add);

      expect(pool.revision.value, 0);

      await pool.preloadScene(_sceneWithImages(['asset:assets/test.png']));

      await pumpEventQueue();

      expect(pool.revision.value, 1);
      expect(intrinsicEvents, isEmpty);
      expect(identical(pool.images['image-0'], decoded), isTrue);

      await subscription.cancel();
      pool.dispose();

      expect(decoded.debugDisposed, isTrue);
    });

    test('raster preload proceeds while metadata remains pending', () async {
      final decoded = await _createImage();
      final metadata = Completer<Map<String, Size2D>>();
      final metadataStarted = Completer<void>();
      final decoderStarted = Completer<void>();
      var metadataCalls = 0;

      final pool = FlutterImagePool(
        assetMetasResolver: (_) {
          metadataCalls++;
          metadataStarted.complete();
          return metadata.future;
        },
        decoder: (_) async {
          decoderStarted.complete();
          return decoded;
        },
      );
      final scene = _sceneWithImages(['asset:assets/test.png']);

      final intrinsicFuture = pool.resolveSceneIntrinsics(scene);
      await metadataStarted.future;

      final preloadFuture = pool.preloadScene(scene, targetW: 128);
      await pumpEventQueue();

      expect(decoderStarted.isCompleted, isTrue);
      expect(metadataCalls, 1);

      await preloadFuture;
      expect(identical(pool.images['image-0'], decoded), isTrue);

      metadata.complete(const <String, Size2D>{});
      await intrinsicFuture;

      pool.dispose();
      expect(decoded.debugDisposed, isTrue);
    });

    test('replacing a decoded image disposes the previous handle', () async {
      final first = await _createImage(color: 0xFFFF0000);
      final second = await _createImage(color: 0xFF00FF00);

      var decoderCall = 0;

      final pool = FlutterImagePool(
        decoder: (_) async {
          return decoderCall++ == 0 ? first : second;
        },
      );

      final scene = _sceneWithImages(['asset:assets/test.png']);

      await pool.preloadScene(scene, targetW: 128);

      expect(first.debugDisposed, isFalse);
      expect(pool.revision.value, 1);

      // The different decode target produces a different raster key while the
      // source remains the same, exercising replacement rather than source
      // clearing.
      await pool.preloadScene(scene, targetW: 256);

      expect(first.debugDisposed, isTrue);
      expect(second.debugDisposed, isFalse);
      expect(identical(pool.images['image-0'], second), isTrue);
      expect(pool.revision.value, 2);

      pool.dispose();

      expect(second.debugDisposed, isTrue);
    });

    test('source changes clear the previous image immediately', () async {
      final first = await _createImage(color: 0xFFFF0000);
      final second = await _createImage(color: 0xFF0000FF);

      final secondDecode = Completer<ui.Image?>();
      final secondDecodeStarted = Completer<void>();

      var decoderCall = 0;

      final pool = FlutterImagePool(
        decoder: (_) {
          if (decoderCall++ == 0) {
            return Future<ui.Image?>.value(first);
          }

          secondDecodeStarted.complete();
          return secondDecode.future;
        },
      );

      await pool.preloadScene(_sceneWithImages(['asset:assets/first.png']));

      expect(identical(pool.images['image-0'], first), isTrue);

      final secondFuture = pool.preloadScene(
        _sceneWithImages(['asset:assets/second.png']),
      );

      // Reconciliation happens before URL or decoder awaits.
      expect(pool.images['image-0'], isNull);
      expect(first.debugDisposed, isTrue);

      await secondDecodeStarted.future;

      secondDecode.complete(second);
      await secondFuture;

      expect(identical(pool.images['image-0'], second), isTrue);
      expect(second.debugDisposed, isFalse);

      pool.dispose();

      expect(second.debugDisposed, isTrue);
    });

    test('removing an element releases its decoded image', () async {
      final decoded = await _createImage();

      final pool = FlutterImagePool(decoder: (_) async => decoded);

      await pool.preloadScene(_sceneWithImages(['asset:assets/test.png']));

      expect(decoded.debugDisposed, isFalse);
      expect(pool.revision.value, 1);

      await pool.preloadScene(_sceneWithImages(const []));

      expect(decoded.debugDisposed, isTrue);
      expect(pool.images, isEmpty);
      expect(pool.revision.value, 2);

      pool.dispose();
    });

    test('latest preload request wins', () async {
      final staleImage = await _createImage(color: 0xFFFF0000);
      final latestImage = await _createImage(color: 0xFF00FF00);

      final staleResult = Completer<ui.Image?>();
      final latestResult = Completer<ui.Image?>();

      final staleStarted = Completer<void>();
      final latestStarted = Completer<void>();

      var decoderCall = 0;

      final pool = FlutterImagePool(
        decoder: (_) {
          switch (decoderCall++) {
            case 0:
              staleStarted.complete();
              return staleResult.future;

            case 1:
              latestStarted.complete();
              return latestResult.future;

            default:
              throw StateError('Unexpected decoder invocation');
          }
        },
      );

      final staleFuture = pool.preloadScene(
        _sceneWithImages(['asset:assets/stale.png']),
      );

      await staleStarted.future;

      final latestFuture = pool.preloadScene(
        _sceneWithImages(['asset:assets/latest.png']),
      );

      await latestStarted.future;

      latestResult.complete(latestImage);
      await latestFuture;

      expect(identical(pool.images['image-0'], latestImage), isTrue);
      expect(latestImage.debugDisposed, isFalse);

      staleResult.complete(staleImage);
      await staleFuture;

      expect(staleImage.debugDisposed, isTrue);
      expect(
        identical(pool.images['image-0'], latestImage),
        isTrue,
        reason: 'The stale completion must not replace the latest image.',
      );

      pool.dispose();

      expect(latestImage.debugDisposed, isTrue);
    });

    test('late decoder result is disposed after pool disposal', () async {
      final lateImage = await _createImage();
      final decoderResult = Completer<ui.Image?>();
      final decoderStarted = Completer<void>();

      final pool = FlutterImagePool(
        decoder: (_) {
          decoderStarted.complete();
          return decoderResult.future;
        },
      );

      final images = pool.images;

      final future = pool.preloadScene(
        _sceneWithImages(['asset:assets/late.png']),
      );

      await decoderStarted.future;

      pool.dispose();

      decoderResult.complete(lateImage);
      await expectLater(future, completes);

      expect(lateImage.debugDisposed, isTrue);
      expect(images, isEmpty);
    });

    test('dispose releases every currently retained image', () async {
      final first = await _createImage(color: 0xFFFF0000);
      final second = await _createImage(color: 0xFF00FF00);

      var decoderCall = 0;

      final pool = FlutterImagePool(
        decoder: (_) async {
          return decoderCall++ == 0 ? first : second;
        },
      );

      await pool.preloadScene(
        _sceneWithImages(['asset:assets/first.png', 'asset:assets/second.png']),
      );

      expect(first.debugDisposed, isFalse);
      expect(second.debugDisposed, isFalse);
      expect(pool.images, hasLength(2));

      pool.dispose();

      expect(first.debugDisposed, isTrue);
      expect(second.debugDisposed, isTrue);
      expect(pool.images, isEmpty);

      // Disposal remains idempotent.
      pool.dispose();
    });
  });

  group('FlutterImagePool resolver boundaries', () {
    test(
      'passes original source refs to bulk URL resolver unchanged',
      () async {
        final requestedBatches = <List<String>>[];

        final pool = FlutterImagePool(
          assetUrlsResolver: (sourceRefs) async {
            requestedBatches.add(List<String>.from(sourceRefs));

            return const <String, String>{};
          },
          decoder: (_) {
            throw StateError(
              'Decoder must not run for unresolved opaque refs.',
            );
          },
        );

        await pool.preloadScene(
          _sceneWithImages([
            'media:abc123',
            'asset:assets/samples/sample_image.png',
          ]),
        );

        expect(requestedBatches, hasLength(1));
        expect(
          requestedBatches.single,
          unorderedEquals([
            'media:abc123',
            'asset:assets/samples/sample_image.png',
          ]),
        );
        expect(pool.images, isEmpty);

        pool.dispose();
      },
    );

    test('does not guess unresolved refs when a URL resolver exists', () async {
      final pool = FlutterImagePool(
        assetUrlResolver: (_) async => null,
        decoder: (_) {
          throw StateError('Decoder must not run for unresolved opaque refs.');
        },
      );

      await pool.preloadScene(_sceneWithImages(['media:missing']));

      expect(pool.images, isEmpty);

      pool.dispose();
    });

    test(
      'late unresolved URL completion cannot write after disposal',
      () async {
        final resolver = Completer<Map<String, String>>();

        final pool = FlutterImagePool(
          assetUrlsResolver: (_) => resolver.future,
        );

        final images = pool.images;

        final future = pool.preloadScene(_sceneWithImages(['media:late']));

        pool.dispose();

        resolver.complete(const <String, String>{});

        await expectLater(future, completes);
        expect(images, isEmpty);
      },
    );
  });
}
