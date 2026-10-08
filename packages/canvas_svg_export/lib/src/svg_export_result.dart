/// Stable categories for features that cannot be faithfully exported.
enum SvgExportIssueCode {
  invalidScene,
  unsupportedGradient,
  unsupportedText,
  unsupportedImage,
  unsupportedIcon,
  unsupportedDashedStroke,
  missingComputedGeometry,
}

/// [nodeId] is absent for document-level issues such as the background.
/// [path] points to a source field when reported by scene validation.
final class SvgExportIssue {
  const SvgExportIssue({
    required this.code,
    required this.message,
    this.nodeId,
    this.path,
  });

  final SvgExportIssueCode code;
  final String message;
  final String? nodeId;
  final String? path;
}

/// A strict export returns a complete document or issues, never partial SVG.
final class SvgExportResult {
  const SvgExportResult._(this.svg, this.issues);

  factory SvgExportResult.success(String svg) =>
      SvgExportResult._(svg, const <SvgExportIssue>[]);

  factory SvgExportResult.failure(List<SvgExportIssue> issues) =>
      SvgExportResult._(null, List<SvgExportIssue>.unmodifiable(issues));

  final String? svg;
  final List<SvgExportIssue> issues;

  bool get isSuccess => svg != null;
}
