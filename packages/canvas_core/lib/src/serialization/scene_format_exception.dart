import 'package:canvas_core/src/runtime/validation/scene_document_validation.dart';

/// The first invalid value at a persisted-scene boundary.
///
/// The issue's code and JSON Pointer path are stable diagnostic data. Its
/// message, and the inherited FormatException message, are for display only.
final class CanvasSceneFormatException extends FormatException {
  CanvasSceneFormatException(this.issue)
    : super('${issue.path}: ${issue.message}');

  final CanvasSceneValidationIssue issue;
}
