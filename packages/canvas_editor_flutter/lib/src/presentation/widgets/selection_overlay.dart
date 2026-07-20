// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/widgets/selection_overlay.dart

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import 'package:canvas_core/canvas_core_runtime.dart' as rt;
import 'package:canvas_editor_flutter/src/editor_api.dart';

class CanvasSelectionOverlay extends StatefulWidget {
  final rt.RenderSnapshot render;
  final double scale;
  final Offset pan;
  final Set<String> selectedIds;

  const CanvasSelectionOverlay({
    super.key,
    required this.render,
    required this.scale,
    required this.pan,
    required this.selectedIds,
  });

  @override
  State<CanvasSelectionOverlay> createState() => _CanvasSelectionOverlayState();
}

class _CanvasSelectionOverlayState extends State<CanvasSelectionOverlay> {
  double? _lastAngle;

  VoidCallback? _endRotateSession;
  VoidCallback? _endScaleSession;
  EditorController? _sessionController;

  // ---- Scale gesture state (single-select) ----
  // IMPORTANT:
  // EditorRuntime.updateUniformScaleAround() applies `mul` incrementally
  // (it multiplies current scale by mul). Therefore we MUST send a mul-step
  // each pointer move (currT / prevT), NOT an absolute mul-from-start.
  rt.Vec2? _scaleAnchorWorld; // opposite corner in WORLD space
  rt.Vec2? _scaleAxisWorld; // unit vector from anchor -> grabbed handle (WORLD)
  double?
  _scalePrevT; // previous signed distance along axis (baseline for steps)

  /// Current pivot (world). Updated from geometry when not dragging.
  rt.Vec2 _centerWorld = const rt.Vec2(0, 0);

  /// Cached pivot for the active gesture to avoid rebuild-jitter.
  rt.Vec2? _gesturePivotWorld;

  rt.Vec2 get _pivotWorld => _gesturePivotWorld ?? _centerWorld;

  rt.Vec2 _screenToWorld(Offset local) => rt.Vec2(
    (local.dx - widget.pan.dx) / widget.scale,
    (local.dy - widget.pan.dy) / widget.scale,
  );

  rt.Vec2 _globalToWorld(BuildContext overlayCtx, Offset global) {
    final ro = overlayCtx.findRenderObject();
    if (ro is! RenderBox) return const rt.Vec2(0, 0);
    final local = ro.globalToLocal(global); // global -> overlay local
    return _screenToWorld(local);
  }

  double _angleFromPivot(rt.Vec2 pivot, rt.Vec2 p) =>
      math.atan2(p.y - pivot.y, p.x - pivot.x);

  double _normalizeDelta(double a) => math.atan2(math.sin(a), math.cos(a));

  double _dot(rt.Vec2 a, rt.Vec2 b) => a.x * b.x + a.y * b.y;

  rt.Vec2 _transformPoint(vm.Matrix4 m, rt.Vec2 p) {
    final v = m.transform3(vm.Vector3(p.x, p.y, 0));
    return rt.Vec2(v.x, v.y);
  }

  vm.Matrix4 _inverseOrIdentity(vm.Matrix4 m) {
    final inv = vm.Matrix4.copy(m);
    final det = inv.invert();
    if (det == 0) return vm.Matrix4.identity();
    return inv;
  }

  void _closeRotateSession() {
    final endSession = _endRotateSession;
    if (endSession == null) return;

    _endRotateSession = null;
    endSession();
  }

  void _closeScaleSession() {
    final endSession = _endScaleSession;
    if (endSession == null) return;

    _endScaleSession = null;
    endSession();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final controller = context.read<EditorController>();

    if (!identical(_sessionController, controller)) {
      _closeRotateSession();
      _closeScaleSession();
      _sessionController = controller;
    }
  }

