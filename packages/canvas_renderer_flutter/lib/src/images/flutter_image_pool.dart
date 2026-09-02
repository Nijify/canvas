// Path: packages/canvas_renderer_flutter/lib/src/images/flutter_image_pool.dart

import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_renderer_flutter/src/images/flutter_image_adapters.dart';
import 'package:flutter/foundation.dart'
    show ValueListenable, ValueNotifier, debugPrint, kDebugMode;
import 'package:flutter/widgets.dart' show ImageProvider, ResizeImage;

/// Decodes an [ImageProvider] into an independently owned image handle.
///
/// A non-null image returned by this function transfers ownership of that
/// handle to [FlutterImagePool]. The pool will dispose it when it becomes
/// stale, is replaced, is removed from the scene, or the pool is disposed.
typedef FlutterImageDecoder =
    Future<ui.Image?> Function(ImageProvider<Object> provider);

void _dlog(String tag, Object message) {
  if (!kDebugMode) return;

  debugPrint('[${DateTime.now().toIso8601String()}][$tag] $message');
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
  ) async {
    if (_disposed || sourceRefs.isEmpty) {
      return const <String, String>{};
    }

    final imageResolver = resolver;

    // Without a host resolver, logical source refs are assumed to already be
    // renderable by this Flutter host.
    if (imageResolver == null) {
      return Map<String, String>.unmodifiable(<String, String>{
        for (final sourceRef in sourceRefs) sourceRef: sourceRef,
      });
    }

    try {
      final resolvedByRef = await imageResolver.resolveSources(
        sourceRefs.toList(growable: false),
      );

      if (_disposed) {
        return const <String, String>{};
      }

      final result = <String, String>{};

      for (final sourceRef in sourceRefs) {
        final resolved = resolvedByRef[sourceRef]?.trim();

        if (resolved != null && resolved.isNotEmpty) {
          result[sourceRef] = resolved;
        }
      }

      return Map<String, String>.unmodifiable(result);
    } catch (error, stackTrace) {
      if (!_disposed) {
        _dlog('POOL_SOURCE', 'resolver exception=$error\n$stackTrace');
      }

      return const <String, String>{};
    }
  }

  Future<void> _primeMetaCache(Set<String> sourceRefs) async {
    final imageResolver = resolver;

    if (_disposed || sourceRefs.isEmpty || imageResolver == null) {
      return;
    }

    final missing = <String>[
      for (final ref in sourceRefs)
        if (!_metaCache.containsKey(ref)) ref,
    ];

    if (missing.isEmpty) return;

    try {
      final resolvedByRef = await imageResolver.resolveIntrinsicSizes(missing);

      if (_disposed) return;

      for (final ref in missing) {
        final size = _usableIntrinsicSize(resolvedByRef[ref]);

        if (size != null) {
          _metaCache[ref] = size;
        } else {
          _metaCache.remove(ref);
        }
      }
    } catch (error, stackTrace) {
      if (_disposed) return;

      for (final ref in missing) {
        _metaCache.remove(ref);
      }

      _dlog('POOL_META', 'resolver exception=$error\n$stackTrace');
    }
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
  Future<void> resolveSceneIntrinsics(
    CanvasSceneDocument scene, {
    bool includeHidden = true,
  }) async {
    if (_disposed) return;

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

    await _primeMetaCache(sourceRefs);

    if (!_isCurrentIntrinsicsRequest(generation)) {
      return;
    }

    for (final entry in sourceByElement.entries) {
      final sourceRef = entry.value;
      final size =
          persistedIntrinsicByElement[entry.key] ??
          (sourceRef == null ? null : _metaCache[sourceRef]);

      _setIntrinsicSize(entry.key, size);
    }
  }

  /// Decodes raster images for painting.
  ///
  /// This method never updates intrinsic metadata and therefore never emits
  /// [onIntrinsicUpdated].
  Future<void> preloadScene(
    CanvasSceneDocument scene, {
    int? targetW,
    int? targetH,
    bool includeHidden = true,
  }) async {
    if (_disposed) return;

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

    final renderableSourceByRef = await _resolveRenderableSources(sourceRefs);

    if (!_isCurrentPreloadRequest(generation)) {
      return;
    }

    // Do not fetch optional metadata on the raster critical path. Each image
    // uses persisted or already-cached metadata when available, then falls
    // back to a one-sided decode hint.
    final side = _decodeSide(targetW, targetH);

    await Future.wait([
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
  }

  Future<void> _preloadImageNode(
    ImageNode image, {
    required int generation,
    required int? side,
    required String? sourceRef,
    required String? renderableSource,
    required Size2D? persistedIntrinsic,
  }) async {
    if (!_isCurrentPreloadRequest(generation)) {
      return;
    }

    _dlog(
      'POOL_PRELOAD',
      'el=${image.id} assetId=${image.data.assetId} sourceRef=$sourceRef '
          'renderable="$renderableSource"',
    );

    // When a host resolver is installed, a missing result is authoritative.
    // Without a resolver, _resolveRenderableSources maps sourceRef to itself.
    if (renderableSource == null || renderableSource.isEmpty) {
      _clearDecodedImage(image.id);
      return;
    }

    final meta =
        persistedIntrinsic ??
        (sourceRef == null ? null : _metaCache[sourceRef]);

    final dimensions = _decodeDimsFromMeta(side, meta);

    final loadedKey =
        '$renderableSource@${dimensions.w ?? 0}x${dimensions.h ?? 0}';

    if (_loadedKey[image.id] == loadedKey && _images[image.id] != null) {
      return;
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
        return;
      }

      _dlog(
        'POOL_DECODE',
        'el=${image.id} ok=${decoded != null} key="$loadedKey"',
      );

      if (decoded == null) {
        _clearDecodedImage(image.id);
        return;
      }

      _installDecodedImage(image.id, decoded, loadedKey);
    } catch (error, stackTrace) {
      if (!_isCurrentPreloadRequest(generation)) {
        return;
      }

      _dlog(
        'POOL_DECODE',
        'el=${image.id} exception=$error key="$loadedKey"\n'
            '$stackTrace',
      );

      _clearDecodedImage(image.id);
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
