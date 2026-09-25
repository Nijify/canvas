// Path: packages/canvas_editor_flutter/lib/src/interaction/selection_controllers.dart

import 'package:canvas_core/canvas_core_runtime.dart' as rt;
import 'package:flutter/foundation.dart';

import 'package:canvas_editor_flutter/src/editor_hosts.dart'
    show EditorSelectionHost;

final class SelectionController extends ValueNotifier<rt.ElementId?>
    implements EditorSelectionHost {
  SelectionController() : super(null);

  @override
  void selectItem(rt.ElementId? id) {
    value = id;
  }
}
