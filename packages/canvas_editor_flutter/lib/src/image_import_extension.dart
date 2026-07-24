// Path: oss_packages/canvas_editor_flutter/lib/src/image_import_extension.dart
import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/editor_extensions.dart';
import 'package:canvas_editor_flutter/src/editor_surface_features.dart';
import 'package:canvas_editor_flutter/src/image_import.dart';
import 'package:canvas_editor_flutter/src/presentation/actions/editor_actions.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector.dart'
    show ImageInspectorPanel;
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_fields.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_ui.dart';
import 'package:flutter/material.dart';

const _initialImageTopLeft = Vec2(80, 80);
const _initialImageSize = Size2D(200, 200);

int _imageImportAddSequence = 0;

/// Opt-in user-image acquisition for an editor surface.
///
/// This feature owns:
/// - Gallery / camera acquisition
/// - Replacement-source UI
/// - Add Image action
/// - Durable source reference validation
///
/// Core canvas editing remains usable without this extension.
EditorExtension<TSourceDocument> imageImportExtension<TSourceDocument>({
  required ImageImportPort imageImport,
}) {
  return _ImageImportExtension<TSourceDocument>(imageImport: imageImport);
}

class _ImageImportExtension<TSourceDocument>
    extends EditorExtension<TSourceDocument> {
  _ImageImportExtension({required this.imageImport});

  final ImageImportPort imageImport;

  bool _isAdding = false;
  bool _isDisposed = false;
  VoidCallback? _requestRebuild;

  @override
  void attach(EditorExtensionContext<TSourceDocument> context) {
    _requestRebuild = context.requestRebuild;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _requestRebuild = null;
  }

  void _requestSurfaceRebuild() {
    if (_isDisposed) return;
    _requestRebuild?.call();
  }

  @override
  EditorSurfaceFeatures get surfaceFeatures {
    return EditorSurfaceFeatures(
      inspectorBuilder: (context) {
        final selected =
            context.selectedRenderedNode ?? context.selectedEditableNode;

        if (selected is! ImageNode) return null;

        return ImageInspectorPanel(
          nodeId: selected.id,
          inspector: context,
          sourceControls: context.fieldRow<String>(
            selected.id,
            _imageSourceSpec(imageImport: imageImport),
          ),
        );
      },
    );
  }

  @override
  List<EditorActionSpec> get actionSpecs {
    return <EditorActionSpec>[
      EditorActionSpec(
        id: EditorActionIds.addImage,
        section: EditorToolbarSection.add,
        labelBuilder: (_) => 'Image',
        iconBuilder: (_) => Icons.image_outlined,
        isEnabled: (_) => !_isAdding,
        isVisible: (_) => true,
        priority: 90,
        invoke: _addImage,
      ),
    ];
  }

  Future<void> _addImage(EditorActionContext context) async {
    if (_isAdding) return;

    _isAdding = true;
    _requestSurfaceRebuild();

    try {
      final source = await _chooseImageImportSource(context.buildContext);
      if (source == null) return;

      final sourceRef = await _requestDurableImageSourceRef(
        imageImport: imageImport,
        source: source,
        onFailure: (message) {
          if (!context.buildContext.mounted) return;
          context.ui.toast('Failed to add image: $message');
        },
      );

      if (sourceRef == null || !context.buildContext.mounted) return;

      context.addNodeAndSelect(_buildImportedImage(sourceRef));
    } finally {
      _isAdding = false;
      _requestSurfaceRebuild();
    }
  }

  ImageNode _buildImportedImage(String sourceRef) {
    final position = Vec2(
      _initialImageTopLeft.x + _initialImageSize.w * 0.5,
      _initialImageTopLeft.y + _initialImageSize.h * 0.5,
    );

    return ImageNode(
      id: _nextImageId(),
      data: ImageData(size: _initialImageSize, sourcePath: sourceRef),
      xf: Transform2D(position: position),
    );
  }

  String _nextImageId() {
    return 'img_${DateTime.now().microsecondsSinceEpoch}_'
        '${_imageImportAddSequence++}';
  }
}

