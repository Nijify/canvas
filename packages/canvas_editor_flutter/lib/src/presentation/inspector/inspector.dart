// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/inspector/inspector.dart

import 'package:flutter/material.dart';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/canvas_runtime_resources.dart'
    show CanvasRuntimeResources;
import 'package:canvas_editor_flutter/src/editor_api.dart'
    show EditorController, kSceneFieldsId;
import 'package:canvas_editor_flutter/src/editor_hosts.dart'
    show EditorSelectionHost;
import 'package:canvas_editor_flutter/src/presentation/inspector/fill_editor.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_context.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_field_row.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_fields.dart';
import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_ui.dart';

Widget _defaultInspectorFieldRowBuilder<T>(
  ElementId nodeId,
  EditorController controller,
  InspectorFieldSpec<T> spec,
) {
  return InspectorFieldRow<T>(
    nodeId: nodeId,
    controller: controller,
    spec: spec,
  );
}

Widget _buildInspectorPanel({
  required String title,
  required List<Widget> children,
}) {
  return InspectorCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(title), const Gap(8), ...children],
    ),
  );
}

Widget _buildBackgroundPanel({required InspectorContext inspector}) {
  return _buildInspectorPanel(
    title: 'Background',
    children: [
      FillEditor(
        nodeId: kSceneFieldsId,
        inspector: inspector,
        ids: FillFieldIds.background,
        header: null,
      ),
      const Gap(12),
      inspector.fieldRow<double>(
        kSceneFieldsId,
        doubleSliderSpec(
          fieldKey: CanvasFields.sceneBackgroundOpacity,
          title: 'Opacity',
          uiLabel: 'Opacity',
          min: 0,
          max: 1,
          fraction: true,
        ),
      ),
    ],
  );
}

/// Intrinsic base-scene inspector.
///
/// Optional feature builders get the first opportunity to handle the current
/// selection. Returning null delegates to this complete base inspector.
Widget buildSceneInspector(InspectorContext inspector) {
  final selectionState = inspector.selection.value;

  if (selectionState.hasItems && selectionState.ids.length > 1) {
    return const InspectorCard(child: Text('Multiple objects selected'));
  }

  if (!selectionState.hasItems) {
    return _buildBackgroundPanel(inspector: inspector);
  }

  final selectedId = inspector.selectedId;
  if (selectedId == null) {
    return _buildBackgroundPanel(inspector: inspector);
  }

  // Preserve the previous rendered-scene dispatch behavior, while falling back
  // to the canonical node when a custom render pipeline omits the selected node.
  final selected =
      inspector.selectedRenderedNode ?? inspector.selectedEditableNode;

  if (selected == null) {
    return const InspectorCard(child: Text('Selected object is unavailable'));
  }

  return switch (selected) {
    TextNode node => TextInspectorPanel(nodeId: node.id, inspector: inspector),
    ImageNode node => ImageInspectorPanel(
      nodeId: node.id,
      inspector: inspector,
    ),
    PathNode node => _buildPathPanel(inspector: inspector, nodeId: node.id),
    IconNode node => IconInspectorPanel(nodeId: node.id, inspector: inspector),
    _ => const InspectorCard(child: Text('No editable properties')),
  };
}

class TextInspectorPanel extends StatelessWidget {
  const TextInspectorPanel({
    super.key,
    required this.nodeId,
    required this.inspector,
  });

  final ElementId nodeId;
  final InspectorContext inspector;

  @override
  Widget build(BuildContext context) {
    final fonts = inspector.resources.fonts.pickerFonts;

    return _buildInspectorPanel(
      title: 'Text',
      children: [
        inspector.fieldRow<String>(nodeId, textContentSpec()),
        const Gap(12),
        inspector.fieldRow<String>(nodeId, textFontFamilySpec(fonts: fonts)),
        const Gap(12),
        inspector.fieldRow<double>(nodeId, textFontSizeSpec()),
        inspector.fieldRow<double>(nodeId, textLetterSpacingSpec()),
        inspector.fieldRow<int>(nodeId, textBoldSpec()),
        const Gap(12),
        FillEditor(
          nodeId: nodeId,
          inspector: inspector,
          ids: FillFieldIds.text,
          header: 'Fill',
        ),
        const Gap(12),
        inspector.fieldRow<double>(nodeId, textShadowOffsetSpec()),
      ],
    );
  }
}

class ImageInspectorPanel extends StatelessWidget {
  const ImageInspectorPanel({
    super.key,
    required this.nodeId,
    required this.inspector,
    this.sourceControls,
  });

