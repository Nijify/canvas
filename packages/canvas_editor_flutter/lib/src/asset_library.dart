// Path: oss_packages/canvas_editor_flutter/lib/src/asset_library.dart

import 'package:canvas_core/canvas_core_runtime.dart' show Size2D;
import 'package:flutter/widgets.dart' show BuildContext;

/// One curated asset that can be presented by an asset-library UI.
class CanvasAssetLibraryItem {
  const CanvasAssetLibraryItem({
    required this.id,
    required this.label,
    required this.category,
    required this.sourceRef,
    required this.thumbnailRef,
    required this.intrinsicSize,
    this.tags = const <String>[],
    this.defaultSize = 220,
    this.metadata = const <String, Object?>{},
  });

  /// Stable identifier for this catalog item.
  final String id;

  /// User-facing asset name.
  final String label;

  /// Host-defined grouping key used by asset-library UI.
  ///
  /// Examples include `samples/photos`, `shapes/basic`, and
  /// `stickers/arrows`.
  final String category;

  /// Reference persisted in the canvas document when the asset is inserted.
  final String sourceRef;

  /// Reference used by the host's picker or grid UI.
  final String thumbnailRef;

  /// Natural dimensions of the source asset.
  final Size2D intrinsicSize;

  /// Host-defined search and filtering terms.
  final List<String> tags;

  /// Maximum initial extent of the inserted image node.
  ///
  /// When [intrinsicSize] is valid, the largest inserted dimension is
  /// [defaultSize] and the intrinsic aspect ratio is preserved.
  final double defaultSize;

  /// Host-defined data such as provider, attribution, licensing, or search
  /// metadata.
  ///
  /// The editor does not interpret this map.
  final Map<String, Object?> metadata;
}

/// A curated collection of assets available to an editor.
abstract class CanvasAssetLibrary {
  const CanvasAssetLibrary();

  /// All assets in this library.
  List<CanvasAssetLibraryItem> get items;

  /// Sorted category keys represented by [items].
  List<String> get categories {
    final categories = <String>{
      for (final item in items) item.category,
    }.toList()..sort();

    return categories;
  }

  /// Returns the assets assigned to [category].
  List<CanvasAssetLibraryItem> byCategory(String category) {
    return items
        .where((item) => item.category == category)
        .toList(growable: false);
  }

  /// Finds an asset by its source or thumbnail reference.
  ///
  /// References with an `asset:` prefix are matched against the equivalent
  /// unprefixed reference.
  CanvasAssetLibraryItem? bySourceRef(String ref) {
    final normalized = _normalizeRef(ref);

    for (final item in items) {
      if (_normalizeRef(item.sourceRef) == normalized) {
        return item;
      }

      if (_normalizeRef(item.thumbnailRef) == normalized) {
        return item;
      }
    }

    return null;
  }

  /// Returns the intrinsic size associated with [ref], when known.
  Size2D? intrinsicSizeFor(String ref) {
    return bySourceRef(ref)?.intrinsicSize;
  }

  String _normalizeRef(String ref) {
    final trimmed = ref.trim();

    if (trimmed.startsWith('asset:')) {
      return trimmed.substring('asset:'.length).trim();
    }

    return trimmed;
  }
}

/// An in-memory asset library backed by a fixed list.
class LocalCanvasAssetLibrary extends CanvasAssetLibrary {
  const LocalCanvasAssetLibrary(this.items);

  @override
  final List<CanvasAssetLibraryItem> items;
}

/// Presents a host-owned UI flow for selecting one curated asset.
///
/// The host may use a dialog, bottom sheet, route, side panel, or any other
/// presentation. Return `null` when the user cancels.
typedef CanvasAssetLibrarySelectionPresenter =
    Future<CanvasAssetLibraryItem?> Function(
      BuildContext context,
      CanvasAssetLibrary library,
    );
