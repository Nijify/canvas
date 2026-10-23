// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/actions/base_add_actions.dart
//
// Base/basic add actions.
//
// This file intentionally now contributes normal EditorActionSpec values instead
// of maintaining a separate add-menu/add-handler pipeline.

import 'dart:math' as math;

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

const RectSource _rect = RectSource(x: -80, y: -50, width: 160, height: 100);
const RectSource _roundRect = RectSource(
  x: -90,
  y: -55,
  width: 180,
  height: 110,
  rx: 16,
  ry: 16,
);
const RectSource _pill = RectSource(
  x: -110,
  y: -30,
  width: 220,
  height: 60,
  rx: (60) / 2,
  ry: (60) / 2,
);
const CircleSource _circle = CircleSource(60);
const EllipseSource _ellipse = EllipseSource(100, 60);
const LineSource _line = LineSource(x1: -110, y1: 0, x2: 110, y2: 0);
final PolylineSource _polyline = PolylineSource(const [
  Vec2(-80, 20),
  Vec2(0, -20),
  Vec2(80, 20),
]);
final PolygonSource _polygon = _polygonPreset(6, 64, 64, 0);
final PolygonSource _star = _polygonPreset(10, 72, 36, -90);

PolygonSource _polygonPreset(
  int vertices,
  double outer,
  double inner,
  double degrees,
) => PolygonSource([
  for (var i = 0; i < vertices; i++)
    Vec2(
      (i.isEven ? outer : inner) *
          math.cos(degrees * math.pi / 180 + i * 2 * math.pi / vertices),
      (i.isEven ? outer : inner) *
          math.sin(degrees * math.pi / 180 + i * 2 * math.pi / vertices),
    ),
]);

PathNode _buildBasePath(PathSource src, {String? role, String? idOverride}) {
  return PathNode(
    id: idOverride ?? _genBaseAddId('path'),
    data: PathData(
      source: src,
      appearance: CanvasAppearance(
        foreground: (src is LineSource || src is PolylineSource)
            ? const CanvasFill.none()
            : const CanvasFill.solid(_baseFill),
        stroke: CanvasStroke(
          color: _baseStroke,
          width: src is LineSource ? 6 : _baseStrokeW,
        ),
      ),
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
        appearance: const CanvasAppearance(
          foreground: CanvasFill.solid(_baseFill),
        ),
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
    id: EditorActionIds.addPolyline,
    label: 'Polyline',
    icon: Icons.timeline,
    priority: 15,
    menuGroup: _addMenuGroupShapes,
    invoke: (ctx) => _addBaseShape(ctx, source: _polyline),
  ),
  _addAction(
    id: EditorActionIds.addLine,
    label: 'Line',
    icon: Icons.border_bottom,
    priority: 10,
    menuGroup: _addMenuGroupShapes,
    invoke: (ctx) => _addBaseShape(ctx, source: _line),
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