  final ElementId nodeId;
  final InspectorContext inspector;
  final Widget? sourceControls;

  @override
  Widget build(BuildContext context) {
    return _buildInspectorPanel(
      title: 'Image',
      children: [
        if (sourceControls != null) ...[sourceControls!, const Gap(12)],
        ImageGeometryInspectorControls(nodeId: nodeId, inspector: inspector),
      ],
    );
  }
}

/// Source-independent image layout controls.
///
/// This is intentionally not a full inspector panel or an [InspectorCard].
/// It can be embedded by the base Image inspector and importer-owned panels.
class ImageGeometryInspectorControls extends StatelessWidget {
  const ImageGeometryInspectorControls({
    super.key,
    required this.nodeId,
    required this.inspector,
  });

  final ElementId nodeId;
  final InspectorContext inspector;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        inspector.fieldRow<double>(
          nodeId,
          doubleSliderSpec(
            fieldKey: CanvasFields.imageWidthPx,
            title: 'Width',
            uiLabel: 'Width',
            min: 10,
            max: 900,
          ),
        ),
        const Gap(8),
        inspector.fieldRow<double>(
          nodeId,
          doubleSliderSpec(
            fieldKey: CanvasFields.imageHeightPx,
            title: 'Height',
            uiLabel: 'Height',
            min: 10,
            max: 900,
          ),
        ),
      ],
    );
  }
}

class IconInspectorPanel extends StatelessWidget {
  const IconInspectorPanel({
    super.key,
    required this.nodeId,
    required this.inspector,
  });

  final ElementId nodeId;
  final InspectorContext inspector;

  @override
  Widget build(BuildContext context) {
    final catalogItems = inspector.resources.icons.items;

    return _buildInspectorPanel(
      title: 'Icon',
      children: [
        inspector.fieldRow<String>(nodeId, iconRefSpec(icons: catalogItems)),
        if (catalogItems.isEmpty) ...[
          const Gap(8),
          const HintText('No icons available.'),
        ],
        const Gap(12),
        inspector.fieldRow<double>(
          nodeId,
          doubleSliderSpec(
            fieldKey: CanvasFields.iconSizePx,
            title: 'Size',
            uiLabel: 'Size',
            min: 16,
            max: 200,
          ),
        ),
        const Gap(12),
        FillEditor(
          nodeId: nodeId,
          inspector: inspector,
          ids: FillFieldIds.icon,
          header: 'Fill',
        ),
        const Gap(12),
        inspector.fieldRow<double>(
          nodeId,
          doubleSliderSpec(
            fieldKey: CanvasFields.iconShadowOffset,
            title: 'Shadow Offset',
            uiLabel: 'Shadow Offset',
            min: 0,
            max: 20,
          ),
        ),
      ],
    );
  }
}

Widget _buildPathPanel({
  required InspectorContext inspector,
  required ElementId nodeId,
}) {
  return _buildInspectorPanel(
    title: 'Path',
    children: [
      const Gap(4),
      FillEditor(
        nodeId: nodeId,
        inspector: inspector,
        ids: FillFieldIds.path,
        header: 'Fill',
      ),
    ],
  );
}

class Inspector extends StatelessWidget {
  const Inspector({
    super.key,
    required this.renderSnapshot,
    required this.controller,
    required this.selection,
    required this.resources,
    this.builder,
    this.compact = false,
    this.fieldRowBuilder,
  });

  final RenderSnapshot renderSnapshot;
  final EditorController controller;

  final EditorSelectionHost selection;
  final CanvasRuntimeResources resources;

  final InspectorBuilder? builder;
  final bool compact;
  final InspectorFieldRowBuilder? fieldRowBuilder;

  @override
  Widget build(BuildContext context) {
    final selectionState = selection.value;

    final selectedId = selectionState.hasItems && selectionState.ids.length == 1
        ? selectionState.ids.single
        : null;

    final inspectorContext = InspectorContext(
      selectedId: selectedId,
      selection: selection,
      controller: controller,
      editableScene: controller.document.value,
      renderedScene: renderSnapshot.scene,
      resources: resources,
      fieldRowBuilder: fieldRowBuilder ?? _defaultInspectorFieldRowBuilder,
    );

    final panel =
        builder?.call(inspectorContext) ??
        buildSceneInspector(inspectorContext);

    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 8 : 12),
      child: panel,
    );
  }
}
