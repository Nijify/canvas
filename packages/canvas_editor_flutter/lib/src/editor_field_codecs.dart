// Path: oss_packages/canvas_editor_flutter/lib/src/editor_field_codecs.dart

import 'package:canvas_core/canvas_core_runtime.dart' as rt;
import 'package:canvas_editor_flutter/src/editor_api.dart';
import 'package:canvas_editor_flutter/src/editor_edits.dart';
import 'package:canvas_editor_flutter/src/editor_fill.dart'
    show coerceFillForNode;

typedef CommitFn =
    void Function(
      EditorController controller,
      rt.ElementId nodeId,
      Object value,
    );

typedef ReadNodeFn = Object Function(rt.Node node);
typedef ReadSceneFn = Object Function(rt.CanvasSceneDocument scene);

/// Defines read and literal commit behavior for one registered canvas field.
///
/// Field-specific normalization and invariants belong here. Persistent changes
/// produced by a codec should be routed through
/// [EditorController.applyEdit].
class FieldCodec {
  const FieldCodec({
    required this.fallback,
    this.readNode,
    this.readScene,
    required this.commit,
    this.isSceneOnly = false,
  });

  final Object fallback;

  /// Reads from a runtime node in the effective rendered scene.
  final ReadNodeFn? readNode;

  /// Reads from the scene for the kSceneFieldsId pseudo node.
  final ReadSceneFn? readScene;

  /// Applies field-specific policy and routes the resulting persistent mutation
  /// through [EditorController.applyEdit].
  final CommitFn commit;

  /// True when the codec is only valid for kSceneFieldsId.
  final bool isSceneOnly;
}

void _commitNodeUpdate(
  EditorController controller,
  rt.ElementId nodeId,
  rt.Node Function(rt.Node node) update,
) {
  controller.applyEdit(EditorEdits.updateNode(nodeId, update));
}

