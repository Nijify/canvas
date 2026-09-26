// Path: packages/canvas_editor_flutter/lib/src/editor_field_codecs.dart

import 'package:canvas_core/canvas_core_runtime.dart' as rt;
import 'package:canvas_editor_flutter/src/editor_fill.dart'
    show coerceFillForNode;

typedef ReadNodeFn =
    Object Function(rt.CanvasSceneDocument scene, rt.Node node);

typedef ReadSceneFn = Object Function(rt.CanvasSceneDocument scene);

typedef CanReadCanonicalNodeFn =
    bool Function(rt.CanvasSceneDocument scene, rt.Node node);

typedef ReadCanonicalNodeFn =
    Object Function(rt.CanvasSceneDocument scene, rt.Node node);

typedef ReadCanonicalSceneFn = Object Function(rt.CanvasSceneDocument scene);

typedef WriteCanonicalFn =
    rt.CanvasSceneDocument Function(
      rt.CanvasSceneDocument base,
      rt.ElementId nodeId,
      Object value,
    );

/// Defines presentation reads and canonical mutation behavior for one
/// registered canvas field.
///
/// [readNode] and [readScene] are presentation readers. They may read resolved
/// or otherwise effective runtime state and are used by `getField()`.
///
/// Canonical mutation uses [readCanonicalNode] or [readCanonicalScene] together
/// with [writeCanonical]. Canonical writers transform the supplied base scene
/// and return the result. They must not start another editor commit.
class FieldCodec {
  const FieldCodec({
    required this.fallback,
    this.readNode,
    this.readScene,
    this.canReadCanonicalNode,
    this.readCanonicalNode,
    this.readCanonicalScene,
    required this.writeCanonical,
    this.isSceneOnly = false,
  });

  final Object fallback;

  /// Presentation read from a runtime node and its effective scene context.
  final ReadNodeFn? readNode;

  /// Presentation read for a scene-level field.
  final ReadSceneFn? readScene;

  /// Returns whether this node is a valid canonical target for the field.
  ///
  /// Node-field codecs must provide this together with [readCanonicalNode].
  final CanReadCanonicalNodeFn? canReadCanonicalNode;

  /// Reads the persisted/canonical value from the canonical base scene.
  ///
  /// This is intentionally separate from [readNode]; canonical updates must
  /// never derive their starting value from presentation state.
  final ReadCanonicalNodeFn? readCanonicalNode;

  /// Reads the persisted/canonical value for a scene-level field.
  ///
  /// Scene-only codecs must provide this.
  final ReadCanonicalSceneFn? readCanonicalScene;

  /// Applies field-specific normalization and canonical storage behavior.
  ///
  /// This transforms [base] and returns the resulting canonical scene.
  /// It must not call `applyEdit()`, `commitField()`, `updateField()`, or
  /// otherwise initiate another commit.
  final WriteCanonicalFn writeCanonical;

  /// True when this codec is valid only for the scene-fields pseudo target.
  final bool isSceneOnly;
}

rt.CanvasSceneDocument _writeNodeUpdate(
  rt.CanvasSceneDocument base,
  rt.ElementId nodeId,
  rt.Node Function(rt.Node node) update,
) {
  final node = rt.findById(base, nodeId);
  if (node == null) return base;

  final nextNode = update(node);

  if (identical(nextNode, node) || nextNode == node) {
    return base;
  }

  return rt.replaceById(base, nodeId, nextNode);
}

