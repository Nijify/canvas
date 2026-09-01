// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/actions/base_add_actions.dart
//
// Base/basic add actions.
//
// This file intentionally now contributes normal EditorActionSpec values instead
// of maintaining a separate add-menu/add-handler pipeline.

import 'package:flutter/material.dart';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/presentation/actions/editor_actions.dart';

int _baseAddSeq = 0;

String _genBaseAddId(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_baseAddSeq++}';

const _baseFill = 0xFF22C55E;
const _baseStroke = 0xFF111111;
const _baseStrokeW = 2.0;

const _addMenuGroupShapes = 'Shapes';

const _textPos = Vec2(120, 220);
const _shapePos = Vec2(60, 60);

const RectSource _rect = RectSource(160, 100);
const RoundRectSource _roundRect = RoundRectSource(180, 110, 16, 16);
const PillSource _pill = PillSource(220, 60);
const CircleSource _circle = CircleSource(60);
const EllipseSource _ellipse = EllipseSource(100, 60);
const UnderlineSource _underline = UnderlineSource(220, 6);
const RegularPolygonSource _polygon = RegularPolygonSource(6, 64, rotation: 0);
const StarSource _star = StarSource(5, 72, 36, rotation: -90);

PathNode _buildBasePath(PathSource src, {String? role, String? idOverride}) {
  return PathNode(
    id: idOverride ?? _genBaseAddId('path'),
    data: PathData(
      points: const <Vec2?>[],
      fill: CanvasFill.solid(_baseFill),
      strokeColor: _baseStroke,
      strokeWidth: _baseStrokeW,
      source: src,
    ),
    xf: const Transform2D(position: _shapePos),
    role: role,
  );
}

void _addBaseShape(EditorActionContext ctx, {required PathSource source}) {
  ctx.addNodeAndSelect(_buildBasePath(source));
}

String? _configuredTextFontFamily(EditorActionContext ctx) {
  for (final item in ctx.resources.pickerFonts) {
    final family = item.family.trim();

    if (family.isNotEmpty) {
      return family;
    }
  }

  for (final rawFamily in ctx.resources.fonts.fallbackFontFamilies) {
    final family = rawFamily.trim();

    if (family.isNotEmpty) {
      return family;
    }
  }

  return null;
}

void _addBaseText(EditorActionContext ctx) {
  final fontFamily = _configuredTextFontFamily(ctx);

  if (fontFamily == null) {
    ctx.ui.toast('No text font is configured.');
    return;
  }

  ctx.addNodeAndSelect(
    TextNode(
      id: _genBaseAddId('text'),
      data: TextData(
        text: 'Your text',
        fontFamily: fontFamily,
        fontWeight: 700,
        fontSize: 32,
        letterSpacing: 0,
        fill: CanvasFill.solid(_baseFill),
        shadowOffset: 0,
      ),
      xf: const Transform2D(position: _textPos),
    ),
  );
}

final List<EditorActionSpec> baseAddActions = [
  _addAction(
    id: EditorActionIds.addText,
    label: 'Text',
    icon: Icons.text_fields,
    priority: 100,
    invoke: _addBaseText,
  ),
  _addAction(
    id: EditorActionIds.addRect,
    label: 'Rectangle',
    icon: Icons.check_box_outline_blank,
    priority: 80,
    menuGroup: _addMenuGroupShapes,
    invoke: (ctx) => _addBaseShape(ctx, source: _rect),
  ),
  _addAction(
    id: EditorActionIds.addCircle,
    label: 'Circle',
    icon: Icons.circle_outlined,
    priority: 70,
    menuGroup: _addMenuGroupShapes,
    invoke: (ctx) => _addBaseShape(ctx, source: _circle),
  ),
  _addAction(
    id: EditorActionIds.addRoundRect,
    label: 'Rounded Rectangle',
    icon: Icons.crop_3_2,
    priority: 60,
    menuGroup: _addMenuGroupShapes,
    invoke: (ctx) => _addBaseShape(ctx, source: _roundRect),
  ),
  _addAction(
    id: EditorActionIds.addPill,
    label: 'Pill',
    icon: Icons.rectangle_rounded,
    priority: 50,
    menuGroup: _addMenuGroupShapes,
    invoke: (ctx) => _addBaseShape(ctx, source: _pill),
  ),
  _addAction(
    id: EditorActionIds.addEllipse,
    label: 'Ellipse',
    icon: Icons.tonality,
    priority: 40,
    menuGroup: _addMenuGroupShapes,
    invoke: (ctx) => _addBaseShape(ctx, source: _ellipse),
  ),
  _addAction(
    id: EditorActionIds.addStar,
    label: 'Star',
    icon: Icons.star_border,
    priority: 30,
    menuGroup: _addMenuGroupShapes,
    invoke: (ctx) => _addBaseShape(ctx, source: _star),
  ),
  _addAction(
    id: EditorActionIds.addPolygon,
    label: 'Polygon',
    icon: Icons.change_history,
    priority: 20,
    menuGroup: _addMenuGroupShapes,
    invoke: (ctx) => _addBaseShape(ctx, source: _polygon),
  ),
  _addAction(
    id: EditorActionIds.addUnderline,
    label: 'Underline',
    icon: Icons.border_bottom,
    priority: 10,
    menuGroup: _addMenuGroupShapes,
    invoke: (ctx) => _addBaseShape(ctx, source: _underline),
  ),
];

EditorActionSpec _addAction({
  required EditorActionId id,
  required String label,
  required IconData icon,
  required EditorActionInvoke invoke,
  int priority = 0,
  String? menuGroup,
}) {
  return EditorActionSpec(
    id: id,
    section: EditorToolbarSection.add,
    labelBuilder: (_) => label,
    iconBuilder: (_) => icon,
    isEnabled: (_) => true,
    isVisible: (_) => true,
    priority: priority,
    menuGroup: menuGroup,
    invoke: invoke,
  );
}
