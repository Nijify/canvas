// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/viewport/editor_camera_state.dart

import 'dart:ui' show Offset, Size;

import 'package:flutter/foundation.dart' show immutable;

/// Minimum allowed viewport scale.
///
/// A value of 0.05 allows the canvas to be zoomed out substantially while
/// keeping interaction and rendering stable.
const double kEditorCameraMinScale = 0.05;

/// Maximum allowed viewport scale.
///
/// Limits how far the user can zoom in to keep interaction and rendering
/// manageable.
const double kEditorCameraMaxScale = 4.0;

/// Immutable presentation state for the editor camera.
///
/// Stores the camera transform and the latest layout measurements. Camera
/// policy remains in [EditorCameraController] and the editor surface.
@immutable
final class EditorCameraState {
  const EditorCameraState({
    required this.scale,
    required this.pan,
    required this.viewportW,
    required this.viewportH,
    required this.artboardW,
    required this.artboardH,
    required this.userInteracted,
  });

  const EditorCameraState.initial()
    : scale = 1.0,
      pan = Offset.zero,
      viewportW = 0,
      viewportH = 0,
      artboardW = 0,
      artboardH = 0,
      userInteracted = false;

  /// Current uniform zoom scale.
  final double scale;

  /// Screen-space translation in logical pixels.
  final Offset pan;

  /// Last measured viewport dimensions in screen pixels.
  final double viewportW;
  final double viewportH;

  /// Last rendered artboard dimensions in world units.
  final double artboardW;
  final double artboardH;

  /// Whether the user has explicitly panned or zoomed the camera.
  ///
  /// This is used by camera policy to distinguish initial auto-framing from
  /// a user-controlled view.
  final bool userInteracted;

  /// Last measured viewport size.
  Size get viewportSize => Size(viewportW, viewportH);

  EditorCameraState copyWith({
    double? scale,
    Offset? pan,
    double? viewportW,
    double? viewportH,
    double? artboardW,
    double? artboardH,
    bool? userInteracted,
  }) {
    return EditorCameraState(
      scale: scale ?? this.scale,
      pan: pan ?? this.pan,
      viewportW: viewportW ?? this.viewportW,
      viewportH: viewportH ?? this.viewportH,
      artboardW: artboardW ?? this.artboardW,
      artboardH: artboardH ?? this.artboardH,
      userInteracted: userInteracted ?? this.userInteracted,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EditorCameraState &&
            scale == other.scale &&
            pan == other.pan &&
            viewportW == other.viewportW &&
            viewportH == other.viewportH &&
            artboardW == other.artboardW &&
            artboardH == other.artboardH &&
            userInteracted == other.userInteracted;
  }

  @override
  int get hashCode => Object.hash(
    scale,
    pan,
    viewportW,
    viewportH,
    artboardW,
    artboardH,
    userInteracted,
  );

  @override
  String toString() {
    return 'EditorCameraState('
        'scale: $scale, '
        'pan: $pan, '
        'viewportW: $viewportW, '
        'viewportH: $viewportH, '
        'artboardW: $artboardW, '
        'artboardH: $artboardH, '
        'userInteracted: $userInteracted'
        ')';
  }
}
