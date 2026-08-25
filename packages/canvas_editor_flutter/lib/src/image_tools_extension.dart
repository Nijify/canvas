import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/editor_api.dart'
    show EditorController;
import 'package:canvas_editor_flutter/src/editor_extensions.dart'
    show EditorExtension;
import 'package:canvas_editor_flutter/src/editor_surface_features.dart'
    show EditorSurfaceFeatures;
import 'package:canvas_editor_flutter/src/image_tools.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_context.dart'
    show InspectorContext;
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_ui.dart'
    show Gap, HintText;
import 'package:flutter/material.dart';

const _removeBackgroundButtonKey = ValueKey('remove-background-button');

/// Adds host-owned background removal to the standard Image inspector.
///
/// This extension owns:
///
/// - Image-selection applicability;
/// - runtime editability presentation;
/// - canonical/effective source validation;
/// - asynchronous target and stale-result protection;
/// - mutation through `CanvasFields.imageSource`;
/// - editor feedback.
///
/// The supplied [port] owns the actual image processing and persistence.
EditorExtension<TSourceDocument> backgroundRemovalExtension<TSourceDocument>({
  required BackgroundRemovalPort port,
}) {
  return _BackgroundRemovalExtension<TSourceDocument>(port: port);
}

final class _BackgroundRemovalExtension<TSourceDocument>
    extends EditorExtension<TSourceDocument> {
  const _BackgroundRemovalExtension({required this.port});

  final BackgroundRemovalPort port;

  @override
  EditorSurfaceFeatures get surfaceFeatures {
    return EditorSurfaceFeatures(inspectorSections: [_buildInspectorSection]);
  }

  Widget? _buildInspectorSection(InspectorContext context) {
    final editable = context.selectedEditableNode;

    // Destructive image transformations operate on canonical ImageNode state.
    if (editable is! ImageNode) {
      return null;
    }

    final rendered = context.selectedRenderedNode;

    // Do not place Image tools inside an inspector whose prepared node has
    // become another node type.
    if (rendered != null && rendered is! ImageNode) {
      return null;
    }

    return _BackgroundRemovalSection(
      key: ValueKey('background-removal-section:${editable.id}'),
      controller: context.controller,
      nodeId: editable.id,
      port: port,
    );
  }
}

final class _BackgroundRemovalSection extends StatelessWidget {
  const _BackgroundRemovalSection({
    super.key,
    required this.controller,
    required this.nodeId,
    required this.port,
  });

  final EditorController controller;
  final ElementId nodeId;
  final BackgroundRemovalPort port;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Image tools', style: Theme.of(context).textTheme.titleSmall),
        const Gap(8),
        _BackgroundRemovalControl(
          key: ValueKey('background-removal-control:$nodeId'),
          controller: controller,
          nodeId: nodeId,
          port: port,
        ),
      ],
    );
  }
}

final class _BackgroundRemovalControl extends StatefulWidget {
  const _BackgroundRemovalControl({
    super.key,
    required this.controller,
    required this.nodeId,
    required this.port,
  });

  final EditorController controller;
  final ElementId nodeId;
  final BackgroundRemovalPort port;

  @override
  State<_BackgroundRemovalControl> createState() =>
      _BackgroundRemovalControlState();
}

