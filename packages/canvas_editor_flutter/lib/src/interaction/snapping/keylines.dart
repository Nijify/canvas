// Path: packages/canvas_editor_flutter/lib/src/interaction/snapping/keylines.dart

import 'package:canvas_core/canvas_core_runtime.dart' show Rect2D, Size2D;

import 'package:canvas_editor_flutter/src/interaction/snapping/snap_types.dart';

/// Center (and optionally edges) derived from rect bounds.
List<SnapCandidate> rectKeylines(
  Rect2D rect,
  SnapKind kind, {
  bool includeEdges = true,
}) {
  final cx = (rect.left + rect.right) * 0.5;
  final cy = (rect.top + rect.bottom) * 0.5;

  final list = <SnapCandidate>[
    SnapCandidate(kind: kind, axis: SnapAxis.x, pos: cx),
    SnapCandidate(kind: kind, axis: SnapAxis.y, pos: cy),
  ];

  if (includeEdges) {
    list.addAll([
      SnapCandidate(kind: kind, axis: SnapAxis.x, pos: rect.left),
      SnapCandidate(kind: kind, axis: SnapAxis.x, pos: rect.right),
      SnapCandidate(kind: kind, axis: SnapAxis.y, pos: rect.top),
      SnapCandidate(kind: kind, axis: SnapAxis.y, pos: rect.bottom),
    ]);
  }

  return list;
}

/// Center (and optionally edges) derived from artboard size.
List<SnapCandidate> artboardKeylines(Size2D ab, {bool includeEdges = false}) {
  final rect = Rect2D.fromLTWH(0, 0, ab.w, ab.h);
  return rectKeylines(rect, SnapKind.keyline, includeEdges: includeEdges);
}