rt.CanvasSceneDocument _writeFill(
  rt.CanvasSceneDocument base,
  rt.ElementId nodeId,
  rt.CanvasFill requestedFill,
) {
  return _writeNodeUpdate(base, nodeId, (node) {
    if (node is rt.TextNode) {
      final nextFill = coerceFillForNode(node, requestedFill);
      final current = node.data.appearance.foreground;

      if (nextFill == current) return node;

      return node.copyWith(
        data: node.data.copyWith(
          appearance: node.data.appearance.copyWith(foreground: nextFill),
        ),
      );
    }

    if (node is rt.IconNode) {
      final nextFill = coerceFillForNode(node, requestedFill);
      final current = node.data.appearance.foreground;

      if (nextFill == current) return node;

      return node.copyWith(
        data: node.data.copyWith(
          appearance: node.data.appearance.copyWith(foreground: nextFill),
        ),
      );
    }

    if (node is rt.PathNode) {
      final nextFill = coerceFillForNode(node, requestedFill);

      if (nextFill == node.data.fill) return node;

      return node.copyWith(data: node.data.copyWith(fill: nextFill));
    }

    return node;
  });
}

bool _sameUnderlays(
  List<rt.CanvasSourceUnderlay> left,
  List<rt.CanvasSourceUnderlay> right,
) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;

  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }

  return true;
}

rt.CanvasSceneDocument _writeTextUnderlays(
  rt.CanvasSceneDocument base,
  rt.ElementId nodeId,
  List<rt.CanvasSourceUnderlay> requestedUnderlays,
) {
  return _writeNodeUpdate(base, nodeId, (node) {
    if (node is! rt.TextNode) return node;

    final currentUnderlays = node.data.appearance.underlays;

    if (_sameUnderlays(currentUnderlays, requestedUnderlays)) {
      return node;
    }

    final nextUnderlays = List<rt.CanvasSourceUnderlay>.unmodifiable(
      requestedUnderlays,
    );

    return node.copyWith(
      data: node.data.copyWith(
        appearance: node.data.appearance.copyWith(underlays: nextUnderlays),
      ),
    );
  });
}

rt.CanvasSceneDocument _writeIconUnderlays(
  rt.CanvasSceneDocument base,
  rt.ElementId nodeId,
  List<rt.CanvasSourceUnderlay> requestedUnderlays,
) {
  return _writeNodeUpdate(base, nodeId, (node) {
    if (node is! rt.IconNode) return node;

    final currentUnderlays = node.data.appearance.underlays;

    if (_sameUnderlays(currentUnderlays, requestedUnderlays)) {
      return node;
    }

    final nextUnderlays = List<rt.CanvasSourceUnderlay>.unmodifiable(
      requestedUnderlays,
    );

    return node.copyWith(
      data: node.data.copyWith(
        appearance: node.data.appearance.copyWith(underlays: nextUnderlays),
      ),
    );
  });
}

// -----------------------------------------------------------------------------
// Field registry
// -----------------------------------------------------------------------------

class FieldCatalog {
  static FieldCodec of(
    rt.CanvasFieldKey id, {
    Map<rt.CanvasFieldKey, FieldCodec> extra =
        const <rt.CanvasFieldKey, FieldCodec>{},
  }) {
    final codec = extra[id] ?? _codecs[id];

    if (codec == null) {
      throw StateError('Missing FieldCodec for $id');
    }

    return codec;
  }

