// Path: packages/canvas_editor_flutter/lib/src/editor_hosts.dart

import 'package:canvas_core/canvas_core_runtime.dart' as rt;
import 'package:flutter/foundation.dart';

/// Canonical document capability for hosted/source-document editors.
///
/// Use this when an extension needs to read or update host-owned source state
/// outside the canonical base canvas scene.
abstract interface class EditorDocumentHost<TSourceDocument> {
  /// Current published canonical source document.
  TSourceDocument get sourceDocument;

  /// Listenable canonical source document.
  ///
  /// This updates for source-document changes even when the base scene is
  /// unchanged, for example token-binding or other source-metadata changes.
  ValueListenable<TSourceDocument> get source;

  /// Updates resolve context used by the adapter/render pipeline.
  void setResolveContext(Object? context);

  /// Applies a source-document edit that must preserve the canonical base
  /// canvas scene.
  ///
  /// The callback receives immutable canonical input and must be synchronous,
  /// deterministic, and free of side effects.
  ///
  /// Use this only for host-owned metadata or canonical state outside the base
  /// scene. A callback that meaningfully changes the adapter's base scene is
  /// programmer misuse and throws before history or publication is changed.
  ///
  /// Base-scene mutations belong on `EditorController.applyEdit()`,
  /// `commitField()`, or `updateField()`.
  void applySourceEdit(TSourceDocument Function(TSourceDocument document) edit);
}

/// Selection capability exposed to editor extensions.
///
/// Selection is either one canvas item ID or null.
abstract interface class EditorSelectionHost
    implements ValueListenable<rt.ElementId?> {
  /// Replaces the current selection.
  ///
  /// Pass null to clear selection.
  void selectItem(rt.ElementId? id);
}
