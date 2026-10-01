// Path: packages/canvas_renderer_flutter/lib/src/images/flutter_image_pool.dart

import 'dart:async';
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
typedef FlutterImageDecoder =
    Future<ui.Image?> Function(ImageProvider<Object> provider);

/// The loading stage that could not supply an image resource.
enum FlutterImageLoadPhase { sourceResolution, intrinsicMetadata, rasterDecode }

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
/// The pool owns two deliberately separate kinds of state:
///
/// - Stable intrinsic metadata, which may trigger layout invalidation.
/// - Decoded raster handles, which only trigger repaint notifications.
///
/// One pool must not be shared between unrelated documents because its state is
/// keyed by document-local [ElementId] values.
class FlutterImagePool implements ImageIntrinsics {
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

  final Map<ElementId, Size2D> _intrinsicById = <ElementId, Size2D>{};

  /// Tracks which source currently owns each intrinsic entry.
  final Map<ElementId, String> _intrinsicSourceById = <ElementId, String>{};

  /// Tracks which source currently owns each raster entry.
  final Map<ElementId, String> _rasterSourceById = <ElementId, String>{};

  final StreamController<ElementId> _intrinsicUpdatedController =
      StreamController<ElementId>.broadcast();

  final ValueNotifier<int> _revision = ValueNotifier<int>(0);

  /// Repaint-only notification.
  ///
  /// Intrinsic metadata changes use [onIntrinsicUpdated] instead.
  ValueListenable<int> get revision => _revision;

  // Cache: opaque source ref -> stable intrinsic size.
  final Map<String, Size2D> _metaCache = <String, Size2D>{};

  // Element ID -> successfully installed raster key.
  final Map<ElementId, String> _loadedKey = <ElementId, String>{};

  // The two public stages are independent and may overlap.
  int _intrinsicsGeneration = 0;
  int _preloadGeneration = 0;

  bool _disposed = false;

  bool _isCurrentIntrinsicsRequest(int generation) {
    return !_disposed && generation == _intrinsicsGeneration;
  }

  bool _isCurrentPreloadRequest(int generation) {
    return !_disposed && generation == _preloadGeneration;
  }

  @override
  Size2D? intrinsicSize(ElementId id) => _intrinsicById[id];

  /// Reports layout-affecting intrinsic metadata changes.
  ///
  /// This is a Flutter runtime lifecycle signal and is intentionally separate
  /// from the synchronous core [ImageIntrinsics] contract.
  Stream<ElementId> get onIntrinsicUpdated =>
      _intrinsicUpdatedController.stream;

  void _bumpRevision() {
    if (_disposed) return;
    _revision.value++;
  }

