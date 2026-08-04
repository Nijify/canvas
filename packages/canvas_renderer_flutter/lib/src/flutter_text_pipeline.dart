// Path: lib/src/flutter_text_pipeline.dart

import 'dart:collection';
import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart' show Size2D, TextMeasurer;
import 'package:flutter/painting.dart';

class TextSpec {
  final String text;
  final String family;
  final int weight;
  final double size;

  /// Additional spacing between characters in logical Flutter pixels.
  final double letterSpacing;

  const TextSpec(
    this.text,
    this.family,
    this.weight,
    this.size, {
    this.letterSpacing = 0.0,
  });
}

/// Flutter text measurement and painting engine.
///
/// This object owns the [TextPainter] instances in its bounded layout cache.
/// Callers that create a pipeline must dispose it. Renderers and exporters only
/// borrow the pipeline supplied to them.
class FlutterTextPipeline implements TextMeasurer {
  FlutterTextPipeline({
    int maxEntries = 4096,
    Iterable<String> fallbackFontFamilies = const <String>[],
  }) : assert(maxEntries > 0),
       _maxEntries = maxEntries,
       _fallbackFontFamilies = List<String>.unmodifiable(
         fallbackFontFamilies
             .map((family) => family.trim())
             .where((family) => family.isNotEmpty),
       );

  final int _maxEntries;
  final List<String> _fallbackFontFamilies;

  // LRU: touching an entry moves it to the end.
  final LinkedHashMap<_Key, _CacheEntry> _cache =
      LinkedHashMap<_Key, _CacheEntry>();

  bool _disposed = false;

  int get cacheSize => _cache.length;

  /// Disposes cached layouts while keeping this pipeline reusable.
  void clearCache() {
    _ensureActive();
    _disposeCache();
  }

  /// Permanently releases this pipeline and all cached text resources.
  ///
  /// Safe to call more than once.
  void dispose() {
    if (_disposed) return;

    _disposed = true;
    _disposeCache();
  }

  @override
  Size2D measure({
    required String text,
    required String fontFamily,
    required int fontWeight,
    required double fontSize,
    required double letterSpacing,
  }) {
    _ensureActive();

    final entry = _getOrCreateLayoutEntry(
      TextSpec(
        text,
        fontFamily,
        fontWeight,
        fontSize,
        letterSpacing: letterSpacing,
      ),
    );

    _ensureLaidOut(entry);

    return Size2D(entry.painter.width, entry.painter.height);
  }

  void paint(
    ui.Canvas canvas,
    ui.Offset origin,
    TextSpec spec, {
    ui.Color? solid,
    ui.Shader? shader,
    double shadowOffset = 0,
    TextOriginKind originKind = TextOriginKind.baseline,
  }) {
    _ensureActive();

    final foregroundPaint = shader != null
        ? (ui.Paint()..shader = shader)
        : null;

    if (shadowOffset != 0) {
      final shadowPainter = _buildPainterUncached(
        spec,
        color: solid ?? const ui.Color(0xFF000000),
      );

      try {
        shadowPainter.layout();

        final shadowOrigin = _resolveOrigin(shadowPainter, origin, originKind);

        shadowPainter.paint(
          canvas,
          ui.Offset(
            shadowOrigin.dx + shadowOffset,
            shadowOrigin.dy + shadowOffset,
          ),
        );
      } finally {
        shadowPainter.dispose();
      }
    }

    // Reuse the cached layout-only painter when no visual override is needed.
    if (foregroundPaint == null && solid == null) {
      final entry = _getOrCreateLayoutEntry(spec);
      _ensureLaidOut(entry);

      final painter = entry.painter;
      painter.paint(canvas, _resolveOrigin(painter, origin, originKind));
      return;
    }

    // Colored and gradient variants are deliberately operation-scoped.
    final painter = _buildPainterUncached(
      spec,
      color: solid,
      foreground: foregroundPaint,
    );

    try {
      painter.layout();
      painter.paint(canvas, _resolveOrigin(painter, origin, originKind));
    } finally {
      painter.dispose();
    }
  }

  List<String> _fallbackFor(String primary) {
    final cleanPrimary = primary.trim();

    return _fallbackFontFamilies
        .where((family) => family != cleanPrimary)
        .toList(growable: false);
  }

  ui.Offset _resolveOrigin(
    TextPainter painter,
    ui.Offset origin,
    TextOriginKind kind,
  ) {
    if (kind == TextOriginKind.center) {
      return ui.Offset(
        origin.dx - painter.width / 2,
        origin.dy - painter.height / 2,
      );
    }

    final baseline = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );

    return ui.Offset(origin.dx, origin.dy - baseline);
  }

  _CacheEntry _getOrCreateLayoutEntry(TextSpec spec) {
    final key = _Key(
      spec.text,
      spec.family,
      spec.weight,
      spec.size,
      spec.letterSpacing,
    );

    // Remove and reinsert to mark the entry as most recently used.
    final existing = _cache.remove(key);

    if (existing != null) {
      _cache[key] = existing;
      return existing;
    }

    final entry = _CacheEntry(_buildPainterUncached(spec));

    _cache[key] = entry;
    _evictIfNeeded();

    return entry;
  }

  void _ensureLaidOut(_CacheEntry entry) {
    if (entry.isLaidOut) return;

    entry.painter.layout();
    entry.isLaidOut = true;
  }

  void _evictIfNeeded() {
    while (_cache.length > _maxEntries) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey)!.painter.dispose();
    }
  }

  void _disposeCache() {
    for (final entry in _cache.values) {
      entry.painter.dispose();
    }

    _cache.clear();
  }

  void _ensureActive() {
    if (_disposed) {
      throw StateError('FlutterTextPipeline has been disposed.');
    }
  }

  TextPainter _buildPainterUncached(
    TextSpec spec, {
    ui.Paint? foreground,
    ui.Color? color,
  }) {
    final fontWeight = FontWeight.values.firstWhere(
      (weight) => weight.value == spec.weight,
      orElse: () => FontWeight.w400,
    );

    final style = TextStyle(
      fontFamily: spec.family,
      fontFamilyFallback: _fallbackFor(spec.family),
      fontWeight: fontWeight,
      fontSize: spec.size,
      letterSpacing: spec.letterSpacing,
      foreground: foreground,
      color: foreground == null ? (color ?? const ui.Color(0xFF000000)) : null,
    );

    return TextPainter(
      text: TextSpan(text: spec.text, style: style),
      textDirection: ui.TextDirection.ltr,
    );
  }
}

enum TextOriginKind { baseline, center }

class _CacheEntry {
  _CacheEntry(this.painter);

  final TextPainter painter;
  bool isLaidOut = false;
}

class _Key {
  const _Key(
    this.text,
    this.family,
    this.weight,
    this.size,
    this.letterSpacing,
  );

  final String text;
  final String family;
  final int weight;
  final double size;
  final double letterSpacing;

  @override
  int get hashCode {
    return Object.hash(text, family, weight, size, letterSpacing);
  }

  @override
  bool operator ==(Object other) {
    return other is _Key &&
        text == other.text &&
        family == other.family &&
        weight == other.weight &&
        size == other.size &&
        letterSpacing == other.letterSpacing;
  }
}
