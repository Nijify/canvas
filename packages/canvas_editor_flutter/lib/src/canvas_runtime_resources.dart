// Path: oss_packages/canvas_editor_flutter/lib/src/canvas_runtime_resources.dart

import 'package:canvas_core/canvas_core_runtime.dart';

class FontDef {
  const FontDef({
    required this.family,
    required this.label,
    this.assetPaths = const <String>[],
  });

  final String family;
  final String label;
  final List<String> assetPaths;
}

class IconCatalogItem {
  const IconCatalogItem({
    required this.ref,
    required this.label,
    required this.resolved,
  });

  final String ref;
  final String label;
  final ResolvedIcon resolved;
}

abstract interface class IconCatalogPort implements IconResolver {
  List<IconCatalogItem> get items;

  Map<String, ResolvedIcon> get resolveMap => {
    for (final item in items) item.ref: item.resolved,
  };

  @override
  ResolvedIcon? resolve(String iconRef) => resolveMap[iconRef];
}

abstract interface class CanvasFontAssets {
  /// Fonts shown in font pickers.
  List<FontDef> get pickerFonts;

  /// Fonts the runtime can load.
  ///
  /// This should include picker fonts plus hidden runtime fonts,
  /// such as icon fonts.
  List<FontDef> get loadableFonts;

  /// Font families used by Flutter text fallback.
  ///
  /// Usually typography fonts only, not icon fonts.
  Iterable<String> get fallbackFontFamilies;

  /// Ensure font families are loaded before measurement/export.
  Future<void> ensureLoaded(Iterable<String> families);
}

abstract interface class CanvasMediaResolver {
  /// Resolve a canvas media ref to something Flutter/image rendering can load.
  ///
  /// The editor treats refs as opaque strings. Host apps define what schemes
  /// such as `media:`, `asset:`, `file:`, or app-specific refs mean.
  ///
  /// Examples:
  /// - asset:assets/samples/image_01.png
  /// - media:uploaded-image-01
  /// - https://cdn.example.com/image.png
  /// - file:///tmp/image.png
  Future<String?> resolveUrl(String ref);

  Future<Map<String, String>> resolveUrls(List<String> refs);

  Future<Size2D?> resolveIntrinsicSize(String ref);

  Future<Map<String, Size2D>> resolveIntrinsicSizes(List<String> refs);
}

/// Runtime assets required to render and edit existing scenes.
///
/// Asset libraries/elements pickers are optional editor features. They should be
/// passed through extensions instead of being part of this runtime object.
class CanvasRuntimeResources {
  const CanvasRuntimeResources({
    required this.fonts,
    required this.icons,
    required this.media,
  });

  final CanvasFontAssets fonts;
  final IconCatalogPort icons;
  final CanvasMediaResolver media;

  Iterable<String> get fallbackFontFamilies => fonts.fallbackFontFamilies;

  Set<String> fontFamiliesForScene(
    CanvasSceneDocument scene, {
    bool includeFallbackFonts = true,
    bool includeIconFonts = true,
  }) {
    final out = <String>{if (includeFallbackFonts) ...fallbackFontFamilies};

    void walk(Node node) {
      if (node is TextNode) {
        final family = node.data.fontFamily.trim();
        if (family.isNotEmpty) out.add(family);
      } else if (includeIconFonts && node is IconNode) {
        final resolved = icons.resolve(node.data.iconRef);
        if (resolved is ResolvedIconText) {
          final family = resolved.fontFamily.trim();
          if (family.isNotEmpty) out.add(family);
        }
      }

      if (node.isGroup) {
        for (final child in node.childrenOrEmpty) {
          walk(child);
        }
      }
    }

    for (final root in scene.children) {
      walk(root);
    }

    return out;
  }

  Future<void> ensureFontsForScene(
    CanvasSceneDocument scene, {
    bool includeFallbackFonts = true,
    bool includeIconFonts = true,
  }) {
    return fonts.ensureLoaded(
      fontFamiliesForScene(
        scene,
        includeFallbackFonts: includeFallbackFonts,
        includeIconFonts: includeIconFonts,
      ),
    );
  }
}
