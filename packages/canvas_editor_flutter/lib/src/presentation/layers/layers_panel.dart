// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/layers/layers_panel.dart

import 'package:canvas_core/canvas_core_runtime.dart' show CanvasSceneDocument;
import 'package:canvas_editor_flutter/src/editor_api.dart'
    show EditorController;
import 'package:canvas_editor_flutter/src/editor_edits.dart' show EditorEdits;
import 'package:canvas_editor_flutter/src/presentation/layers/scene_object_tree.dart'
    show
        SceneObjectKind,
        SceneObjectPresentationPolicy,
        SceneObjectRow,
        SceneObjectTreeBuilder;
import 'package:canvas_editor_flutter/src/editor_hosts.dart'
    show EditorSelectionHost;
import 'package:flutter/material.dart';

class LayersPanel extends StatelessWidget {
  const LayersPanel({
    super.key,
    required this.controller,
    required this.selection,
    this.policy = const SceneObjectPresentationPolicy(),
    this.title = 'Layers',
  });

  final EditorController controller;
  final EditorSelectionHost selection;
  final SceneObjectPresentationPolicy policy;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.7)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LayersHeader(title: title),
          Expanded(
            child: ValueListenableBuilder<CanvasSceneDocument>(
              valueListenable: controller.document,
              builder: (context, scene, _) {
                return ValueListenableBuilder(
                  valueListenable: selection,
                  builder: (context, selectionState, _) {
                    final rows = SceneObjectTreeBuilder(
                      policy: policy,
                    ).build(scene: scene);

                    if (rows.isEmpty) {
                      return const _LayersEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        final selected = selectionState.ids.contains(
                          row.selectionId,
                        );

                        return _LayerRow(
                          row: row,
                          selected: selected,
                          onTap: row.locked
                              ? null
                              : () => selection.selectItems([
                                  row.selectionId,
                                ], additive: false),
                          onRename: () => _showRenameDialog(context, row),
                          // Layer visibility is persisted through Node.hidden.
                          onToggleHidden: () {
                            controller.applyEdit(
                              EditorEdits.setElementHidden(row.id, !row.hidden),
                            );
                          },
                          onToggleLocked: () {
                            controller.applyEdit(
                              EditorEdits.setElementLocked(row.id, !row.locked),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    SceneObjectRow row,
  ) async {
    final nextName = await showDialog<String>(
      context: context,
      builder: (context) {
        return _RenameLayerDialog(initialName: row.label);
      },
    );

    if (nextName == null) return;

    controller.applyEdit(EditorEdits.renameElement(row.id, nextName));
  }
}

class _RenameLayerDialog extends StatefulWidget {
  const _RenameLayerDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameLayerDialog> createState() => _RenameLayerDialogState();
}

class _RenameLayerDialogState extends State<_RenameLayerDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename layer'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 80,
        decoration: const InputDecoration(
          labelText: 'Layer name',
          hintText: 'Enter a layer name',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Rename')),
      ],
    );
  }
}

class _LayersHeader extends StatelessWidget {
  const _LayersHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.7)),
        ),
      ),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LayersEmptyState extends StatelessWidget {
  const _LayersEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'No layers yet',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _LayerRow extends StatelessWidget {
  const _LayerRow({
    required this.row,
    required this.selected,
    required this.onTap,
    required this.onRename,
    required this.onToggleHidden,
    required this.onToggleLocked,
  });

  final SceneObjectRow row;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback onRename;
  final VoidCallback onToggleHidden;
  final VoidCallback onToggleLocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final selectedColor = theme.colorScheme.primaryContainer.withValues(
      alpha: 0.72,
    );

    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      color: row.locked
          ? theme.colorScheme.onSurfaceVariant
          : theme.colorScheme.onSurface,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Material(
        color: selected ? selectedColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          onDoubleTap: onRename,
          child: SizedBox(
            height: 36,
            child: Row(
              children: [
                SizedBox(width: 8 + row.depth * 16.0),
                Icon(
                  _kindIcon(row.kind),
                  size: 17,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    row.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                ),
                IconButton(
                  tooltip: row.hidden ? 'Show layer' : 'Hide layer',
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: onToggleHidden,
                  icon: Icon(
                    row.hidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
                IconButton(
                  tooltip: row.locked ? 'Unlock layer' : 'Lock layer',
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: onToggleLocked,
                  icon: Icon(
                    row.locked ? Icons.lock_outline : Icons.lock_open_outlined,
                  ),
                ),
                IconButton(
                  tooltip: 'Rename layer',
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: onRename,
                  icon: const Icon(Icons.drive_file_rename_outline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _kindIcon(SceneObjectKind kind) {
  return switch (kind) {
    SceneObjectKind.text => Icons.text_fields,
    SceneObjectKind.image => Icons.image_outlined,
    SceneObjectKind.path => Icons.category_outlined,
    SceneObjectKind.icon => Icons.star_outline,
    SceneObjectKind.group => Icons.folder_open_outlined,
    SceneObjectKind.unknown => Icons.layers_outlined,
  };
}
