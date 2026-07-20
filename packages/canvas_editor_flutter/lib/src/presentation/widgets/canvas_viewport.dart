// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/widgets/canvas_viewport.dart

import 'dart:ui';

import 'package:flutter/foundation.dart' show listEquals, Listenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show HardwareKeyboard, LogicalKeyboardKey;

import 'package:canvas_core/canvas_core_editor.dart'; // Snap types + constants/extensions.
import 'package:canvas_core/canvas_core_runtime.dart'
    show
        CanvasSceneDocument,
        Rect2D,
        RenderSnapshot,
        Vec2,
        findById,
        selectionUnionBounds;
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';

import 'package:canvas_editor_flutter/src/presentation/viewport/editor_camera_state.dart'
    show kEditorCameraMaxScale, kEditorCameraMinScale;
import 'package:canvas_editor_flutter/src/editor_api.dart'
    show EditorController;
import 'package:canvas_editor_flutter/src/interaction/canvas_viewport_behavior.dart';
import 'package:canvas_editor_flutter/src/interaction/editor_interaction_policy.dart';
import 'package:canvas_editor_flutter/src/editor_hosts.dart'
    show EditorSelectionHost;
import 'package:canvas_editor_flutter/src/presentation/widgets/canvas_painter.dart';

class CanvasViewport extends StatefulWidget {
  const CanvasViewport({
    super.key,
    required this.render,
    required this.renderer,
    required this.viewportPx,
    required this.scale,
    required this.pan,
    required this.onPanZoom,
    this.snapToGuides = true,
    this.transientGuides = const [],
    required this.repaint,
    required this.selection,
    required this.controller,
    required this.interactionPolicy,
    this.viewportBehavior,
  });

  final RenderSnapshot render;
  final CanvasRenderer renderer;
  final Listenable repaint;
  final Size viewportPx;

  final double scale;
  final Offset pan;

  final bool snapToGuides;
  final List<SnapCandidate> transientGuides;

  final EditorSelectionHost selection;
  final EditorController controller;

  /// Interaction policy for movement and transform chrome.
  ///
  /// The default policy allows normal interaction with unlocked nodes.
  /// Applications can provide restrictions for selected nodes.
  final EditorInteractionPolicy interactionPolicy;

  /// Optional viewport behavior extension.
  ///
  /// The viewport provides hit testing, selection, dragging, snapping, and
  /// pan/zoom. Optional behavior can customize interaction decisions and
  /// foreground UI.
  final CanvasViewportBehavior? viewportBehavior;

  final void Function(double scale, Offset pan) onPanZoom;

  @override
  State<CanvasViewport> createState() => _CanvasViewportState();
}

class _SnapGuidesPainter extends CustomPainter {
  final List<SnapLine> guides;

  const _SnapGuidesPainter(this.guides);

