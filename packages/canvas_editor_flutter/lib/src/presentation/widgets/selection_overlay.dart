// Path: packages/canvas_editor_flutter/lib/src/presentation/widgets/selection_overlay.dart

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:canvas_editor_flutter/src/interaction/transform_gesture.dart';

import 'package:canvas_core/canvas_core_runtime.dart' as rt;
import 'package:canvas_editor_flutter/src/editor_api.dart';

class CanvasSelectionOverlay extends StatefulWidget {
  final rt.SceneEvaluation render;
  final double scale;
  final Offset pan;
  final rt.ElementId selectedId;

  const CanvasSelectionOverlay({
    super.key,
    required this.render,
    required this.scale,
    required this.pan,
    required this.selectedId,
  });

  @override
  State<CanvasSelectionOverlay> createState() => _CanvasSelectionOverlayState();
}

class _CanvasSelectionOverlayState extends State<CanvasSelectionOverlay> {
  TransformGesture? _rotation;
  TransformGesture? _scaling;
  rt.Vec2? _anchor;
  rt.Vec2? _axis;
  double? _startValue;

  rt.Vec2? _toWorld(BuildContext overlay, Offset global) {
    final box = overlay.findRenderObject();
    if (box is! RenderBox || widget.scale <= 0) return null;
    final point = box.globalToLocal(global);
    return rt.Vec2((point.dx - widget.pan.dx) / widget.scale,
        (point.dy - widget.pan.dy) / widget.scale);
  }

  void _close() {
    _rotation?.close(); _scaling?.close();
    _rotation = null; _scaling = null;
    _anchor = null; _axis = null; _startValue = null;
  }

