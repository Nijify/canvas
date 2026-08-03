// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/widgets/canvas_painter.dart

import 'package:flutter/material.dart';
import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';

class CanvasPainter extends CustomPainter {
  final Size2D artboardSize;
  final List<PaintOp> ops;
  final CanvasRenderer renderer;

  CanvasPainter({
    required this.artboardSize,
    required this.ops,
    required this.renderer,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    renderer.replay(canvas, ops);
  }

  @override
  bool shouldRepaint(covariant CanvasPainter old) =>
      !identical(ops, old.ops) || artboardSize != old.artboardSize;
}
