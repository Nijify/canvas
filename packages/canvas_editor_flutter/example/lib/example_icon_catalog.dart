import 'dart:convert';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/canvas_editor_flutter.dart';
import 'package:flutter/services.dart';

const _iconAssets = [
  (ref: 'icon.diamond', label: 'Diamond', asset: 'assets/icons/diamond.json'),
  (ref: 'icon.ring', label: 'Ring', asset: 'assets/icons/ring.json'),
  (ref: 'icon.arrow', label: 'Wide arrow', asset: 'assets/icons/arrow.json'),
];

/// Example-owned asset loading, completed before the editor session starts.
final class ExampleIconCatalog implements IconCatalogPort {
  ExampleIconCatalog._(List<IconCatalogItem> items)
    : items = List.unmodifiable(items),
      resolveMap = Map.unmodifiable({
        for (final item in items) item.ref: item.resolved,
      });

  static Future<ExampleIconCatalog> load(AssetBundle bundle) async {
    final items = await Future.wait([
      for (final icon in _iconAssets)
        () async {
          final json = jsonDecode(await bundle.loadString(icon.asset));
          return IconCatalogItem(
            ref: icon.ref,
            label: icon.label,
            resolved: _decodeIcon(json),
          );
        }(),
    ]);
    return ExampleIconCatalog._(items);
  }

  @override
  final List<IconCatalogItem> items;

  @override
  final Map<String, ResolvedIcon> resolveMap;

  @override
  ResolvedIcon? resolve(String iconRef) => resolveMap[iconRef];
}

ResolvedIcon _decodeIcon(Object? json) {
  if (json is! Map ||
      json.length != 3 ||
      !json.keys.toSet().containsAll({'source', 'viewBox', 'fillRule'})) {
    throw const FormatException('Expected a colorless vector icon asset.');
  }
  final box = json['viewBox'];
  if (box is! List || box.length != 4) {
    throw const FormatException('Expected viewBox [x, y, width, height].');
  }
  double coordinate(int index) {
    final value = box[index];
    if (value is! num || !value.toDouble().isFinite) {
      throw const FormatException('Expected a finite viewBox coordinate.');
    }
    return value.toDouble();
  }

  final source = json['source'];
  if (source is! Map || source.length != 2 || source['kind'] != 'path' || source['d'] is! String) {
    throw const FormatException('Expected an SVG path source.');
  }
  final fillRule = switch (json['fillRule']) {
    'nonZero' => FillRule.nonZero,
    'evenOdd' => FillRule.evenOdd,
    _ => throw const FormatException('Expected nonZero or evenOdd fill rule.'),
  };
  try {
    return ResolvedIcon(
      pathIR: parseSvgPathData(source['d'] as String),
      viewBox: Rect2D.fromLTWH(
        coordinate(0),
        coordinate(1),
        coordinate(2),
        coordinate(3),
      ),
      fillRule: fillRule,
    );
  } on ArgumentError catch (error) {
    throw FormatException('Invalid icon geometry: ${error.message}');
  }
}
