// Path: test/editor_runtime_fakes.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/canvas_editor_flutter.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart'
    show FlutterFontLoader;

CanvasRuntimeResources canvasRuntimeResourcesForTest({
  FlutterFontLoader fonts = const TestFontLoader(),
  List<FontPickerItem> pickerFonts = const <FontPickerItem>[
    FontPickerItem(family: 'TestFont', label: 'Test Font'),
  ],
  IconCatalogPort icons = const TestIconCatalogPort(),
  CanvasImageAssetResolver images = const TestImageResolver(),
}) {
  return CanvasRuntimeResources(
    fonts: fonts,
    pickerFonts: pickerFonts,
    icons: icons,
    images: images,
  );
}

final class TestFontLoader implements FlutterFontLoader {
  const TestFontLoader({
    this.fallbackFontFamilies = const <String>['TestFont'],
  });

  @override
  final List<String> fallbackFontFamilies;

  @override
  Future<bool> ensureLoaded(Iterable<String> families) async {
    return false;
  }
}

final class TestImageResolver implements CanvasImageAssetResolver {
  const TestImageResolver();

  @override
  Future<Map<String, String>> resolveSources(List<String> sourceRefs) async {
    return const <String, String>{};
  }

  @override
  Future<Map<String, Size2D>> resolveIntrinsicSizes(
    List<String> sourceRefs,
  ) async {
    return const <String, Size2D>{};
  }
}

final class TestIconCatalogPort implements IconCatalogPort {
  const TestIconCatalogPort();

  @override
  List<IconCatalogItem> get items => const <IconCatalogItem>[];

  @override
  Map<String, ResolvedIcon> get resolveMap => const <String, ResolvedIcon>{};

  @override
  ResolvedIcon? resolve(String iconRef) => null;
}