  @override
  void didUpdateWidget(covariant CanvasSelectionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) _close();
  }

  @override
  void dispose() { _close(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final computed = widget.render.computed;
    final id = widget.selectedId;
    final world = computed.worldById[id];
    final bounds = computed.layoutBoundsLocalById[id];
    if (world == null || bounds == null) return const SizedBox.shrink();
    final corners = rt.transformedRectCorners(bounds, world);
    final center = world.transformPoint(rt.Vec2(
      bounds.left / 2 + bounds.right / 2, bounds.top / 2 + bounds.bottom / 2));
    Offset screen(rt.Vec2 p) => Offset(p.x * widget.scale + widget.pan.dx,
        p.y * widget.scale + widget.pan.dy);
    final points = corners.map(screen).toList(growable: false);
    final topMid = (points[0] + points[1]) / 2;
    final edge = points[1] - points[0];
    var normal = Offset(edge.dy, -edge.dx);
    final outward = topMid - screen(center);
    if (normal.dx * outward.dx + normal.dy * outward.dy < 0) normal = -normal;
    final direction = normal.distance == 0 ? const Offset(0, -1) : normal / normal.distance;
    final rotateHandle = topMid + direction * 24;
    final controller = context.read<EditorController>();
    final handles = <int>[];
    for (var i = 0; i < points.length; i++) {
      if (!handles.any((j) => (points[i] - points[j]).distance < 0.01)) handles.add(i);
    }
    const radius = 10.0;
    return Positioned.fill(child: Builder(builder: (overlay) => Stack(children: [
      IgnorePointer(child: CustomPaint(painter: _SelectionPainter(points, rotateHandle, radius))),
      _handle(overlay, rotateHandle, radius, keyName: 'canvas-rotate-handle',
        start: (pointer) {
          _close();
          _rotation = TransformGesture.start(controller, id);
          if (_rotation == null) return;
          final initial = _rotation!.evaluation.computed;
          final box = initial.layoutBoundsLocalById[id]!;
          final frame = initial.worldById[id]!;
          _anchor = frame.transformPoint(rt.Vec2(box.left / 2 + box.right / 2,
            box.top / 2 + box.bottom / 2));
          _startValue = math.atan2(pointer.y - _anchor!.y, pointer.x - _anchor!.x);
        },
        move: (pointer) {
          final anchor = _anchor, start = _startValue;
          if (anchor == null || start == null || _rotation == null) return;
          final angle = math.atan2(pointer.y - anchor.y, pointer.x - anchor.x) - start;
          _rotation!.applyWorldDelta(rt.affineAround(anchor, rt.Affine2D.rotation(angle)));
        },
      ),
      for (final i in handles)
        _handle(overlay, points[i], radius, keyName: 'canvas-scale-handle-$i',
          start: (pointer) {
            _close();
            _scaling = TransformGesture.start(controller, id);
            if (_scaling == null) return;
            final initial = _scaling!.evaluation.computed;
            final quad = rt.transformedRectCorners(initial.layoutBoundsLocalById[id]!,
              initial.worldById[id]!);
            final anchor = quad[(i + 2) % 4];
            final axis = quad[i] - anchor;
            if (axis.length <= 1e-6) { _close(); return; }
            _anchor = anchor; _axis = axis / axis.length;
            final delta = pointer - anchor;
            final projection = delta.x * _axis!.x + delta.y * _axis!.y;
            if (projection.abs() <= 1e-6) { _close(); return; }
            _startValue = projection;
          },
          move: (pointer) {
            final anchor = _anchor, axis = _axis, start = _startValue;
            if (anchor == null || axis == null || start == null || _scaling == null) return;
            final delta = pointer - anchor;
            // Uniform positive corner sizing; zero-crossing is not an implicit mirror tool.
            final factor = ((delta.x * axis.x + delta.y * axis.y) / start).clamp(0.02, 50.0).toDouble();
            _scaling!.applyWorldDelta(rt.affineAround(anchor, rt.Affine2D.scale(factor)));
          },
        ),
    ])));
  }

  Widget _handle(BuildContext overlay, Offset center, double radius, {
    required String keyName,
    required void Function(rt.Vec2) start,
    required void Function(rt.Vec2) move,
  }) => Positioned(
    left: center.dx - radius, top: center.dy - radius,
    width: radius * 2, height: radius * 2,
    child: Listener(
      key: ValueKey(keyName), behavior: HitTestBehavior.opaque,
      onPointerDown: (event) { final p = _toWorld(overlay, event.position); if (p != null) start(p); },
      onPointerMove: (event) { final p = _toWorld(overlay, event.position); if (p != null) move(p); },
      onPointerUp: (_) => _close(), onPointerCancel: (_) => _close(),
      child: DecoratedBox(decoration: BoxDecoration(
        color: Colors.white, shape: BoxShape.circle,
        border: Border.all(color: Colors.blueAccent, width: 1.5))),
    ),
  );
}

class _SelectionPainter extends CustomPainter {
  final List<Offset> corners; // TL, TR, BR, BL in screen space
  final Offset handleCenter;
  final double handleR;

  _SelectionPainter(this.corners, this.handleCenter, this.handleR)
    : assert(corners.length == 4);

  @override
  void paint(Canvas canvas, Size size) {
    const base = Color(0xFF3B82F6);
    final fill = Paint()
      ..color = base.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = base
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(corners[0].dx, corners[0].dy)
      ..lineTo(corners[1].dx, corners[1].dy)
      ..lineTo(corners[2].dx, corners[2].dy)
      ..lineTo(corners[3].dx, corners[3].dy)
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);

    final line = Paint()
      ..color = base
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final topMid = Offset(
      (corners[0].dx + corners[1].dx) / 2,
      (corners[0].dy + corners[1].dy) / 2,
    );
    canvas.drawLine(topMid, handleCenter, line);

    final w = Paint()..color = Colors.white;
    canvas.drawCircle(handleCenter, handleR, w);
    canvas.drawCircle(handleCenter, handleR, stroke);
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter old) {
    return !listEquals(old.corners, corners) ||
        old.handleCenter != handleCenter ||
        old.handleR != handleR;
  }
}
