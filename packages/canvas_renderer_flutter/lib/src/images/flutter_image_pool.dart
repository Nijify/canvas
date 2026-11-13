// Path: packages/canvas_renderer_flutter/lib/src/images/flutter_image_pool.dart

import 'dart:collection';
import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_renderer_flutter/src/images/flutter_image_adapters.dart';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/widgets.dart' show ImageProvider, ResizeImage;

/// Decodes an [ImageProvider] into an independently owned image handle.
///
/// A non-null image returned by this function transfers ownership of that
/// handle to [FlutterImagePool]. The pool will dispose it when it becomes
/// stale, is replaced, is removed from the scene, or the pool is disposed.
typedef FlutterImageDecoder = Future<ui.Image?> Function(
  ImageProvider<Object> provider,
);

/// The loading stage that could not supply an image resource.
enum FlutterImageLoadPhase { sourceResolution, rasterDecode }

/// Failure from one image-loading operation, not retained pool state.
///
/// [sourceRef], [cause], and [stackTrace] are structured diagnostic data and may
/// contain private paths, inline bytes, or URL credentials. Do not log them
/// without host-specific redaction. [toString] deliberately omits those values.
final class FlutterImageLoadFailure {
  const FlutterImageLoadFailure({
    required this.sourceRef,
    required this.phase,
    required this.reason,
    this.cause,
    this.stackTrace,
  });

  final String sourceRef;
  final FlutterImageLoadPhase phase;
  final String reason;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() =>
      '${phase.name}: $reason'
      '${cause == null ? '' : ' (${cause.runtimeType})'}';
}

class _DecodeDims {
  const _DecodeDims(this.w, this.h);

  final int? w;
  final int? h;
}

/// Owns all Flutter image state associated with one editor/rendering surface.
///
/// Asset dimensions stay in the scene; the pool owns decoded raster handles.
///
/// One pool must not be shared between unrelated documents because its state is
/// keyed by document-local [ElementId] values.
class FlutterImagePool {
  FlutterImagePool({this.resolver, FlutterImageDecoder decoder = toUiImage})
    : _decoder = decoder;

  final CanvasImageAssetResolver? resolver;

  final FlutterImageDecoder _decoder;

  final Map<ElementId, ui.Image?> _images = <ElementId, ui.Image?>{};

  /// Live, read-only view of the currently decoded images.
  ///
  /// Consumers that retain this map continue to observe later pool updates.
  late final Map<ElementId, ui.Image?> images =
      UnmodifiableMapView<ElementId, ui.Image?>(_images);

  /// Tracks which source currently owns each raster entry.
  final Map<ElementId, String> _rasterSourceById = <ElementId, String>{};

  final ValueNotifier<int> _revision = ValueNotifier<int>(0);

  /// Repaint-only notification.
  ValueListenable<int> get revision => _revision;

  // Element ID -> successfully installed raster key.
  final Map<ElementId, String> _loadedKey = <ElementId, String>{};

  int _preloadGeneration = 0;

  bool _disposed = false;

  bool _isCurrentPreloadRequest(int generation) {
    return !_disposed && generation == _preloadGeneration;
  }

  void _bumpRevision() {
    if (_disposed) return;
    _revision.value++;
  }

  void _clearDecodedImage(ElementId id) {
    _loadedKey.remove(id);

    final previous = _images.remove(id);
    if (previous == null) return;

    previous.dispose();
    _bumpRevision();
  }

  void _installDecodedImage(ElementId id, ui.Image image, String loadedKey) {
    if (_disposed) {
      image.dispose();
      return;
    }

    final previous = _images[id];

    _images[id] = image;
    _loadedKey[id] = loadedKey;

    if (identical(previous, image)) return;

    previous?.dispose();
    _bumpRevision();
  }

  int? _decodeSide(int? width, int? height) {
    if (width == null && height == null) return null;
    if (width == null) return height;
    if (height == null) return width;

    return width > height ? width : height;
  }

  _DecodeDims _decodeDims(int? side, Size2D size) {
    if (side == null) {
      return const _DecodeDims(null, null);
    }

    final maxSide = size.w > size.h ? size.w : size.h;
    final scale = side / maxSide;

    var width = (size.w * scale).round();
    var height = (size.h * scale).round();

    if (width < 1) width = 1;
    if (height < 1) height = 1;

    return _DecodeDims(width, height);
  }

  Future<Map<String, String>> _resolveRenderableSources(
    Set<String> sourceRefs,
    List<FlutterImageLoadFailure> failures,
  ) async {
    if (_disposed || sourceRefs.isEmpty) {
      return const <String, String>{};
    }

    final imageResolver = resolver;

    // Without a host resolver, logical refs must already be renderable.
    if (imageResolver == null) {
      return <String, String>{
        for (final sourceRef in sourceRefs) sourceRef: sourceRef,
      };
    }

    try {
      final resolvedByRef = await imageResolver.resolveSources(
        sourceRefs.toList(growable: false),
      );

      if (_disposed) return const <String, String>{};

      final result = <String, String>{};

      for (final sourceRef in sourceRefs) {
        final resolved = resolvedByRef[sourceRef]?.trim();

        if (resolved != null && resolved.isNotEmpty) {
          result[sourceRef] = resolved;
        } else {
          failures.add(
            FlutterImageLoadFailure(
              sourceRef: sourceRef,
              phase: FlutterImageLoadPhase.sourceResolution,
              reason: resolved == null
                  ? 'Resolver returned no source.'
                  : 'Resolver returned an empty source.',
            ),
          );
        }
      }

      return result;
    } catch (error, stackTrace) {
      for (final sourceRef in sourceRefs) {
        failures.add(
          FlutterImageLoadFailure(
            sourceRef: sourceRef,
            phase: FlutterImageLoadPhase.sourceResolution,
            reason: 'Source resolver threw.',
            cause: error,
            stackTrace: stackTrace,
          ),
        );
      }

      return const <String, String>{};
    }
  }

