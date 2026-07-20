// Path: oss_packages/canvas_editor_flutter/test/asset_library_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/asset_library.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'asset library resolves intrinsic size from source and thumbnail refs',
    () {
      const catalog = LocalCanvasAssetLibrary(<CanvasAssetLibraryItem>[
        CanvasAssetLibraryItem(
          id: 'sample_image_01',
          label: 'Sample image',
          category: 'samples/images',
          sourceRef: 'asset:assets/samples/image_01.png',
          thumbnailRef: 'asset:assets/samples/thumbs/image_01.png',
          intrinsicSize: Size2D(1024, 768),
          tags: <String>['sample', 'image'],
        ),
      ]);

      expect(catalog.categories, const <String>['samples/images']);
      expect(catalog.byCategory('samples/images'), hasLength(1));

      expect(
        catalog.intrinsicSizeFor('asset:assets/samples/image_01.png'),
        const Size2D(1024, 768),
      );

      expect(
        catalog.intrinsicSizeFor('assets/samples/image_01.png'),
        const Size2D(1024, 768),
      );

      expect(
        catalog.intrinsicSizeFor('asset:assets/samples/thumbs/image_01.png'),
        const Size2D(1024, 768),
      );

      expect(catalog.intrinsicSizeFor('media:unknown'), isNull);
    },
  );
}