  static final Map<rt.CanvasFieldKey, FieldCodec> _codecs = {
    // -------------------------------------------------------------------------
    // Text
    // -------------------------------------------------------------------------
    rt.CanvasFields.textContent: FieldCodec(
      fallback: '',
      readNode: (_, node) => (node as rt.TextNode).data.text,
      canReadCanonicalNode: (_, node) => node is rt.TextNode,
      readCanonicalNode: (_, node) => (node as rt.TextNode).data.text,
      writeCanonical: (base, nodeId, value) {
        final text = value as String;

        return _writeNodeUpdate(base, nodeId, (node) {
          if (node is! rt.TextNode) return node;
          if (node.data.text == text) return node;

          return node.copyWith(data: node.data.copyWith(text: text));
        });
      },
    ),

    rt.CanvasFields.textFontFamily: FieldCodec(
      fallback: 'Inter',
      readNode: (_, node) => (node as rt.TextNode).data.fontFamily,
      canReadCanonicalNode: (_, node) => node is rt.TextNode,
      readCanonicalNode: (_, node) => (node as rt.TextNode).data.fontFamily,
      writeCanonical: (base, nodeId, value) {
        final fontFamily = value as String;

        return _writeNodeUpdate(base, nodeId, (node) {
          if (node is! rt.TextNode) return node;
          if (node.data.fontFamily == fontFamily) return node;

          return node.copyWith(
            data: node.data.copyWith(fontFamily: fontFamily),
          );
        });
      },
    ),

    rt.CanvasFields.textFill: FieldCodec(
      fallback: const rt.CanvasFill.solid(0xFF111111),
      readNode: (_, node) => (node as rt.TextNode).data.appearance.foreground,
      canReadCanonicalNode: (_, node) => node is rt.TextNode,
      readCanonicalNode: (_, node) =>
          (node as rt.TextNode).data.appearance.foreground,
      writeCanonical: (base, nodeId, value) {
        return _writeFill(base, nodeId, value as rt.CanvasFill);
      },
    ),

    rt.CanvasFields.textUnderlays: FieldCodec(
      fallback: const <rt.CanvasSourceUnderlay>[],
      readNode: (_, node) => (node as rt.TextNode).data.appearance.underlays,
      canReadCanonicalNode: (_, node) => node is rt.TextNode,
      readCanonicalNode: (_, node) =>
          (node as rt.TextNode).data.appearance.underlays,
      writeCanonical: (base, nodeId, value) {
        return _writeTextUnderlays(
          base,
          nodeId,
          value as List<rt.CanvasSourceUnderlay>,
        );
      },
    ),

    rt.CanvasFields.textFontSize: FieldCodec(
      fallback: 28.0,
      readNode: (_, node) => (node as rt.TextNode).data.fontSize,
      canReadCanonicalNode: (_, node) => node is rt.TextNode,
      readCanonicalNode: (_, node) => (node as rt.TextNode).data.fontSize,
      writeCanonical: (base, nodeId, value) {
        final fontSize = value as double;

        return _writeNodeUpdate(base, nodeId, (node) {
          if (node is! rt.TextNode) return node;
          if (node.data.fontSize == fontSize) return node;

          return node.copyWith(data: node.data.copyWith(fontSize: fontSize));
        });
      },
    ),

    rt.CanvasFields.textFontWeight: FieldCodec(
      fallback: 400,
      readNode: (_, node) => (node as rt.TextNode).data.fontWeight,
      canReadCanonicalNode: (_, node) => node is rt.TextNode,
      readCanonicalNode: (_, node) => (node as rt.TextNode).data.fontWeight,
      writeCanonical: (base, nodeId, value) {
        final fontWeight = value as int;

        return _writeNodeUpdate(base, nodeId, (node) {
          if (node is! rt.TextNode) return node;
          if (node.data.fontWeight == fontWeight) return node;

          return node.copyWith(
            data: node.data.copyWith(fontWeight: fontWeight),
          );
        });
      },
    ),

    rt.CanvasFields.textLetterSpacing: FieldCodec(
      fallback: 0.0,
      readNode: (_, node) => (node as rt.TextNode).data.letterSpacing,
      canReadCanonicalNode: (_, node) => node is rt.TextNode,
      readCanonicalNode: (_, node) => (node as rt.TextNode).data.letterSpacing,
      writeCanonical: (base, nodeId, value) {
        final letterSpacing = value as double;

        return _writeNodeUpdate(base, nodeId, (node) {
          if (node is! rt.TextNode) return node;
          if (node.data.letterSpacing == letterSpacing) return node;

          return node.copyWith(
            data: node.data.copyWith(letterSpacing: letterSpacing),
          );
        });
      },
    ),

    // -------------------------------------------------------------------------
    // Icon
    // -------------------------------------------------------------------------
    rt.CanvasFields.iconRef: FieldCodec(
      fallback: '',
      readNode: (_, node) => (node as rt.IconNode).data.iconRef,
      canReadCanonicalNode: (_, node) => node is rt.IconNode,
      readCanonicalNode: (_, node) => (node as rt.IconNode).data.iconRef,
      writeCanonical: (base, nodeId, value) {
        final iconRef = value as String;

        return _writeNodeUpdate(base, nodeId, (node) {
          if (node is! rt.IconNode) return node;
          if (node.data.iconRef == iconRef) return node;

          return node.copyWith(data: node.data.copyWith(iconRef: iconRef));
        });
      },
    ),

    rt.CanvasFields.iconFill: FieldCodec(
      fallback: const rt.CanvasFill.solid(0xFF111111),
      readNode: (_, node) => (node as rt.IconNode).data.appearance.foreground,
      canReadCanonicalNode: (_, node) => node is rt.IconNode,
      readCanonicalNode: (_, node) =>
          (node as rt.IconNode).data.appearance.foreground,
      writeCanonical: (base, nodeId, value) {
        return _writeFill(base, nodeId, value as rt.CanvasFill);
      },
    ),

    rt.CanvasFields.iconUnderlays: FieldCodec(
      fallback: const <rt.CanvasSourceUnderlay>[],
      readNode: (_, node) => (node as rt.IconNode).data.appearance.underlays,
      canReadCanonicalNode: (_, node) => node is rt.IconNode,
      readCanonicalNode: (_, node) =>
          (node as rt.IconNode).data.appearance.underlays,
      writeCanonical: (base, nodeId, value) {
        return _writeIconUnderlays(
          base,
          nodeId,
          value as List<rt.CanvasSourceUnderlay>,
        );
      },
    ),

    rt.CanvasFields.iconSizePx: FieldCodec(
      fallback: 48.0,
      readNode: (_, node) => (node as rt.IconNode).data.sizePx,
      canReadCanonicalNode: (_, node) => node is rt.IconNode,
      readCanonicalNode: (_, node) => (node as rt.IconNode).data.sizePx,
      writeCanonical: (base, nodeId, value) {
        final sizePx = value as double;

        return _writeNodeUpdate(base, nodeId, (node) {
          if (node is! rt.IconNode) return node;
          if (node.data.sizePx == sizePx) return node;

          return node.copyWith(data: node.data.copyWith(sizePx: sizePx));
        });
      },
    ),

    // -------------------------------------------------------------------------
    // Image
    // -------------------------------------------------------------------------
    rt.CanvasFields.imageSource: FieldCodec(
      fallback: '',
      readNode: (scene, node) {
        final image = node as rt.ImageNode;
        final assetId = image.data.assetId;

        return assetId == null ? '' : scene.assets[assetId]?.sourceRef ?? '';
      },
      canReadCanonicalNode: (_, node) => node is rt.ImageNode,
      readCanonicalNode: (scene, node) {
        final image = node as rt.ImageNode;
        final assetId = image.data.assetId;

        return assetId == null ? '' : scene.assets[assetId]?.sourceRef ?? '';
      },
      writeCanonical: (base, nodeId, value) {
        final requested = value as String;
        final sourceRef = requested.trim().isEmpty ? null : requested;

        final node = rt.findById(base, nodeId);
        if (node is! rt.ImageNode) return base;

        final currentAssetId = node.data.assetId;
        final currentSourceRef = currentAssetId == null
            ? null
            : base.assets[currentAssetId]?.sourceRef;

        if (sourceRef == null) {
          if (currentAssetId == null) return base;

          return rt.replaceById(
            base,
            nodeId,
            node.copyWith(data: node.data.copyWith(assetId: null)),
          );
        }

        if (currentSourceRef == sourceRef) {
          return base;
        }

        final assetId = _nextImageAssetId(base, nodeId);

        final nextBase = base.copyWith(
          assets: <rt.CanvasAssetId, rt.CanvasImageAsset>{
            ...base.assets,
            assetId: rt.CanvasImageAsset(sourceRef: sourceRef),
          },
        );

        return rt.replaceById(
          nextBase,
          nodeId,
          node.copyWith(data: node.data.copyWith(assetId: assetId)),
        );
      },
    ),

    rt.CanvasFields.imageWidthPx: FieldCodec(
      fallback: 200.0,
      readNode: (_, node) => (node as rt.ImageNode).data.size.w.toDouble(),
      canReadCanonicalNode: (_, node) => node is rt.ImageNode,
      readCanonicalNode: (_, node) =>
          (node as rt.ImageNode).data.size.w.toDouble(),
      writeCanonical: (base, nodeId, value) {
        final width = value as double;

        return _writeNodeUpdate(base, nodeId, (node) {
          if (node is! rt.ImageNode) return node;

          final size = node.data.size;
          if (size.w == width) return node;

          return node.copyWith(
            data: node.data.copyWith(size: rt.Size2D(width, size.h)),
          );
        });
      },
    ),

    rt.CanvasFields.imageHeightPx: FieldCodec(
      fallback: 200.0,
      readNode: (_, node) => (node as rt.ImageNode).data.size.h.toDouble(),
      canReadCanonicalNode: (_, node) => node is rt.ImageNode,
      readCanonicalNode: (_, node) =>
          (node as rt.ImageNode).data.size.h.toDouble(),
      writeCanonical: (base, nodeId, value) {
        final height = value as double;

        return _writeNodeUpdate(base, nodeId, (node) {
          if (node is! rt.ImageNode) return node;

          final size = node.data.size;
          if (size.h == height) return node;

          return node.copyWith(
            data: node.data.copyWith(size: rt.Size2D(size.w, height)),
          );
        });
      },
    ),

    // -------------------------------------------------------------------------
    // Path
    // -------------------------------------------------------------------------
    rt.CanvasFields.pathFill: FieldCodec(
      fallback: const rt.CanvasFill.none(),
      readNode: (_, node) => (node as rt.PathNode).data.fill,
      canReadCanonicalNode: (_, node) => node is rt.PathNode,
      readCanonicalNode: (_, node) => (node as rt.PathNode).data.fill,
      writeCanonical: (base, nodeId, value) {
        return _writeFill(base, nodeId, value as rt.CanvasFill);
      },
    ),

    // -------------------------------------------------------------------------
    // Scene pseudo-node fields
    // -------------------------------------------------------------------------
    rt.CanvasFields.sceneBackgroundFill: FieldCodec(
      fallback: const rt.CanvasFill.none(),
      isSceneOnly: true,
      readScene: (scene) => scene.backgroundFill,
      readCanonicalScene: (scene) => scene.backgroundFill,
      writeCanonical: (base, _, value) {
        final fill = value as rt.CanvasFill;

        if (base.backgroundFill == fill) {
          return base;
        }

        return base.copyWith(backgroundFill: fill);
      },
    ),

    rt.CanvasFields.sceneBackgroundOpacity: FieldCodec(
      fallback: 1.0,
      isSceneOnly: true,
      readScene: (scene) => scene.backgroundOpacity,
      readCanonicalScene: (scene) => scene.backgroundOpacity,
      writeCanonical: (base, _, value) {
        final opacity = value as double;

        if (base.backgroundOpacity == opacity) {
          return base;
        }

        return base.copyWith(backgroundOpacity: opacity);
      },
    ),
  };
}

int _imageAssetSequence = 0;

rt.CanvasAssetId _nextImageAssetId(
  rt.CanvasSceneDocument scene,
  rt.ElementId nodeId,
) {
  while (true) {
    final candidate =
        '${nodeId}_asset_${DateTime.now().microsecondsSinceEpoch}_'
        '${_imageAssetSequence++}';

    if (!scene.assets.containsKey(candidate)) {
      return candidate;
    }
  }
}
