// Path: lib/src/images/flutter_file_image_provider_io.dart
// IO-platform file-backed ImageProvider implementation.

import 'dart:io' show File, Platform;

import 'package:flutter/widgets.dart';

ImageProvider<Object> fileImageProvider(String source) {
  // Raw paths stay raw. Only this host adapter interprets file URI syntax.
  // Invalid or unsupported URI conversions propagate instead of being used
  // as literal filenames.
  final path = source.toLowerCase().startsWith('file:')
      ? Uri.parse(source).toFilePath(windows: Platform.isWindows)
      : source;
  return FileImage(File(path));
}
