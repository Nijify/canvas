// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/viewport/editor_camera_controller.dart

import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'package:canvas_core/canvas_core_runtime.dart'
    show Rect2D, Size2D, computeViewport;
import 'package:canvas_editor_flutter/src/presentation/viewport/editor_camera_state.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;

/// Owns mutable editor-camera state and framing policy.
///
/// [CanvasEditorSurface] decides when layout synchronization is required.
/// This controller owns how the requested artboard or content framing is
/// converted into camera scale and pan.
final class EditorCameraController extends ValueNotifier<EditorCameraState> {
  EditorCameraController() : super(const EditorCameraState.initial());

  /// Updates camera scale and/or screen-space pan.
  ///
  /// A real pan or zoom marks the camera as user-controlled. Tiny floating-point
  /// changes are ignored to avoid unnecessary rebuilds during pointer gestures.
  void setPanZoom({double? newScale, Offset? newPan}) {
    final clampedScale = newScale == null
        ? value.scale
        : newScale
              .clamp(kEditorCameraMinScale, kEditorCameraMaxScale)
              .toDouble();

    final nextPan = newPan ?? value.pan;

    final changed =
        !_closeD(value.scale, clampedScale) || !_closeO(value.pan, nextPan);

    if (!changed) return;

    _set(
      value.copyWith(scale: clampedScale, pan: nextPan, userInteracted: true),
    );
  }

  /// Synchronizes camera state with a valid viewport and artboard layout.
  ///
  /// Camera behavior:
  ///
  /// - Before user interaction, fit the artboard or usable content bounds.
  /// - Content bounds are usable only when both dimensions are positive.
  /// - When [forceFit] is true, fit even after user interaction.
  /// - After user interaction, preserve the same world point at the viewport
  ///   centre when this method is invoked for a real layout change.
  void syncToLayout({
    required Size viewportPx,
    required Size2D artboard,
    required double paddingPx,
    required bool forceFit,
    Rect2D? contentBounds,
  }) {
    if (!viewportPx.width.isFinite ||
        !viewportPx.height.isFinite ||
        viewportPx.width <= 0 ||
        viewportPx.height <= 0 ||
        artboard.w <= 0 ||
        artboard.h <= 0) {
      return;
    }

    final current = value;
    final previousViewport = current.viewportSize;

    final viewportChanged =
        previousViewport.width != viewportPx.width ||
        previousViewport.height != viewportPx.height;

    final artboardChanged =
        current.artboardW != artboard.w || current.artboardH != artboard.h;

    if (!viewportChanged && !artboardChanged && !forceFit) {
      return;
    }

    final shouldFit = forceFit || !current.userInteracted;

    if (shouldFit) {
      final usableContentBounds =
          contentBounds != null &&
              contentBounds.width > 0 &&
              contentBounds.height > 0
          ? contentBounds
          : null;

      final sourceBounds =
          usableContentBounds ?? Rect2D.fromLTWH(0, 0, artboard.w, artboard.h);

      final fit = _computeFit(
        viewportPx: viewportPx,
        sourceBounds: sourceBounds,
        paddingPx: paddingPx,
      );

      if (usableContentBounds != null) {
        _set(
          current.copyWith(
            scale: fit.scale,
            pan: fit.pan,
            viewportW: viewportPx.width,
            viewportH: viewportPx.height,
            artboardW: artboard.w,
            artboardH: artboard.h,
            userInteracted: false,
          ),
        );
        return;
      }

      // Preserve the old optimization: when only layout metadata changes and
      // fit values are effectively identical, retain scale/pan unchanged.
      if (_closeD(current.scale, fit.scale) && _closeO(current.pan, fit.pan)) {
        _set(
          current.copyWith(
            viewportW: viewportPx.width,
            viewportH: viewportPx.height,
            artboardW: artboard.w,
            artboardH: artboard.h,
          ),
        );
        return;
      }

      _set(
        current.copyWith(
          scale: fit.scale,
          pan: fit.pan,
          viewportW: viewportPx.width,
          viewportH: viewportPx.height,
          artboardW: artboard.w,
          artboardH: artboard.h,
        ),
      );
      return;
    }

    // User has already moved the camera. Preserve the world point that was at
    // the previous viewport centre instead of jumping to a fresh auto-fit.
    final oldCentre = Offset(
      previousViewport.width / 2,
      previousViewport.height / 2,
    );

    final worldAtOldCentre = (oldCentre - current.pan) / current.scale;

    final newCentre = Offset(viewportPx.width / 2, viewportPx.height / 2);

    final newPan = newCentre - _multiply(worldAtOldCentre, current.scale);

    _set(
      current.copyWith(
        pan: newPan,
        viewportW: viewportPx.width,
        viewportH: viewportPx.height,
        artboardW: artboard.w,
        artboardH: artboard.h,
      ),
    );
  }

  /// Replaces the state only when it is materially different.
  ///
  /// [EditorCameraState] has structural equality, so this prevents redundant
  /// notifications while preserving all meaningful state changes.
  void _set(EditorCameraState next) {
    if (next == value) return;
    value = next;
  }

  ({double scale, Offset pan}) _computeFit({
    required Size viewportPx,
    required Rect2D sourceBounds,
    required double paddingPx,
  }) {
    // Preserve the established editor rule: only positive padding affects the
    // viewport fit. Zero and negative padding are treated as no padding.
    final hasPadding = paddingPx > 0;

    final targetW = hasPadding
        ? math.max(1.0, viewportPx.width - paddingPx * 2)
        : viewportPx.width;

    final targetH = hasPadding
        ? math.max(1.0, viewportPx.height - paddingPx * 2)
        : viewportPx.height;

    final transform = computeViewport(
      sourceBounds: sourceBounds,
      targetW: targetW,
      targetH: targetH,
      minUniformScale: kEditorCameraMinScale,
      maxUniformScale: kEditorCameraMaxScale,
    );

    final inset = hasPadding ? paddingPx : 0.0;

    return (
      scale: transform.scale,
      pan: Offset(transform.translateX + inset, transform.translateY + inset),
    );
  }

  static Offset _multiply(Offset offset, double scale) {
    return Offset(offset.dx * scale, offset.dy * scale);
  }

  static bool _closeD(double a, double b, [double epsilon = 1e-6]) {
    return (a - b).abs() < epsilon;
  }

  static bool _closeO(Offset a, Offset b, [double epsilon = 1e-3]) {
    return (a.dx - b.dx).abs() < epsilon && (a.dy - b.dy).abs() < epsilon;
  }
}