  @override
  void paint(Canvas canvas, Size size) {
    if (guides.isEmpty) return;

    final p = Paint()
      ..color = const Color(0xFFFF2AA2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final g in guides) {
      final r = g.extentWorld;
      if (g.axis == SnapAxis.x) {
        final x = (r.left + r.right) / 2;
        canvas.drawLine(Offset(x, r.top), Offset(x, r.bottom), p);
      } else {
        final y = (r.top + r.bottom) / 2;
        canvas.drawLine(Offset(r.left, y), Offset(r.right, y), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SnapGuidesPainter old) {
    return !listEquals(old.guides, guides);
  }
}

class _CanvasViewportState extends State<CanvasViewport> {
  String? _draggingId;
  Vec2? _dragStartCanvas;
  List<SnapLine> _guides = const [];

  bool _allowPinchZoom = false;
  double _scaleStartScale = 1.0;
  Offset _scaleStartPan = Offset.zero;
  Offset _worldAtCenterOnScaleStart = Offset.zero;

  VoidCallback? _endDragSession;

  void _beginMoveSession() {
    _endDragSession ??= widget.controller.beginEditSession();
  }

  void _endMoveSession() {
    final endSession = _endDragSession;
    if (endSession == null) return;

    _endDragSession = null;
    endSession();
  }

  void _setGuides(List<SnapLine> next) {
    setState(() => _guides = List<SnapLine>.from(next));
  }

  void _applyDragStartIntent(CanvasDragStartIntent intent, Vec2 local) {
    final dragId = intent.dragId;

    if (dragId != null) {
      _beginMoveSession();
      _draggingId = dragId;
      _dragStartCanvas = local;
      return;
    }

    _draggingId = null;
    _dragStartCanvas = null;
    _endMoveSession();
  }

  bool _canMoveAny(CanvasSceneDocument scene, Iterable<String> ids) {
    for (final id in ids) {
      final node = findById(scene, id);
      if (node != null && widget.interactionPolicy.canMove(node)) {
        return true;
      }
    }
    return false;
  }

  Set<String> _movableIds(CanvasSceneDocument scene, Iterable<String> ids) {
    return ids.where((id) {
      final node = findById(scene, id);
      return node != null && widget.interactionPolicy.canMove(node);
    }).toSet();
  }

  @override
  void dispose() {
    _endMoveSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.render.scene;
    final computed = widget.render.computed;
    final ops = widget.render.ops;

    final vp = widget.viewportPx;
    final displayScale = widget.scale;
    final displayPan = widget.pan;

    Vec2 toCanvas(Offset screen) {
      return ((screen - displayPan) / displayScale).toCore;
    }

    CanvasViewportBehaviorContext behaviorCtx() {
      return CanvasViewportBehaviorContext(
        render: widget.render,
        selection: widget.selection,
        controller: widget.controller,
      );
    }

    return ClipRect(
      child: Container(
        color: const Color(0xFFF6F7FB),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) {
            final pos = toCanvas(d.localPosition);

            final hitLeaf = pickTopAtScene(
              scene,
              pos,
              computed: computed,
              includeLocked: false,
              selectLeaf: true,
              viewportZoom: displayScale,
            );

            final hit = pickTopAtScene(
              scene,
              pos,
              computed: computed,
              includeLocked: false,
              selectLeaf: false,
              viewportZoom: displayScale,
            );

            final behaviorHandled =
                widget.viewportBehavior?.handleTapSelection(
                  context,
                  behaviorCtx(),
                  CanvasHitTestResult(leaf: hitLeaf, node: hit),
                ) ??
                false;

            if (behaviorHandled) return;

            if (hit != null) {
              final keys = HardwareKeyboard.instance.logicalKeysPressed;
              final additive =
                  d.kind == PointerDeviceKind.mouse &&
                  (keys.contains(LogicalKeyboardKey.metaLeft) ||
                      keys.contains(LogicalKeyboardKey.metaRight) ||
                      keys.contains(LogicalKeyboardKey.controlLeft) ||
                      keys.contains(LogicalKeyboardKey.controlRight));

              widget.selection.selectItems([hit.id], additive: additive);
            } else {
              widget.selection.clearSelection();
            }
          },
          onTapUp: (_) {
            if (_guides.isNotEmpty) _setGuides(const []);
          },
          onTapCancel: () {
            if (_guides.isNotEmpty) _setGuides(const []);
          },
          onScaleStart: (d) {
            _allowPinchZoom = d.pointerCount >= 2;

            _scaleStartScale = displayScale;
            _scaleStartPan = displayPan;

            final center = Offset(vp.width / 2, vp.height / 2);
            _worldAtCenterOnScaleStart =
                (center - _scaleStartPan) / _scaleStartScale;

            final local = toCanvas(d.localFocalPoint);

            final hitLeaf = pickTopAtScene(
              scene,
              local,
              computed: computed,
              includeLocked: false,
              selectLeaf: true,
              viewportZoom: displayScale,
            );

            final hit = pickTopAtScene(
              scene,
              local,
              computed: computed,
              includeLocked: false,
              selectLeaf: false,
              viewportZoom: displayScale,
            );

            final behaviorIntent = widget.viewportBehavior
                ?.resolveDragStartSelection(
                  context,
                  behaviorCtx(),
                  CanvasHitTestResult(leaf: hitLeaf, node: hit),
                  d,
                );

            if (behaviorIntent != null) {
              _applyDragStartIntent(behaviorIntent, local);
              if (_guides.isNotEmpty) _setGuides(const []);
              return;
            }

            if (hit != null) {
              if (d.pointerCount == 1) {
                final nextSelectionIds =
                    widget.selection.value.ids.contains(hit.id)
                    ? widget.selection.value.ids
                    : <String>{hit.id};

                if (_canMoveAny(scene, nextSelectionIds)) {
                  _beginMoveSession();
                  _draggingId = hit.id;
                  _dragStartCanvas = local;
                } else {
                  _draggingId = null;
                  _dragStartCanvas = null;
                  _endMoveSession();
                }

                if (!widget.selection.value.ids.contains(hit.id)) {
                  widget.selection.selectItems([hit.id], additive: false);
                }
              } else {
                _draggingId = null;
                _dragStartCanvas = null;
                _endMoveSession();
              }
            } else {
              _draggingId = null;
              _dragStartCanvas = null;
              _endMoveSession();

              widget.selection.clearSelection();

              if (_guides.isNotEmpty) _setGuides(const []);
            }
          },
          onScaleUpdate: (d) {
            if (_draggingId != null &&
                d.pointerCount == 1 &&
                _dragStartCanvas != null) {
              final now = toCanvas(d.localFocalPoint);
              final rawDelta = now - _dragStartCanvas!;

              final selectedIds = widget.selection.value.hasItems
                  ? widget.selection.value.ids
                  : {_draggingId!};

              final movableIds = _movableIds(scene, selectedIds);

              if (movableIds.isEmpty) {
                if (_guides.isNotEmpty) _setGuides(const []);
                return;
              }

              final aabb = selectionUnionBounds(
                movableIds,
                getBounds: (sid) => computed.visualBoundsWorldById[sid],
              );

              if (aabb == null) {
                widget.controller.updateDragMany(movableIds, rawDelta);
                _dragStartCanvas = now;
                if (_guides.isNotEmpty) _setGuides(const []);
                return;
              }

              final probe = Rect2D.fromLTRB(
                aabb.left + rawDelta.x,
                aabb.top + rawDelta.y,
                aabb.right + rawDelta.x,
                aabb.bottom + rawDelta.y,
              );

              final res = snapScene(
                doc: scene,
                computed: computed,
                probeWorld: probe,
                config: SnapConfig(
                  options: SnapOptions(
                    snapToKeylines: true,
                    snapToGuides: widget.snapToGuides,
                    snapToObjects: true,
                    snapToGrid: false,
                    toleranceScreenPx: 6.0,
                    zoom: displayScale,
                    showBothGuidesWhenClose: true,
                    innerDualAxisTolFactor: 0.4,
                  ),
                  transientGuideCandidates: widget.transientGuides,
                  guideFrameWorld: Rect2D.fromLTWH(
                    0,
                    0,
                    scene.artboardSize.w,
                    scene.artboardSize.h,
                  ),
                  ignoreIds: movableIds,
                  lockedAxis: null,
                  gridStepWorld: null,
                ),
              );

              final snappedDelta = rawDelta + res.deltaWorld;

              widget.controller.updateDragMany(movableIds, snappedDelta);

              if (res.guides.isEmpty) {
                if (_guides.isNotEmpty) _setGuides(const []);
              } else if (!listEquals(_guides, res.guides)) {
                _setGuides(res.guides);
              }

              _dragStartCanvas = now;
              return;
            }

            if (!_allowPinchZoom) {
              if (_guides.isNotEmpty) _setGuides(const []);
              return;
            }

            final newScale = (_scaleStartScale * d.scale).clamp(
              kEditorCameraMinScale,
              kEditorCameraMaxScale,
            );

            final center = Offset(vp.width / 2, vp.height / 2);
            final newPan = center - _worldAtCenterOnScaleStart * newScale;

            widget.onPanZoom(newScale, newPan);

            if (_guides.isNotEmpty) _setGuides(const []);
          },
          onScaleEnd: (_) {
            _endMoveSession();

            _draggingId = null;
            _dragStartCanvas = null;
            _allowPinchZoom = false;

            if (_guides.isNotEmpty) _setGuides(const []);
          },
          child: Transform(
            transform: Matrix4.identity()
              ..translateByDouble(displayPan.dx, displayPan.dy, 0.0, 1.0)
              ..scaleByDouble(displayScale, displayScale, 1.0, 1.0),
            child: RepaintBoundary(
              child: Builder(
                builder: (context) {
                  final behaviorListenable = widget.viewportBehavior
                      ?.listenable(context);

                  return AnimatedBuilder(
                    animation: behaviorListenable == null
                        ? widget.selection
                        : Listenable.merge([
                            widget.selection,
                            behaviorListenable,
                          ]),
                    builder: (_, _) {
                      final behaviorForeground = widget.viewportBehavior
                          ?.buildForeground(context, behaviorCtx());

                      return Stack(
                        children: [
                          CustomPaint(
                            size: scene.artboardSize.toUi,
                            painter: CanvasPainter(
                              artboardSize: scene.artboardSize,
                              ops: ops,
                              renderer: widget.renderer,
                              repaint: widget.repaint,
                            ),
                          ),
                          ?behaviorForeground,
                          IgnorePointer(
                            child: CustomPaint(
                              size: scene.artboardSize.toUi,
                              painter: _SnapGuidesPainter(_guides),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