  void _reconcileRasterSources(Map<ElementId, String> sourceByElement) {
    final activeIds = sourceByElement.keys.toSet();

    for (final id in _images.keys.toList(growable: false)) {
      if (!activeIds.contains(id)) {
        _clearDecodedImage(id);
      }
    }

    for (final id in _rasterSourceById.keys.toList(growable: false)) {
      if (!activeIds.contains(id)) {
        _rasterSourceById.remove(id);
        _loadedKey.remove(id);
      }
    }

    for (final entry in sourceByElement.entries) {
      final id = entry.key;
      final sourceRef = entry.value;
      final previousSource = _rasterSourceById[id];

      // Clear immediately when the element changes source so the old raster
      // cannot temporarily paint as the new asset.
      if (previousSource != sourceRef) {
        _clearDecodedImage(id);
      }

      _rasterSourceById[id] = sourceRef;
    }
  }

  /// Decodes raster images for painting.
  ///
  /// Returns immutable, operation-local failures without making interactive
  /// loading strict. Superseded or disposed operations return an empty list.
  Future<List<FlutterImageLoadFailure>> preloadScene(
    CanvasSceneDocument scene, {
    int? targetW,
    int? targetH,
  }) async {
    if (_disposed) return const [];

    requireCanvasSceneIntegrity(scene);
    final generation = ++_preloadGeneration;

    final imageNodes = _collectImageNodes(scene);

    final assetByElement = <ElementId, CanvasImageAsset>{
      for (final image in imageNodes) image.id: scene.assets[image.assetId]!,
    };

    final sourceByElement = <ElementId, String>{
      for (final image in imageNodes)
        image.id: assetByElement[image.id]!.sourceRef.trim(),
    };

    _reconcileRasterSources(sourceByElement);

    final sourceRefs = sourceByElement.values.toSet();

    final failures = <FlutterImageLoadFailure>[];
    final renderableSourceByRef = await _resolveRenderableSources(
      sourceRefs,
      failures,
    );

    if (!_isCurrentPreloadRequest(generation)) {
      return const [];
    }

    // Decode-size hints preserve the aspect ratio stored on the asset.
    final side = _decodeSide(targetW, targetH);

    final decodeFailures = await Future.wait<FlutterImageLoadFailure?>([
      for (final image in imageNodes)
        _preloadImageNode(
          image,
          generation: generation,
          side: side,
          sourceRef: sourceByElement[image.id]!,
          renderableSource: renderableSourceByRef[sourceByElement[image.id]!],
          intrinsicSize: assetByElement[image.id]!.intrinsicSize,
        ),
    ]);

    if (!_isCurrentPreloadRequest(generation)) return const [];

    failures.addAll(decodeFailures.whereType<FlutterImageLoadFailure>());
    return List<FlutterImageLoadFailure>.unmodifiable(failures);
  }

  Future<FlutterImageLoadFailure?> _preloadImageNode(
    ImageNode image, {
    required int generation,
    required int? side,
    required String sourceRef,
    required String? renderableSource,
    required Size2D intrinsicSize,
  }) async {
    if (!_isCurrentPreloadRequest(generation)) {
      return null;
    }

    // When a host resolver is installed, a missing result is authoritative.
    // Without a resolver, _resolveRenderableSources maps sourceRef to itself.
    if (renderableSource == null || renderableSource.isEmpty) {
      _clearDecodedImage(image.id);
      return null;
    }

    final dimensions = _decodeDims(side, intrinsicSize);

    final loadedKey =
        '$renderableSource@${dimensions.w ?? 0}x${dimensions.h ?? 0}';

    if (_loadedKey[image.id] == loadedKey && _images[image.id] != null) {
      return null;
    }

    try {
      final baseProvider = sourceToProvider(renderableSource);

      final provider = dimensions.w != null && dimensions.h != null
          ? ResizeImage(
              baseProvider,
              width: dimensions.w!,
              height: dimensions.h!,
            )
          : withSize(baseProvider, width: side, height: null);

      final decoded = await _decoder(provider);

      if (!_isCurrentPreloadRequest(generation)) {
        decoded?.dispose();
        return null;
      }

      if (decoded == null) {
        _clearDecodedImage(image.id);
        return FlutterImageLoadFailure(
          sourceRef: sourceRef,
          phase: FlutterImageLoadPhase.rasterDecode,
          reason: 'Decoder returned no image.',
        );
      }

      _installDecodedImage(image.id, decoded, loadedKey);
      return null;
    } catch (error, stackTrace) {
      if (!_isCurrentPreloadRequest(generation)) {
        return null;
      }

      _clearDecodedImage(image.id);
      return FlutterImageLoadFailure(
        sourceRef: sourceRef,
        phase: FlutterImageLoadPhase.rasterDecode,
        reason: 'Image provider or decoder threw.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  void dispose() {
    if (_disposed) return;

    _disposed = true;
    _preloadGeneration++;

    final retainedImages = HashSet<ui.Image>.identity()
      ..addAll(_images.values.whereType<ui.Image>());

    for (final image in retainedImages) {
      image.dispose();
    }

    _images.clear();
    _rasterSourceById.clear();
    _loadedKey.clear();

    _revision.dispose();
  }
}

List<ImageNode> _collectImageNodes(CanvasSceneDocument scene) {
  final result = <ImageNode>[];

  visitSceneNodes(
    scene,
    visit: (node) {
      if (node is ImageNode && node.assetId != null) {
        result.add(node);
      }
    },
  );

  return result;
}
