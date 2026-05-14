// Path: lib/src/algorithms/snapping/snap_types.dart
import 'package:canvas_core/src/foundation/core_types.dart';
import 'package:canvas_core/src/foundation/geometry/geometry.dart' show Rect2D;

enum SnapKind { keyline, guide, grid, object }

enum SnapAxis { x, y, both, none }

class SnapOptions {
  final bool snapToKeylines;
  final bool snapToGuides;
  final bool snapToGrid;
  final bool snapToObjects;

  /// If true, when both axes are within tolerance we render both guides,
  /// but we still apply the nearest axis only (unless inner dual-axis triggers).
  final bool showBothGuidesWhenClose;

  /// Screen-pixel tolerance for normal snapping.
  final double toleranceScreenPx;

  /// Screen px per world px.
  final double zoom;

  /// If set (>0), dual-axis snap is applied when BOTH axes are within this many screen px.
  /// Takes precedence over [innerDualAxisTolFactor].
  final double? innerDualAxisTolPx;

  /// If >0, use toleranceScreenPx * innerDualAxisTolFactor as the inner threshold.
  /// Ignored when [innerDualAxisTolPx] is provided.
  final double innerDualAxisTolFactor;

  const SnapOptions({
    this.snapToKeylines = true,
    this.snapToGuides = true,
    this.snapToGrid = true,
    this.snapToObjects = true,
    this.showBothGuidesWhenClose = false,
    this.toleranceScreenPx = 6.0,
    this.zoom = 1.0,
    this.innerDualAxisTolPx,
    this.innerDualAxisTolFactor = 0.0, // 0 = disabled unless px is set
  });
}

/// A candidate alignment line (in world coordinates).
class SnapCandidate {
  final SnapKind kind;
  final SnapAxis axis;

  /// For vertical lines: x = pos; for horizontal: y = pos.
  final double pos;
  const SnapCandidate({
    required this.kind,
    required this.axis,
    required this.pos,
  });
}

class SnapLine {
  final SnapKind kind;
  final SnapAxis axis;

  /// Thin rect to render as the guide (world coords).
  final Rect2D extentWorld;
  const SnapLine(this.kind, this.axis, this.extentWorld);
}

class SnapResult {
  final Vec2 deltaWorld; // delta to apply to the probe
  final SnapAxis axis; // which axis actually snapped
  final double score; // smaller is closer (screen px)
  final List<SnapLine> guides;

  const SnapResult(this.deltaWorld, this.axis, this.score, this.guides);
  static const none = SnapResult(Vec2.zero, SnapAxis.none, double.infinity, []);
}

/// Unified configuration for snapping; pass this object around rather than many params.
class SnapConfig {
  final SnapOptions options;

  /// Optional persistent axis lock for "sticky" behavior across pointer moves.
  final SnapAxis? lockedAxis;

  /// Optional grid step (world units). If null/<=0, grid disabled.
  final double? gridStepWorld;

  /// Ids to ignore (e.g., current selection).
  final Set<String> ignoreIds;

  /// Optional clipping frame for guides (defaults to artboard).
  final Rect2D? guideFrameWorld;

  /// Transient guide candidates supplied by the caller (UI state only).
  /// These MUST NOT be persisted to a document schema.
  final List<SnapCandidate> transientGuideCandidates;

  const SnapConfig({
    this.options = const SnapOptions(),
    this.lockedAxis,
    this.gridStepWorld,
    this.ignoreIds = const {},
    this.guideFrameWorld,
    this.transientGuideCandidates = const [],
  });
}
