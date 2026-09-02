// Path: lib/src/canvas_runtime_resources.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart'
    show FlutterFontLoader;

/// One font exposed by editor font-picker UI.
///
/// Runtime font loading is owned separately by [FlutterFontLoader].
final class FontPickerItem {
  const FontPickerItem({required this.family, required this.label});

  final String family;
  final String label;
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

  Map<String, ResolvedIcon> get resolveMap => <String, ResolvedIcon>{
    for (final item in items) item.ref: item.resolved,
  };

  @override
  ResolvedIcon? resolve(String iconRef) => resolveMap[iconRef];
}

/// Passive runtime capabilities used by one editor session.
///
/// Resource discovery and loading policy belong to the individual capabilities,
/// not to this aggregate.
class CanvasRuntimeResources {
  const CanvasRuntimeResources({
    required this.fonts,
    required this.pickerFonts,
    required this.icons,
    required this.images,
  });

  /// Makes logical font families available to Flutter.
  final FlutterFontLoader fonts;

  /// Fonts exposed through editor font-picker UI.
  final List<FontPickerItem> pickerFonts;

  /// Resolves icons and supplies editor icon-catalog metadata.
  final IconCatalogPort icons;

  /// Resolves logical canvas image source references for this host.
  final CanvasImageAssetResolver images;
}
