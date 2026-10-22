library;

export 'src/unsupported_bg_remover.dart'
    if (dart.library.io) 'src/ml_kit_bg_remover.dart'
    show createBackgroundRemovalByteProcessor;