void _commitFill(
  EditorController controller,
  rt.ElementId nodeId,
  rt.CanvasFill requestedFill,
) {
  _commitNodeUpdate(controller, nodeId, (node) {
    if (node is rt.TextNode) {
      final nextFill = coerceFillForNode(node, requestedFill);
      if (nextFill == node.data.fill) return node;

      return node.copyWith(data: node.data.copyWith(fill: nextFill));
    }

    if (node is rt.IconNode) {
      final nextFill = coerceFillForNode(node, requestedFill);
      if (nextFill == node.data.fill) return node;

      return node.copyWith(data: node.data.copyWith(fill: nextFill));
    }

    if (node is rt.PathNode) {
      final nextFill = coerceFillForNode(node, requestedFill);
      if (nextFill == node.data.fill) return node;

      return node.copyWith(data: node.data.copyWith(fill: nextFill));
    }

    return node;
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
      readNode: (node) => (node as rt.TextNode).data.text,
      commit: (controller, nodeId, value) {
        final text = value as String;

        _commitNodeUpdate(controller, nodeId, (node) {
          if (node is! rt.TextNode) return node;
          if (node.data.text == text) return node;

          return node.copyWith(data: node.data.copyWith(text: text));
        });
      },
    ),

    rt.CanvasFields.textFontFamily: FieldCodec(
      fallback: 'Inter',
      readNode: (node) => (node as rt.TextNode).data.fontFamily,
      commit: (controller, nodeId, value) {
        final fontFamily = value as String;

        _commitNodeUpdate(controller, nodeId, (node) {
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
      readNode: (node) => (node as rt.TextNode).data.fill,
      commit: (controller, nodeId, value) {
        _commitFill(controller, nodeId, value as rt.CanvasFill);
      },
    ),

    rt.CanvasFields.textFontSize: FieldCodec(
      fallback: 28.0,
      readNode: (node) => (node as rt.TextNode).data.fontSize,
      commit: (controller, nodeId, value) {
        final fontSize = value as double;

        _commitNodeUpdate(controller, nodeId, (node) {
          if (node is! rt.TextNode) return node;
          if (node.data.fontSize == fontSize) return node;

          return node.copyWith(data: node.data.copyWith(fontSize: fontSize));
        });
      },
    ),

    rt.CanvasFields.textFontWeight: FieldCodec(
      fallback: 400,
      readNode: (node) => (node as rt.TextNode).data.fontWeight,
      commit: (controller, nodeId, value) {
        final fontWeight = value as int;

        _commitNodeUpdate(controller, nodeId, (node) {
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
      readNode: (node) => (node as rt.TextNode).data.letterSpacing,
      commit: (controller, nodeId, value) {
        final letterSpacing = value as double;

        _commitNodeUpdate(controller, nodeId, (node) {
          if (node is! rt.TextNode) return node;
          if (node.data.letterSpacing == letterSpacing) return node;

          return node.copyWith(
            data: node.data.copyWith(letterSpacing: letterSpacing),
          );
        });
      },
    ),

    rt.CanvasFields.textShadowOffset: FieldCodec(
      fallback: 0.0,
      readNode: (node) => (node as rt.TextNode).data.shadowOffset,
      commit: (controller, nodeId, value) {
        final shadowOffset = value as double;

        _commitNodeUpdate(controller, nodeId, (node) {
          if (node is! rt.TextNode) return node;
          if (node.data.shadowOffset == shadowOffset) return node;

          return node.copyWith(
            data: node.data.copyWith(shadowOffset: shadowOffset),
          );
        });
      },
    ),

    // -------------------------------------------------------------------------
    // Icon
    // -------------------------------------------------------------------------
    rt.CanvasFields.iconRef: FieldCodec(
      fallback: '',
      readNode: (node) => (node as rt.IconNode).data.iconRef,
      commit: (controller, nodeId, value) {
        final iconRef = value as String;

        _commitNodeUpdate(controller, nodeId, (node) {
          if (node is! rt.IconNode) return node;
          if (node.data.iconRef == iconRef) return node;

          return node.copyWith(data: node.data.copyWith(iconRef: iconRef));
        });
      },
    ),

    rt.CanvasFields.iconFill: FieldCodec(
      fallback: const rt.CanvasFill.solid(0xFF111111),
      readNode: (node) => (node as rt.IconNode).data.fill,
      commit: (controller, nodeId, value) {
        _commitFill(controller, nodeId, value as rt.CanvasFill);
      },
    ),

    rt.CanvasFields.iconSizePx: FieldCodec(
      fallback: 48.0,
      readNode: (node) => (node as rt.IconNode).data.sizePx,
      commit: (controller, nodeId, value) {
        final sizePx = value as double;

        _commitNodeUpdate(controller, nodeId, (node) {
          if (node is! rt.IconNode) return node;
          if (node.data.sizePx == sizePx) return node;

          return node.copyWith(data: node.data.copyWith(sizePx: sizePx));
        });
      },
    ),

    rt.CanvasFields.iconShadowOffset: FieldCodec(
      fallback: 0.0,
      readNode: (node) => (node as rt.IconNode).data.shadowOffset,
      commit: (controller, nodeId, value) {
        final shadowOffset = value as double;

        _commitNodeUpdate(controller, nodeId, (node) {
          if (node is! rt.IconNode) return node;
          if (node.data.shadowOffset == shadowOffset) return node;

          return node.copyWith(
            data: node.data.copyWith(shadowOffset: shadowOffset),
          );
        });
      },
    ),

    // -------------------------------------------------------------------------
    // Image
    // -------------------------------------------------------------------------
    rt.CanvasFields.imageSource: FieldCodec(
      fallback: '',
      readNode: (node) => (node as rt.ImageNode).data.sourcePath ?? '',
      commit: (controller, nodeId, value) {
        final requested = value as String;
        final sourcePath = requested.trim().isEmpty ? null : requested;

        _commitNodeUpdate(controller, nodeId, (node) {
          if (node is! rt.ImageNode) return node;
          if (node.data.sourcePath == sourcePath) return node;

          return node.copyWith(
            data: node.data.copyWith(sourcePath: sourcePath),
          );
        });
      },
    ),

    rt.CanvasFields.imageWidthPx: FieldCodec(
      fallback: 200.0,
      readNode: (node) {
        final size = (node as rt.ImageNode).data.size;
        return (size?.w ?? 200.0).toDouble();
      },
      commit: (controller, nodeId, value) {
        final width = value as double;

        _commitNodeUpdate(controller, nodeId, (node) {
          if (node is! rt.ImageNode) return node;

          final effectiveSize = node.data.size ?? const rt.Size2D(200, 200);

          // Do not materialize the nullable fallback for an unchanged value.
          if (effectiveSize.w == width) return node;

          return node.copyWith(
            data: node.data.copyWith(size: rt.Size2D(width, effectiveSize.h)),
          );
        });
      },
    ),

    rt.CanvasFields.imageHeightPx: FieldCodec(
      fallback: 200.0,
      readNode: (node) {
        final size = (node as rt.ImageNode).data.size;
        return (size?.h ?? 200.0).toDouble();
      },
      commit: (controller, nodeId, value) {
        final height = value as double;

        _commitNodeUpdate(controller, nodeId, (node) {
          if (node is! rt.ImageNode) return node;

          final effectiveSize = node.data.size ?? const rt.Size2D(200, 200);

          // Do not materialize the nullable fallback for an unchanged value.
          if (effectiveSize.h == height) return node;

          return node.copyWith(
            data: node.data.copyWith(size: rt.Size2D(effectiveSize.w, height)),
          );
        });
      },
    ),

    // -------------------------------------------------------------------------
    // Path
    // -------------------------------------------------------------------------
    rt.CanvasFields.pathFill: FieldCodec(
      fallback: const rt.CanvasFill.none(),
      readNode: (node) => (node as rt.PathNode).data.fill,
      commit: (controller, nodeId, value) {
        _commitFill(controller, nodeId, value as rt.CanvasFill);
      },
    ),

    // -------------------------------------------------------------------------
    // Scene pseudo-node fields
    // -------------------------------------------------------------------------
    rt.CanvasFields.sceneBackgroundFill: FieldCodec(
      fallback: const rt.CanvasFill.none(),
      isSceneOnly: true,
      readScene: (scene) => scene.backgroundFill,
      commit: (controller, _, value) {
        final fill = value as rt.CanvasFill;

        controller.applyEdit(
          EditorEdits.updateScene((scene) {
            if (scene.backgroundFill == fill) return scene;
            return scene.copyWith(backgroundFill: fill);
          }),
        );
      },
    ),

    rt.CanvasFields.sceneBackgroundOpacity: FieldCodec(
      fallback: 1.0,
      isSceneOnly: true,
      readScene: (scene) => scene.backgroundOpacity,
      commit: (controller, _, value) {
        final opacity = value as double;

        controller.applyEdit(
          EditorEdits.updateScene((scene) {
            if (scene.backgroundOpacity == opacity) return scene;
            return scene.copyWith(backgroundOpacity: opacity);
          }),
        );
      },
    ),
  };
}
