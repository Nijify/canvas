// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/widgets/canvas_painter.dart

import 'package:flutter/material.dart';
import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';

class CanvasPainter extends CustomPainter {
  final Size2D artboardSize;
  final SceneEvaluation evaluation;
  final CanvasRenderer renderer;

  CanvasPainter({
    required this.artboardSize,
    required this.evaluation,
    required this.renderer,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    renderer.paintScene(canvas, evaluation);
  }

  @override
  bool shouldRepaint(covariant CanvasPainter old) =>
      !identical(evaluation, old.evaluation) || artboardSize != old.artboardSize;
}
