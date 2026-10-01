import 'dart:io' show Platform;

import 'package:canvas_renderer_flutter/canvas_renderer_flutter_image_providers.dart';
import 'package:canvas_renderer_flutter/src/images/flutter_file_image_provider_unsupported.dart'
    as unsupported;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('native file image provider', () {
    test('converts an escaped file URI at the host boundary', () {
      final path = Platform.isWindows
          ? r'C:\tmp\canvas image.png'
          : '/tmp/canvas image.png';
      final uri = Uri.file(path, windows: Platform.isWindows);

      final provider = sourceToProvider(uri.toString()) as FileImage;

      expect(provider.file.path, path);
    });

    test('keeps raw platform paths unchanged', () {
      final path = Platform.isWindows ? r'C:\tmp\a.png' : '/tmp/a.png';
      final provider = sourceToProvider(path) as FileImage;

      expect(provider.file.path, path);
    });

    test('does not treat failed URI conversion as a filename', () {
      expect(
        () => sourceToProvider('file:///tmp/a.png?unsupported=query'),
        throwsUnsupportedError,
      );
    });

    test('unsupported hosts report failure without echoing the source', () {
      const source = 'file:///private/image.png?token=secret';

      expect(
        () => unsupported.fileImageProvider(source),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.toString(),
            'safe message',
            isNot(contains(source)),
          ),
        ),
      );
    });
  });
}