final class _BackgroundRemovalControlState
    extends State<_BackgroundRemovalControl> {
  bool _isRemoving = false;

  _BackgroundRemovalAvailability _availability(
    EditorController controller,
    ElementId nodeId,
  ) {
    final canonicalScene = controller.document.value;
    final canonicalNode = findById(canonicalScene, nodeId);

    if (canonicalNode is! ImageNode) {
      return const _BackgroundRemovalAvailability.disabled(
        'The selected image is unavailable.',
      );
    }

    final renderedNode = findById(controller.render.value.scene, nodeId);

    if (renderedNode != null && renderedNode is! ImageNode) {
      return const _BackgroundRemovalAvailability.disabled(
        'This image cannot be transformed in its current rendered state.',
      );
    }

    final canonicalSource = _sourceRefForImage(
      canonicalScene,
      canonicalNode,
    )?.trim();

    if (canonicalSource == null || canonicalSource.isEmpty) {
      return const _BackgroundRemovalAvailability.disabled(
        'This image has no usable source.',
      );
    }

    final fieldState = controller.getField<String>(
      nodeId,
      CanvasFields.imageSource,
    );

    final fieldDisabledReason = fieldState.disabledReason?.trim();

    if (fieldDisabledReason != null && fieldDisabledReason.isNotEmpty) {
      return _BackgroundRemovalAvailability.disabled(fieldDisabledReason);
    }

    final effectiveSource = fieldState.value.trim();

    if (effectiveSource != canonicalSource) {
      return const _BackgroundRemovalAvailability.disabled(
        'This image source is resolved at runtime and cannot be '
        'transformed directly.',
      );
    }

    return _BackgroundRemovalAvailability.enabled(
      canonicalSourceRef: canonicalSource,
      effectiveSourceRef: effectiveSource,
    );
  }

  Future<void> _removeBackground() async {
    if (_isRemoving) {
      return;
    }

    final controller = widget.controller;
    final targetNodeId = widget.nodeId;

    final original = _availability(controller, targetNodeId);

    if (!original.enabled) {
      return;
    }

    final originalCanonicalSource = original.canonicalSourceRef!;
    final originalEffectiveSource = original.effectiveSourceRef!;

    setState(() {
      _isRemoving = true;
    });

    try {
      final BackgroundRemovalResult result;

      try {
        result = await widget.port.removeBackground(
          sourceRef: originalCanonicalSource,
        );
      } catch (_) {
        if (mounted) {
          _showMessage('Unable to remove the background. Please try again.');
        }
        return;
      }

      if (!mounted) {
        return;
      }

      // A State created for one target must never adopt a result for another.
      if (widget.controller != controller || widget.nodeId != targetNodeId) {
        return;
      }

      if (result is BackgroundRemovalFailure) {
        _showMessage(_failureMessage(result));
        return;
      }

      final success = result as BackgroundRemovalSuccess;
      final replacementSourceRef = success.sourceRef.trim();

      if (replacementSourceRef.isEmpty ||
          replacementSourceRef == originalCanonicalSource) {
        _showMessage(
          'Background removal did not return a usable replacement image.',
        );
        return;
      }

      final latest = _availability(controller, targetNodeId);

      if (!latest.enabled) {
        // If the target is still mounted but became non-editable, surface the
        // current editor-owned reason rather than pretending the host failed.
        final reason = latest.disabledReason;

        if (reason != null && reason.isNotEmpty) {
          _showMessage(reason);
        }

        return;
      }

      // The canonical source must still be exactly the source this operation
      // started from.
      if (latest.canonicalSourceRef != originalCanonicalSource) {
        _showMessage('The image changed while background removal was running.');
        return;
      }

      // Preserve the explicit canonical/effective invariant after the await.
      if (latest.effectiveSourceRef != originalEffectiveSource) {
        _showMessage('The image changed while background removal was running.');
        return;
      }

      controller.commitField<String>(
        targetNodeId,
        CanvasFields.imageSource,
        replacementSourceRef,
      );

      // commitField is intentionally void and may reject a stale or denied
      // target. Verify canonical adoption before reporting success.
      final committedScene = controller.document.value;
      final committedNode = findById(committedScene, targetNodeId);

      final committedSource = committedNode is ImageNode
          ? _sourceRefForImage(committedScene, committedNode)?.trim()
          : null;

      if (committedSource != replacementSourceRef) {
        _showMessage(
          'The image could not be updated because its editing state changed.',
        );
        return;
      }

      _showMessage('Background removed.');
    } finally {
      if (mounted) {
        setState(() {
          _isRemoving = false;
        });
      }
    }
  }

  String _failureMessage(BackgroundRemovalFailure failure) {
    final hostMessage = failure.message?.trim();

    if (hostMessage != null && hostMessage.isNotEmpty) {
      return hostMessage;
    }

    return switch (failure.kind) {
      BackgroundRemovalFailureKind.unsupported =>
        'Background removal is not supported for this image.',
      BackgroundRemovalFailureKind.temporarilyUnavailable =>
        'Background removal is temporarily unavailable. Please try again '
            'shortly.',
      BackgroundRemovalFailureKind.failed =>
        'Unable to remove the background. Please try again.',
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final availability = _availability(widget.controller, widget.nodeId);

    final enabled = !_isRemoving && availability.enabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          key: _removeBackgroundButtonKey,
          onPressed: enabled ? _removeBackground : null,
          icon: _isRemoving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_fix_high),
          label: Text(
            _isRemoving ? 'Removing background…' : 'Remove background',
          ),
        ),
        if (!_isRemoving && availability.disabledReason != null) ...[
          const Gap(6),
          HintText(availability.disabledReason!),
        ],
      ],
    );
  }
}

String? _sourceRefForImage(CanvasSceneDocument scene, ImageNode image) {
  final assetId = image.data.assetId;
  return assetId == null ? null : scene.assets[assetId]?.sourceRef;
}

final class _BackgroundRemovalAvailability {
  const _BackgroundRemovalAvailability.enabled({
    required this.canonicalSourceRef,
    required this.effectiveSourceRef,
  }) : disabledReason = null;

  const _BackgroundRemovalAvailability.disabled(this.disabledReason)
    : canonicalSourceRef = null,
      effectiveSourceRef = null;

  final String? canonicalSourceRef;
  final String? effectiveSourceRef;
  final String? disabledReason;

  bool get enabled =>
      disabledReason == null &&
      canonicalSourceRef != null &&
      effectiveSourceRef != null;
}
