// Path: lib/src/fonts/flutter_font_loader.dart

import 'package:flutter/services.dart' show AssetBundle, FontLoader, rootBundle;

/// One Flutter font family backed by bundled application assets.
///
/// This type contains only renderer/runtime configuration. Presentation
/// metadata such as font-picker labels belongs to the editor or host layer.
final class BundledFlutterFont {
  const BundledFlutterFont({required this.family, required this.assetPaths});

  final String family;
  final List<String> assetPaths;
}

/// Ensures logical canvas font families are available to Flutter text layout.
///
/// Implementations may load fonts from bundled assets, a server, a local cache,
/// or another host-specific source.
///
/// The returned bool is true when at least one requested family that was not
/// available at invocation start became available before this call completed.
///
/// Callers waiting on an already in-flight load therefore also receive true
/// when that load completes successfully.
abstract interface class FlutterFontLoader {
  Iterable<String> get fallbackFontFamilies;

  Future<bool> ensureLoaded(Iterable<String> families);
}

/// Strict [FlutterFontLoader] backed by Flutter application assets.
///
/// All requested families must exist in the configured bundled font catalog.
/// Successful registrations are cached. In-flight registrations are shared
/// between concurrent callers. Failed registrations are not cached and may be
/// retried by a later call.
final class BundledFlutterFontLoader implements FlutterFontLoader {
  BundledFlutterFontLoader({
    required Iterable<BundledFlutterFont> fonts,
    Iterable<String> fallbackFontFamilies = const <String>[],
    AssetBundle? assetBundle,
  }) : _assetBundle = assetBundle ?? rootBundle,
       _assetPathsByFamily = _buildAssetPathsByFamily(fonts),
       _fallbackFontFamilies = _normalizeFamilies(fallbackFontFamilies) {
    for (final family in _fallbackFontFamilies) {
      if (!_assetPathsByFamily.containsKey(family)) {
        throw ArgumentError.value(
          family,
          'fallbackFontFamilies',
          'No bundled font is configured for this fallback family.',
        );
      }
    }
  }

  final AssetBundle _assetBundle;
  final Map<String, List<String>> _assetPathsByFamily;
  final List<String> _fallbackFontFamilies;

  final Set<String> _loadedFamilies = <String>{};
  final Map<String, Future<void>> _inFlight = <String, Future<void>>{};

  @override
  Iterable<String> get fallbackFontFamilies => _fallbackFontFamilies;

  @override
  Future<bool> ensureLoaded(Iterable<String> families) async {
    final requested = _normalizeFamilies(families);

    // Validate the complete request before starting any side effects.
    for (final family in requested) {
      if (!_assetPathsByFamily.containsKey(family)) {
        throw StateError('No bundled font is configured for family "$family".');
      }
    }

    final unavailableAtStart = <String>[
      for (final family in requested)
        if (!_loadedFamilies.contains(family)) family,
    ];

    if (unavailableAtStart.isEmpty) {
      return false;
    }

    await Future.wait<void>([
      for (final family in unavailableAtStart)
        _inFlight[family] ?? _startLoad(family),
    ]);

    return unavailableAtStart.any(_loadedFamilies.contains);
  }

  Future<void> _startLoad(String family) {
    late final Future<void> future;

    future = _loadFamily(family)
        .then<void>((_) {
          _loadedFamilies.add(family);
        })
        .whenComplete(() {
          if (identical(_inFlight[family], future)) {
            _inFlight.remove(family);
          }
        });

    _inFlight[family] = future;
    return future;
  }

  Future<void> _loadFamily(String family) async {
    final loader = FontLoader(family);

    for (final assetPath in _assetPathsByFamily[family]!) {
      loader.addFont(_assetBundle.load(assetPath));
    }

    await loader.load();
  }
}

List<String> _normalizeFamilies(Iterable<String> families) {
  final result = <String>[];
  final seen = <String>{};

  for (final raw in families) {
    final family = raw.trim();

    if (family.isEmpty || !seen.add(family)) {
      continue;
    }

    result.add(family);
  }

  return List<String>.unmodifiable(result);
}

Map<String, List<String>> _buildAssetPathsByFamily(
  Iterable<BundledFlutterFont> fonts,
) {
  final result = <String, List<String>>{};

  for (final font in fonts) {
    final family = font.family.trim();

    if (family.isEmpty) {
      throw ArgumentError.value(
        font.family,
        'fonts',
        'Bundled font family must be nonblank.',
      );
    }

    if (result.containsKey(family)) {
      throw ArgumentError('Duplicate bundled font family "$family".');
    }

    final assetPaths = <String>[];
    final seenPaths = <String>{};

    for (final rawPath in font.assetPaths) {
      final assetPath = rawPath.trim();

      if (assetPath.isEmpty) {
        throw ArgumentError(
          'Bundled font "$family" contains a blank asset path.',
        );
      }

      if (seenPaths.add(assetPath)) {
        assetPaths.add(assetPath);
      }
    }

    if (assetPaths.isEmpty) {
      throw ArgumentError(
        'Bundled font "$family" must contain at least one asset path.',
      );
    }

    result[family] = List<String>.unmodifiable(assetPaths);
  }

  return Map<String, List<String>>.unmodifiable(result);
}
