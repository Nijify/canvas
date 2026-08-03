// Path: oss_packages/canvas_editor_flutter/test/selection_controller_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:canvas_editor_flutter/src/editor_api.dart';
import 'package:canvas_editor_flutter/src/interaction/selection_controllers.dart';

void main() {
  group('SelectionState', () {
    test('empty item selection normalizes to none', () {
      final state = SelectionState.items(const <String>[]);

      expect(state, const SelectionState.none());
      expect(state.isEmpty, isTrue);
      expect(state.hasItems, isFalse);
    });

    test('item IDs are immutable', () {
      final state = SelectionState.items(const <String>['a']);

      expect(() => state.ids.add('b'), throwsUnsupportedError);
    });

    test('item equality ignores set iteration order', () {
      final first = SelectionState.items(const <String>['a', 'b']);
      final second = SelectionState.items(const <String>['b', 'a']);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });

  group('SelectionController', () {
    test('does not notify for logically equal selection', () {
      final controller = SelectionController();
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() {
        notifications++;
      });

      controller.clearSelection();
      expect(notifications, 0);

      controller.selectItems(const <String>['a', 'b']);
      expect(notifications, 1);

      controller.selectItems(const <String>['b', 'a']);
      expect(notifications, 1);
    });

    test('empty input clears selection', () {
      final controller = SelectionController();
      addTearDown(controller.dispose);

      controller.selectItems(const <String>['a']);
      controller.selectItems(const <String>[]);

      expect(controller.value, const SelectionState.none());
      expect(controller.firstId, isNull);
    });

    test('additive selection unions IDs', () {
      final controller = SelectionController();
      addTearDown(controller.dispose);

      controller.selectItems(const <String>['a']);
      controller.selectItems(const <String>['b'], additive: true);

      expect(controller.value.ids, unorderedEquals(const <String>['a', 'b']));
      expect(controller.firstId, 'a');
    });
  });
}
