// Path: packages/canvas_editor_flutter/test/selection_controller_test.dart

import 'package:canvas_editor_flutter/src/interaction/selection_controllers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelectionController', () {
    test('starts with no selection', () {
      final controller = SelectionController();
      addTearDown(controller.dispose);

      expect(controller.value, isNull);
    });

    test('selectItem replaces selection and null clears it', () {
      final controller = SelectionController();
      addTearDown(controller.dispose);

      controller.selectItem('a');
      expect(controller.value, 'a');

      controller.selectItem('b');
      expect(controller.value, 'b');

      controller.selectItem(null);
      expect(controller.value, isNull);
    });

    test('does not notify when assigning the same selection', () {
      final controller = SelectionController();
      addTearDown(controller.dispose);

      var notifications = 0;

      controller.addListener(() {
        notifications++;
      });

      controller.selectItem(null);
      expect(notifications, 0);

      controller.selectItem('a');
      expect(notifications, 1);

      controller.selectItem('a');
      expect(notifications, 1);

      controller.selectItem('b');
      expect(notifications, 2);

      controller.selectItem(null);
      expect(notifications, 3);

      controller.selectItem(null);
      expect(notifications, 3);
    });
  });
}
