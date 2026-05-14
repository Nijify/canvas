// Path: lib/src/algorithms/snapping/snap_scene.dart

import 'dart:math' as math;

import 'package:canvas_core/src/foundation/core_types.dart' show Vec2;
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;

import 'package:canvas_core/src/algorithms/layout/computed_scene.dart'
    show ComputedScene;
import 'package:canvas_core/src/runtime/model/node_model.dart' show NodeId;
import 'package:canvas_core/src/runtime/model/scene_document.dart';

import 'package:canvas_core/src/algorithms/snapping/keylines.dart'
    show artboardKeylines;
import 'package:canvas_core/src/algorithms/snapping/snap_types.dart'
    show
        SnapAxis,
        SnapCandidate,
        SnapConfig,
        SnapKind,
        SnapLine,
        SnapOptions,
        SnapResult;

import 'package:canvas_core/src/algorithms/snapping/snap_index_scene.dart'
    show sceneObjectKeylines;

/// Scene-graph snapping (Step 6).
///
/// Mirrors the logic of your existing `snap_engine.dart`, but candidates come from:
/// - artboard keylines
/// - scene object keylines (bounds-derived)
/// - transient guide candidates (UI-only)
/// - optional grid snapping
SnapResult snapScene({
  required CanvasSceneDocument doc,
  required ComputedScene computed, // ✅ NEW
  required Rect2D probeWorld, // selection AABB during drag (world coords)
  required SnapConfig config,
}) {
  final opts = config.options;

  final tolWorld = opts.toleranceScreenPx / math.max(opts.zoom, 1e-6);
  if (tolWorld <= 0) return SnapResult.none;

  // Convert ignore set to NodeId (same underlying type, but keeps intent).
  final ignore = config.ignoreIds.cast<NodeId>();

  // Gather candidates
  final cands = <SnapCandidate>[];

  if (opts.snapToKeylines) {
    cands.addAll(artboardKeylines(doc.artboardSize));
  }
  if (opts.snapToObjects) {
    cands.addAll(sceneObjectKeylines(doc, computed, ignoreIds: ignore));
  }
  if (opts.snapToGuides) {
    cands.addAll(config.transientGuideCandidates);
  }

  // Anchors of probe (edges + center)
  final probeCenters = (
    cx: (probeWorld.left + probeWorld.right) * 0.5,
    cy: (probeWorld.top + probeWorld.bottom) * 0.5,
  );
  final anchorsX = <double>[probeWorld.left, probeCenters.cx, probeWorld.right];
  final anchorsY = <double>[probeWorld.top, probeCenters.cy, probeWorld.bottom];

  // Respect sticky lockedAxis if provided
  final axisConstraint = config.lockedAxis ?? SnapAxis.both;

  double bestDx = 0, bestDy = 0;
  double bestScoreX = double.infinity, bestScoreY = double.infinity;
  SnapCandidate? bestCandX, bestCandY;

  // X
  if (axisConstraint == SnapAxis.both || axisConstraint == SnapAxis.x) {
    final xSnap = _snapAxis(
      anchors: anchorsX,
      axis: SnapAxis.x,
      candidates: cands,
      options: opts,
      tolWorld: tolWorld,
      gridStepWorld: config.gridStepWorld,
    );
    bestDx = xSnap.delta;
    bestScoreX = xSnap.score;
    bestCandX = xSnap.candidate;
  }

  // Y
  if (axisConstraint == SnapAxis.both || axisConstraint == SnapAxis.y) {
    final ySnap = _snapAxis(
      anchors: anchorsY,
      axis: SnapAxis.y,
      candidates: cands,
      options: opts,
      tolWorld: tolWorld,
      gridStepWorld: config.gridStepWorld,
    );
    bestDy = ySnap.delta;
    bestScoreY = ySnap.score;
    bestCandY = ySnap.candidate;
  }

  if (!bestScoreX.isFinite && !bestScoreY.isFinite) return SnapResult.none;

  final hasX = bestScoreX.isFinite;
  final hasY = bestScoreY.isFinite;

  // Compute inner dual-axis threshold in SCREEN px
  double innerTolPx0(SnapOptions opts) {
    if (opts.innerDualAxisTolPx != null && opts.innerDualAxisTolPx! > 0) {
      return opts.innerDualAxisTolPx!;
    }
    if (opts.innerDualAxisTolFactor > 0) {
      return opts.toleranceScreenPx * opts.innerDualAxisTolFactor;
    }
    return 0.0; // disabled
  }

  final innerTolPx = innerTolPx0(opts);

  // Default: apply nearest single axis
  bool applyX = hasX && (!hasY || bestScoreX <= bestScoreY);
  bool applyY = hasY && (!hasX || bestScoreY < bestScoreX);

  // Upgrade to dual-axis if both are within inner threshold and not axis-locked
  final canApplyBoth = (axisConstraint == SnapAxis.both);
  if (canApplyBoth && innerTolPx > 0 && hasX && hasY) {
    final bothWithinInnerTol =
        (bestScoreX <= innerTolPx) && (bestScoreY <= innerTolPx);
    if (bothWithinInnerTol) {
      applyX = true;
      applyY = true;
    }
  }

  final dx = applyX ? bestDx : 0.0;
  final dy = applyY ? bestDy : 0.0;

  final axisApplied = applyX
      ? (applyY ? SnapAxis.both : SnapAxis.x)
      : (applyY ? SnapAxis.y : SnapAxis.none);

  final score = math.min(bestScoreX, bestScoreY);

  // Build guides (world coords), clipped by frame
  final frame =
      config.guideFrameWorld ??
      Rect2D.fromLTWH(0, 0, doc.artboardSize.w, doc.artboardSize.h);

  final guides = <SnapLine>[];
  final canShowBoth = (axisConstraint == SnapAxis.both);

  if (hasX && bestCandX != null) {
    final showX = applyX || (opts.showBothGuidesWhenClose && canShowBoth);
    if (showX) {
      guides.add(_makeGuide(bestCandX.kind, SnapAxis.x, bestCandX.pos, frame));
    }
  }
  if (hasY && bestCandY != null) {
    final showY = applyY || (opts.showBothGuidesWhenClose && canShowBoth);
    if (showY) {
      guides.add(_makeGuide(bestCandY.kind, SnapAxis.y, bestCandY.pos, frame));
    }
  }

  return SnapResult(Vec2(dx, dy), axisApplied, score, guides);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

double _nearestGrid(double v, double step) => (v / step).roundToDouble() * step;

class _AxisSnapResult {
  final double delta;
  final double score;
  final SnapCandidate? candidate;

  const _AxisSnapResult({
    required this.delta,
    required this.score,
    required this.candidate,
  });
}

_AxisSnapResult _snapAxis({
  required List<double> anchors,
  required SnapAxis axis,
  required List<SnapCandidate> candidates,
  required SnapOptions options,
  required double tolWorld,
  required double? gridStepWorld,
}) {
  double bestDelta = 0;
  double bestScore = double.infinity;
  SnapCandidate? bestCandidate;

  for (final a in anchors) {
    for (final c in candidates) {
      if (c.axis != axis) continue;
      final dist = (c.pos - a).abs();
      if (dist <= tolWorld) {
        final screenDist = dist * options.zoom;
        if (screenDist < bestScore) {
          bestScore = screenDist;
          bestDelta = c.pos - a;
          bestCandidate = c;
        }
      }
    }
  }

  if (options.snapToGrid && (gridStepWorld ?? 0) > 0) {
    for (final a in anchors) {
      final g = _nearestGrid(a, gridStepWorld!);
      final dist = (g - a).abs();
      if (dist <= tolWorld) {
        final screenDist = dist * options.zoom;
        if (screenDist < bestScore) {
          bestScore = screenDist;
          bestDelta = g - a;
          bestCandidate = SnapCandidate(
            kind: SnapKind.grid,
            axis: axis,
            pos: g,
          );
        }
      }
    }
  }

  return _AxisSnapResult(
    delta: bestDelta,
    score: bestScore,
    candidate: bestCandidate,
  );
}

SnapLine _makeGuide(SnapKind kind, SnapAxis axis, double pos, Rect2D frame) {
  return (axis == SnapAxis.x)
      ? SnapLine(kind, axis, Rect2D.fromLTRB(pos, frame.top, pos, frame.bottom))
      : SnapLine(
          kind,
          axis,
          Rect2D.fromLTRB(frame.left, pos, frame.right, pos),
        );
}
