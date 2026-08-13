// Path: lib/src/runtime/model/node_editing.dart

library;

import 'package:canvas_core/src/runtime/model/node_model.dart';

String? _normalizeLayerName(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;

  final runes = value.runes;
  if (runes.length <= 80) return value;

  return String.fromCharCodes(runes.take(80));
}

/// Common immutable edits that preserve node identity and tree structure.
///
/// Structural operations such as changing node IDs or replacing group children
/// are intentionally not part of this public editing surface.
extension NodeEditingX on Node {
  Node withName(String? name) {
    final normalized = _normalizeLayerName(name);

    return switch (this) {
      final TextNode node => node.copyWith(name: normalized),
      final ImageNode node => node.copyWith(name: normalized),
      final PathNode node => node.copyWith(name: normalized),
      final IconNode node => node.copyWith(name: normalized),
      final GroupNode node => node.copyWith(name: normalized),
    };
  }

  Node withXf(Transform2D xf) => switch (this) {
    final TextNode node => node.copyWith(xf: xf),
    final ImageNode node => node.copyWith(xf: xf),
    final PathNode node => node.copyWith(xf: xf),
    final IconNode node => node.copyWith(xf: xf),
    final GroupNode node => node.copyWith(xf: xf),
  };

  Node withHidden(bool hidden) => switch (this) {
    final TextNode node => node.copyWith(hidden: hidden),
    final ImageNode node => node.copyWith(hidden: hidden),
    final PathNode node => node.copyWith(hidden: hidden),
    final IconNode node => node.copyWith(hidden: hidden),
    final GroupNode node => node.copyWith(hidden: hidden),
  };

  Node withLocked(bool locked) => switch (this) {
    final TextNode node => node.copyWith(locked: locked),
    final ImageNode node => node.copyWith(locked: locked),
    final PathNode node => node.copyWith(locked: locked),
    final IconNode node => node.copyWith(locked: locked),
    final GroupNode node => node.copyWith(locked: locked),
  };
}