  @override
  void dispose() {
    _closeRotateSession();
    _closeScaleSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ids = widget.selectedIds;
    if (ids.isEmpty) return const SizedBox.shrink();

    final controller = context.read<EditorController>();
    final scene = widget.render.scene;
    final computed = widget.render.computed;

    final isMulti = ids.length > 1;

    // ------------------------------------------------------------------
    // TEMP (UX): Multi-select rotate/scale is disabled.
    //
    // Why:
    // - Current transform ops update only rotation/scale (in-place).
    // - They do NOT compensate position around a shared pivot/anchor.
    // - Result: UI implies a group transform, but nodes “spin/scale in place”.
    //
    // What still works:
    // - Multi-select drag remains enabled (handled in CanvasViewport).
    //
    // Future:
    // - Implement group transform math (rotate/scale ABOUT a shared pivot with
    //   per-node position compensation), then re-enable these handles.
    // ------------------------------------------------------------------
    final bool disableMultiTransform = isMulti;

    // Editable if the node exists in the RUNTIME scene.
    final editableIds = ids
        .where((id) => rt.findById(scene, id) != null)
        .toList(growable: false);
    if (editableIds.isEmpty) return const SizedBox.shrink();

    // ------------------------------------------------------------------
    // Geometry
    // - Single-select: oriented quad from local bounds transformed by world matrix
    //   (so the blue box rotates with the object).
    // - Multi-select: AABB union (current behavior) for visuals only.
    // ------------------------------------------------------------------
    rt.Vec2 pivotWorld;
    List<rt.Vec2> cornersWorld; // TL, TR, BR, BL in world

    if (!isMulti) {
      final id = editableIds.first;
      final node = rt.findById(scene, id);
      final world = computed.worldById[id];
      final lb = computed.localBoundsById[id];

      if (node == null || world == null || lb == null) {
        return const SizedBox.shrink();
      }

      // Local rect corners (TL, TR, BR, BL)
      final localCorners = <rt.Vec2>[
        rt.Vec2(lb.left, lb.top),
        rt.Vec2(lb.right, lb.top),
        rt.Vec2(lb.right, lb.bottom),
        rt.Vec2(lb.left, lb.bottom),
      ];
      cornersWorld = localCorners
          .map((p) => _transformPoint(world, p))
          .toList();

      // Pivot in LOCAL space:
      // - default center of bounds when origin=center
      // - customPivotPx when origin=custom
      final xf = node.xf;
      final rt.Vec2 pivotLocal =
          (xf.origin == rt.OriginKind.custom && xf.customPivotPx != null)
          ? xf.customPivotPx!
          : rt.Vec2((lb.left + lb.right) * 0.5, (lb.top + lb.bottom) * 0.5);

      pivotWorld = _transformPoint(world, pivotLocal);
    } else {
      rt.Rect2D? boundsFor(String id) => computed.visualBoundsWorldById[id];

      final geom = rt.selectionGeometry(ids, getBounds: boundsFor);
      if (geom == null) return const SizedBox.shrink();

      cornersWorld = geom.corners;
      pivotWorld = geom.pivotWorld;
    }

    // Keep pivot synced unless we are mid-gesture.
    if (_gesturePivotWorld == null) {
      _centerWorld = pivotWorld;
    }

    Offset w2s(rt.Vec2 w) => Offset(
      w.x * widget.scale + widget.pan.dx,
      w.y * widget.scale + widget.pan.dy,
    );

    final cornersS = cornersWorld.map(w2s).toList(growable: false);

    // Rotate handle placement:
    // - For single-select oriented quad: use top edge direction.
    // - For multi-select AABB: same logic still works.
    const gap = 24.0;
    const knob = 10.0;

    final topMid = Offset(
      (cornersS[0].dx + cornersS[1].dx) / 2,
      (cornersS[0].dy + cornersS[1].dy) / 2,
    );
    final topEdge = cornersS[1] - cornersS[0];
    final normal = Offset(topEdge.dy, -topEdge.dx);
    final nUnit = normal.distance == 0
        ? const Offset(0, -1)
        : normal / normal.distance;
    final rotateCenter = topMid + nUnit * gap;

    return Positioned.fill(
      child: Builder(
        builder: (overlayCtx) => Stack(
          children: [
            IgnorePointer(
              child: CustomPaint(
                painter: _SelectionPainter(cornersS, rotateCenter, knob),
              ),
            ),

            // ----------------------------------------------------------------
            // Single-select rotate + resize
            // ----------------------------------------------------------------
            if (!disableMultiTransform) ...[
              // ROTATE (single-select)
              _hitCircle(
                overlayCtx,
                rotateCenter,
                knob,
                onStartWorld: (w) {
                  _endRotateSession ??= controller.beginEditSession();
                  _gesturePivotWorld = _centerWorld;
                  _lastAngle = _angleFromPivot(_pivotWorld, w);
                },
                onDragWorld: (w) {
                  if (_lastAngle == null) return;
                  final id = editableIds.first;

                  final ang = _angleFromPivot(_pivotWorld, w);
                  final delta = _normalizeDelta(ang - _lastAngle!);

                  controller.updateRotate(id, delta);

                  _lastAngle = ang;
                },
                onEnd: () {
                  _lastAngle = null;
                  _gesturePivotWorld = null;
                  _closeRotateSession();
                },
              ),

              // SCALE (Canva-like “resize from handle”): anchor opposite corner.
              for (var i = 0; i < cornersS.length; i++)
                _hitCircle(
                  overlayCtx,
                  cornersS[i],
                  knob,
                  onStartWorld: (w) {
                    _endScaleSession ??= controller.beginEditSession();
                    _gesturePivotWorld = _centerWorld;

                    // Opposite corner index (TL<->BR, TR<->BL)
                    final opp = (i + 2) % 4;
                    final anchorWorld = cornersWorld[opp];
                    final handleWorld = cornersWorld[i];

                    final axis = handleWorld - anchorWorld;
                    final len = axis.length;

                    if (len <= 1e-6) {
                      _scaleAnchorWorld = null;
                      _scaleAxisWorld = null;
                      _scalePrevT = null;
                      return;
                    }

                    _scaleAnchorWorld = anchorWorld;
                    _scaleAxisWorld = axis / len; // unit

                    // Signed distance along axis at start.
                    // Clamp away from zero to avoid unstable ratios.
                    var t0 = _dot(w - anchorWorld, _scaleAxisWorld!);
                    if (t0.abs() < 1e-3) t0 = t0.isNegative ? -1e-3 : 1e-3;

                    _scalePrevT = t0;
                  },
                  onDragWorld: (w) {
                    final anchorWorld = _scaleAnchorWorld;
                    final axisUnit = _scaleAxisWorld;
                    var prevT = _scalePrevT;

                    if (anchorWorld == null ||
                        axisUnit == null ||
                        prevT == null) {
                      return;
                    }

                    final id = editableIds.first;

                    // Current signed distance along the anchor->handle axis.
                    var currT = _dot(w - anchorWorld, axisUnit);

                    // Avoid crossing-through-anchor instability.
                    if (currT.abs() < 1e-3) {
                      currT = currT.isNegative ? -1e-3 : 1e-3;
                    }

                    // Incremental mul-step (prevents compounding explosions).
                    var mul = currT / prevT;

                    // Safety clamp (tune as desired).
                    mul = mul.clamp(0.02, 50.0);

                    // Convert anchorWorld -> parent space for scaleAround op.
                    final parentRef = rt.findParentOf(scene, id);
                    final parentNode = parentRef?.parent;
                    final parentWorld = (parentNode == null)
                        ? vm.Matrix4.identity()
                        : (computed.worldById[parentNode.id] ??
                              vm.Matrix4.identity());
                    final invParent = _inverseOrIdentity(parentWorld);
                    final anchorParent = _transformPoint(
                      invParent,
                      anchorWorld,
                    );

                    controller.updateUniformScaleAround(id, anchorParent, mul);

                    // Update baseline for the next incremental step.
                    _scalePrevT = currT;
                  },
                  onEnd: () {
                    _scaleAnchorWorld = null;
                    _scaleAxisWorld = null;
                    _scalePrevT = null;

                    _gesturePivotWorld = null;
                    _closeScaleSession();
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hitCircle(
    BuildContext overlayCtx,
    Offset center,
    double r, {
    required void Function(rt.Vec2 world) onStartWorld,
    required void Function(rt.Vec2 world) onDragWorld,
    required VoidCallback onEnd,
  }) {
    return Positioned(
      left: center.dx - r,
      top: center.dy - r,
      width: r * 2,
      height: r * 2,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) =>
            onStartWorld(_globalToWorld(overlayCtx, e.position)),
        onPointerMove: (e) =>
            onDragWorld(_globalToWorld(overlayCtx, e.position)),
        onPointerUp: (_) => onEnd(),
        onPointerCancel: (_) => onEnd(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blueAccent, width: 1.5),
          ),
        ),
      ),
    );
  }
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
