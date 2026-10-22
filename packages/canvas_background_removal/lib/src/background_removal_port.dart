import 'dart:typed_data';

import 'package:canvas_editor_flutter/image_tools.dart'
    show
        BackgroundRemovalPort,
        BackgroundRemovalResult,
        BackgroundRemovalFailure,
        BackgroundRemovalFailureKind,
        BackgroundRemovalSuccess;

import 'background_removal_processor.dart';
import 'background_removal_provider.dart';
import 'encoded_raster_inspector.dart';

typedef BackgroundRemovalRead = Future<Uint8List?> Function(String sourceRef);
typedef BackgroundRemovalPersist =
    Future<String?> Function(BackgroundRemovalProcessedImage image);

/// Host-supplied source/storage adapters and a native/model byte provider.
/// The port never interprets source refs or imports an application repository.
final class CanvasBackgroundRemovalPort implements BackgroundRemovalPort {
  CanvasBackgroundRemovalPort({
    required BackgroundRemovalRead readSource,
    required BackgroundRemovalPersist persistPng,
    required BackgroundRemovalByteProcessor processor,
    EncodedRasterInspector? rasterInspector,
  }) : _readSource = readSource,
       _persistPng = persistPng,
       _processor = ValidatedBackgroundRemovalProcessor(
         remover: processor,
         rasterInspector: rasterInspector,
       );

  final BackgroundRemovalRead _readSource;
  final BackgroundRemovalPersist _persistPng;
  final ValidatedBackgroundRemovalProcessor _processor;

  @override
  Future<BackgroundRemovalResult> removeBackground({
    required String sourceRef,
  }) async {
    final original = sourceRef.trim();
    if (original.isEmpty) {
      return const BackgroundRemovalFailure(
        kind: BackgroundRemovalFailureKind.failed,
        message: 'The selected image has no usable source.',
      );
    }

    final Uint8List? input;
    try {
      input = await _readSource(original);
    } catch (_) {
      return const BackgroundRemovalFailure(
        kind: BackgroundRemovalFailureKind.failed,
        message: 'Unable to read the selected image.',
      );
    }
    if (input == null || input.isEmpty) {
      return const BackgroundRemovalFailure(
        kind: BackgroundRemovalFailureKind.failed,
        message: 'Unable to read the selected image.',
      );
    }

    final BackgroundRemovalProcessResult processed;
    try {
      processed = await _processor.process(inputBytes: input);
    } catch (_) {
      return const BackgroundRemovalFailure(
        kind: BackgroundRemovalFailureKind.failed,
      );
    }

    if (processed is BackgroundRemovalProcessFailure) {
      return switch (processed.kind) {
        BackgroundRemovalProcessFailureKind.unsupportedInput =>
          const BackgroundRemovalFailure(
            kind: BackgroundRemovalFailureKind.unsupported,
            message:
                'Background removal supports static PNG, JPEG, and WebP images.',
          ),
        BackgroundRemovalProcessFailureKind.temporarilyUnavailable =>
          const BackgroundRemovalFailure(
            kind: BackgroundRemovalFailureKind.temporarilyUnavailable,
            message:
                'Background removal is still preparing. Try again shortly.',
          ),
        BackgroundRemovalProcessFailureKind.failed =>
          const BackgroundRemovalFailure(
            kind: BackgroundRemovalFailureKind.failed,
          ),
      };
    }

    final png = (processed as BackgroundRemovalProcessSuccess).image;
    final String? stored;
    try {
      stored = await _persistPng(png);
    } catch (_) {
      return const BackgroundRemovalFailure(
        kind: BackgroundRemovalFailureKind.failed,
        message: 'The result could not be saved. Please try again.',
      );
    }
    final replacement = stored?.trim();
    if (replacement == null || replacement.isEmpty || replacement == original) {
      return const BackgroundRemovalFailure(
        kind: BackgroundRemovalFailureKind.failed,
        message: 'The result could not be saved. Please try again.',
      );
    }
    return BackgroundRemovalSuccess(sourceRef: replacement);
  }
}