InspectorFieldSpec<String> _imageSourceSpec({
  required ImageImportPort imageImport,
}) {
  return InspectorFieldSpec<String>(
    fieldKey: CanvasFields.imageSource,
    title: 'Source',
    commitMode: CommitMode.immediate,
    control:
        (
          context, {
          required enabled,
          required value,
          required commit,
          begin,
          end,
          flush,
        }) {
          final label = value.trim().isEmpty ? '(none)' : value;

          return _ImageSourcePickerControl(
            enabled: enabled,
            currentSourceLabel: label,
            imageImport: imageImport,
            commitSourceRef: commit,
          );
        },
  );
}

class _ImageSourcePickerControl extends StatefulWidget {
  const _ImageSourcePickerControl({
    required this.enabled,
    required this.currentSourceLabel,
    required this.imageImport,
    required this.commitSourceRef,
  });

  final bool enabled;
  final String currentSourceLabel;
  final ImageImportPort imageImport;
  final ValueChanged<String> commitSourceRef;

  @override
  State<_ImageSourcePickerControl> createState() =>
      _ImageSourcePickerControlState();
}

class _ImageSourcePickerControlState extends State<_ImageSourcePickerControl> {
  bool _isImporting = false;

  Future<void> _import(ImageImportSource source) async {
    if (!widget.enabled || _isImporting) return;

    setState(() => _isImporting = true);

    try {
      final sourceRef = await _requestDurableImageSourceRef(
        imageImport: widget.imageImport,
        source: source,
        onFailure: (message) {
          if (!mounted) return;
          _showFailure(message);
        },
      );

      if (!mounted || sourceRef == null) return;

      widget.commitSourceRef(sourceRef);
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _showFailure(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to replace image: $message')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && !_isImporting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Current source: ${widget.currentSourceLabel}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        InspectorActionGroup(
          children: <Widget>[
            Tooltip(
              message: 'Pick from gallery',
              child: ElevatedButton.icon(
                key: const ValueKey('image-import-replace-gallery'),
                onPressed: enabled
                    ? () => _import(ImageImportSource.gallery)
                    : null,
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ),
            Tooltip(
              message: 'Capture from camera',
              child: ElevatedButton.icon(
                key: const ValueKey('image-import-replace-camera'),
                onPressed: enabled
                    ? () => _import(ImageImportSource.camera)
                    : null,
                icon: const Icon(Icons.photo_camera),
                label: const Text('Camera'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.enabled)
          const Text(
            'Selected images are prepared by this app before being added '
            'to the design.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
      ],
    );
  }
}

Future<ImageImportSource?> _chooseImageImportSource(BuildContext context) {
  return showModalBottomSheet<ImageImportSource>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Add image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ListTile(
              key: const ValueKey('image-import-add-gallery'),
              leading: const Icon(Icons.photo_library),
              title: const Text('Pick from gallery'),
              onTap: () {
                Navigator.of(sheetContext).pop(ImageImportSource.gallery);
              },
            ),
            ListTile(
              key: const ValueKey('image-import-add-camera'),
              leading: const Icon(Icons.photo_camera),
              title: const Text('Capture from camera'),
              onTap: () {
                Navigator.of(sheetContext).pop(ImageImportSource.camera);
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('image-import-add-cancel'),
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<String?> _requestDurableImageSourceRef({
  required ImageImportPort imageImport,
  required ImageImportSource source,
  required void Function(String message) onFailure,
}) async {
  ImageImportResult result;

  try {
    result = await imageImport.importImage(source: source);
  } catch (_) {
    onFailure('Unable to import image. Please try again.');
    return null;
  }

  if (result.cancelled) return null;

  final sourceRef = result.sourceRef;
  final errorMessage = result.errorMessage?.trim();

  if (sourceRef == null || sourceRef.trim().isEmpty || errorMessage != null) {
    onFailure(
      errorMessage == null || errorMessage.isEmpty
          ? 'No usable image reference was returned.'
          : errorMessage,
    );
    return null;
  }

  return sourceRef;
}
