// Path: packages/canvas_editor_flutter/lib/src/editor_hosts.dart

import 'package:canvas_core/canvas_core_runtime.dart' as rt;
import 'package:flutter/foundation.dart';

import 'package:canvas_editor_flutter/src/editor_api.dart' show EditorEdit;

/// Canonical document capability for hosted/source-document editors.
///
/// Use this when an extension needs to read or update the host application's
/// source document, rather than only the resolved runtime scene.
abstract interface class EditorDocumentHost<TSourceDocument> {
  /// Current canonical source document.
  TSourceDocument get sourceDocument;

  /// Listenable canonical source document.
  ///
  /// This updates for source-document changes even when the base scene is
  /// unchanged, for example token binding changes.
  ValueListenable<TSourceDocument> get source;

  /// Applies a generic edit to the canonical base scene.
  ///
  /// The edit is routed through the document adapter, history, and render
  /// pipeline, so host-specific canonical metadata can be preserved, removed,
  /// or remapped as required.
  rt.ElementId? applyEdit(EditorEdit edit);

  /// Updates resolve context used by the adapter/render pipeline.
  void setResolveContext(Object? context);

  /// Applies a source-document-level mutation.
  ///
  /// Use this for source-document metadata or host-specific canonical state.
  void updateSourceDocument(
    TSourceDocument Function(TSourceDocument document) update,
  );
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