  void _setIntrinsicSize(ElementId id, Size2D? size) {
    if (_disposed) return;

    final previous = _intrinsicById[id];
    if (previous == size) return;

    if (size == null) {
      _intrinsicById.remove(id);
    } else {
      _intrinsicById[id] = size;
    }

    _intrinsicUpdatedController.add(id);
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

  String? _sourceKeyFromRaw(String? raw) {
    final value = raw?.trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  CanvasImageAsset? _assetForImage(CanvasSceneDocument scene, ImageNode image) {
    final assetId = image.data.assetId;
    return assetId == null ? null : scene.assets[assetId];
  }

  Size2D? _usableIntrinsicSize(Size2D? size) {
    if (size == null ||
        !size.w.isFinite ||
        !size.h.isFinite ||
        size.w <= 0 ||
        size.h <= 0) {
      return null;
    }

    return size;
  }

  int? _decodeSide(int? width, int? height) {
    if (width == null && height == null) return null;
    if (width == null) return height;
    if (height == null) return width;

    return width > height ? width : height;
  }

  _DecodeDims _decodeDimsFromMeta(int? side, Size2D? meta) {
    if (side == null) {
      return const _DecodeDims(null, null);
    }

    if (meta == null || meta.w <= 0 || meta.h <= 0) {
      return _DecodeDims(side, null);
    }

    final maxSide = meta.w > meta.h ? meta.w : meta.h;
    final scale = side / maxSide;

    var width = (meta.w * scale).round();
    var height = (meta.h * scale).round();

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

  Future<List<FlutterImageLoadFailure>> _primeMetaCache(
    Set<String> sourceRefs,
    int generation,
  ) async {
    final missing = <String>[
      for (final ref in sourceRefs)
        if (!_metaCache.containsKey(ref)) ref,
    ];

    if (missing.isEmpty) return const [];

    final imageResolver = resolver;
    final failures = <FlutterImageLoadFailure>[];

    try {
      final resolvedByRef = imageResolver == null
          ? const <String, Size2D>{}
          : await imageResolver.resolveIntrinsicSizes(missing);

      // Stale metadata must not populate the cache used by the current scene.
      if (!_isCurrentIntrinsicsRequest(generation)) return const [];

      for (final ref in missing) {
        final rawSize = resolvedByRef[ref];
        final size = _usableIntrinsicSize(rawSize);

        if (size != null) {
          _metaCache[ref] = size;
        } else {
          failures.add(
            FlutterImageLoadFailure(
              sourceRef: ref,
              phase: FlutterImageLoadPhase.intrinsicMetadata,
              reason: imageResolver == null
                  ? 'No intrinsic metadata resolver.'
                  : rawSize == null
                  ? 'Resolver returned no intrinsic metadata.'
                  : 'Resolver returned unusable intrinsic metadata.',
            ),
          );
        }
      }
    } catch (error, stackTrace) {
      if (!_isCurrentIntrinsicsRequest(generation)) return const [];

      for (final ref in missing) {
        failures.add(
          FlutterImageLoadFailure(
            sourceRef: ref,
            phase: FlutterImageLoadPhase.intrinsicMetadata,
            reason: 'Intrinsic metadata resolver threw.',
            cause: error,
            stackTrace: stackTrace,
          ),
        );
      }
    }

    return failures;
  }

  void _reconcileIntrinsicSources(Map<ElementId, String?> sourceByElement) {
    final activeIds = sourceByElement.keys.toSet();

    for (final id in _intrinsicById.keys.toList(growable: false)) {
      if (!activeIds.contains(id)) {
        _setIntrinsicSize(id, null);
      }
    }

    for (final id in _intrinsicSourceById.keys.toList(growable: false)) {
      if (!activeIds.contains(id)) {
        _intrinsicSourceById.remove(id);
      }
    }

    for (final entry in sourceByElement.entries) {
      final id = entry.key;
      final sourceRef = entry.value;
      final previousSource = _intrinsicSourceById[id];

      if (sourceRef == null || previousSource != sourceRef) {
        _setIntrinsicSize(id, null);
      }

      if (sourceRef == null) {
        _intrinsicSourceById.remove(id);
      } else {
        _intrinsicSourceById[id] = sourceRef;
      }
    }
  }

  void _reconcileRasterSources(Map<ElementId, String?> sourceByElement) {
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
      if (sourceRef == null || previousSource != sourceRef) {
        _clearDecodedImage(id);
      }

      if (sourceRef == null) {
        _rasterSourceById.remove(id);
      } else {
        _rasterSourceById[id] = sourceRef;
      }
    }
  }

  /// Resolves and publishes stable intrinsic image metadata.
  ///
  /// This method never decodes raster images and never changes [revision].
  /// Returns immutable, operation-local failures; best-effort consumers may
  /// ignore them. Superseded or disposed operations return an empty list.
  Future<List<FlutterImageLoadFailure>> resolveSceneIntrinsics(
    CanvasSceneDocument scene, {
    bool includeHidden = true,
  }) async {
    if (_disposed) return const [];

    final generation = ++_intrinsicsGeneration;

    final imageNodes = _collectImageNodes(scene, includeHidden: includeHidden);

    final assetByElement = <ElementId, CanvasImageAsset?>{
      for (final image in imageNodes) image.id: _assetForImage(scene, image),
    };

    final sourceByElement = <ElementId, String?>{
      for (final image in imageNodes)
        image.id: _sourceKeyFromRaw(assetByElement[image.id]?.sourceRef),
    };

    final persistedIntrinsicByElement = <ElementId, Size2D?>{
      for (final image in imageNodes)
        image.id: sourceByElement[image.id] == null
            ? null
            : _usableIntrinsicSize(assetByElement[image.id]?.intrinsicSize),
    };

    _reconcileIntrinsicSources(sourceByElement);

    for (final entry in persistedIntrinsicByElement.entries) {
      if (entry.value != null) {
        _setIntrinsicSize(entry.key, entry.value);
      }
    }

    final sourceRefs = sourceByElement.entries
        .where((entry) => persistedIntrinsicByElement[entry.key] == null)
        .map((entry) => entry.value)
        .whereType<String>()
        .toSet();

    final failures = await _primeMetaCache(sourceRefs, generation);

    if (!_isCurrentIntrinsicsRequest(generation)) {
      return const [];
    }

    for (final entry in sourceByElement.entries) {
      final sourceRef = entry.value;
      final size =
          persistedIntrinsicByElement[entry.key] ??
          (sourceRef == null ? null : _metaCache[sourceRef]);

      _setIntrinsicSize(entry.key, size);
    }

    return List<FlutterImageLoadFailure>.unmodifiable(failures);
  }

  /// Decodes raster images for painting.
  ///
  /// This method never updates intrinsic metadata and therefore never emits
  /// [onIntrinsicUpdated].
  /// Returns immutable, operation-local failures without making interactive
  /// loading strict. Superseded or disposed operations return an empty list.
  Future<List<FlutterImageLoadFailure>> preloadScene(
    CanvasSceneDocument scene, {
    int? targetW,
    int? targetH,
    bool includeHidden = true,
  }) async {
    if (_disposed) return const [];

    final generation = ++_preloadGeneration;

    final imageNodes = _collectImageNodes(scene, includeHidden: includeHidden);

    final assetByElement = <ElementId, CanvasImageAsset?>{
      for (final image in imageNodes) image.id: _assetForImage(scene, image),
    };

    final sourceByElement = <ElementId, String?>{
      for (final image in imageNodes)
        image.id: _sourceKeyFromRaw(assetByElement[image.id]?.sourceRef),
    };

    final persistedIntrinsicByElement = <ElementId, Size2D?>{
      for (final image in imageNodes)
        image.id: sourceByElement[image.id] == null
            ? null
            : _usableIntrinsicSize(assetByElement[image.id]?.intrinsicSize),
    };

    _reconcileRasterSources(sourceByElement);

    final sourceRefs = sourceByElement.values.whereType<String>().toSet();

    final failures = <FlutterImageLoadFailure>[];
    final renderableSourceByRef = await _resolveRenderableSources(
      sourceRefs,
      failures,
    );

    if (!_isCurrentPreloadRequest(generation)) {
      return const [];
    }

    // Do not fetch optional metadata on the raster critical path. Each image
    // uses persisted or already-cached metadata when available, then falls
    // back to a one-sided decode hint.
    final side = _decodeSide(targetW, targetH);

    final decodeFailures = await Future.wait<FlutterImageLoadFailure?>([
      for (final image in imageNodes)
        _preloadImageNode(
          image,
          generation: generation,
          side: side,
          sourceRef: sourceByElement[image.id],
          renderableSource: sourceByElement[image.id] == null
              ? null
              : renderableSourceByRef[sourceByElement[image.id]!],
          persistedIntrinsic: persistedIntrinsicByElement[image.id],
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
    required String? sourceRef,
    required String? renderableSource,
    required Size2D? persistedIntrinsic,
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

    final meta =
        persistedIntrinsic ??
        (sourceRef == null ? null : _metaCache[sourceRef]);

    final dimensions = _decodeDimsFromMeta(side, meta);

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
          sourceRef: sourceRef!,
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
        sourceRef: sourceRef!,
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
    _intrinsicsGeneration++;
    _preloadGeneration++;

    final retainedImages = HashSet<ui.Image>.identity()
      ..addAll(_images.values.whereType<ui.Image>());

    for (final image in retainedImages) {
      image.dispose();
    }

    _images.clear();
    _intrinsicById.clear();
    _intrinsicSourceById.clear();
    _rasterSourceById.clear();
    _loadedKey.clear();
    _metaCache.clear();

    _intrinsicUpdatedController.close();
    _revision.dispose();
  }
}

List<ImageNode> _collectImageNodes(
  CanvasSceneDocument scene, {
  required bool includeHidden,
}) {
  final result = <ImageNode>[];

  visitSceneNodes(
    scene,
    includeHidden: includeHidden,
    visit: (node) {
      if (node is ImageNode) {
        result.add(node);
      }
    },
  );

  return result;
}
