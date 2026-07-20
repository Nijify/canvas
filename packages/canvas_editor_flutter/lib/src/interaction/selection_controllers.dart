// Path: oss_packages/canvas_editor_flutter/lib/src/interaction/selection_controllers.dart

import 'package:flutter/foundation.dart';

import 'package:canvas_editor_flutter/src/editor_api.dart';
import 'package:canvas_editor_flutter/src/editor_hosts.dart'
    show EditorSelectionHost;

final class SelectionController extends ValueNotifier<SelectionState>
    implements EditorSelectionHost {
  SelectionController() : super(const SelectionState.none());

  @override
  String? get firstId => value.ids.isEmpty ? null : value.ids.first;

  @override
  void clearSelection() {
    value = const SelectionState.none();
  }

  @override
  void selectItems(Iterable<String> ids, {bool additive = false}) {
    final nextIds = additive ? <String>{...value.ids, ...ids} : ids;

    value = SelectionState.items(nextIds);
  }
}
