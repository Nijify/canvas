// Path: oss_packages/canvas_editor_flutter/test/editor_runtime_fakes.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/canvas_editor_flutter.dart';

CanvasRuntimeResources canvasRuntimeResourcesForTest() {
  return CanvasRuntimeResources(
    fonts: TestFontAssets(),
    icons: TestIconCatalogPort(),
    media: TestMediaResolver(),
  );
}

final class TestMediaResolver implements CanvasMediaResolver {
  @override
  Future<String?> resolveUrl(String ref) async => null;

  @override
  Future<Map<String, String>> resolveUrls(List<String> refs) async {
    return const <String, String>{};
  }

  @override
  Future<Size2D?> resolveIntrinsicSize(String ref) async => null;

  @override
  Future<Map<String, Size2D>> resolveIntrinsicSizes(List<String> refs) async {
    return const <String, Size2D>{};
  }
}

final class TestFontAssets implements CanvasFontAssets {
  @override
  List<FontDef> get pickerFonts => const <FontDef>[];

  @override
  List<FontDef> get loadableFonts => const <FontDef>[];

  @override
  Iterable<String> get fallbackFontFamilies => const <String>[];

  @override
  Future<void> ensureLoaded(Iterable<String> families) async {}
}

final class TestIconCatalogPort implements IconCatalogPort {
  @override
  List<IconCatalogItem> get items => const <IconCatalogItem>[];

  @override
  Map<String, ResolvedIcon> get resolveMap => const <String, ResolvedIcon>{};

  @override
  ResolvedIcon? resolve(String iconRef) => null;
}
