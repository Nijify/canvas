import 'package:flutter_test/flutter_test.dart';

import 'package:canvas_editor_flutter/src/runtime/history/history.dart';

void main() {
  group('History', () {
    test('starts with the supplied present and empty stacks', () {
      final history = History<int>(1);

      expect(history.present, 1);
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
      expect(history.pastLength, 0);
      expect(history.futureLength, 0);
    });

    test('reduce pushes the previous present and clears redo history', () {
      var history = History<int>(1);

      history = history.reduce((value) => value + 1);
      history = history.reduce((value) => value + 1);

      expect(history.present, 3);
      expect(history.canUndo, isTrue);
      expect(history.canRedo, isFalse);
      expect(history.pastLength, 2);

      history = history.undo();

      expect(history.present, 2);
      expect(history.canRedo, isTrue);

      history = history.reduce((value) => value + 10);

      expect(history.present, 12);
      expect(history.canRedo, isFalse);
      expect(history.futureLength, 0);
    });

    test('undo and redo move between past, present, and future', () {
      var history = History<int>(1);

      history = history.withPresent(2);
      history = history.withPresent(3);

      history = history.undo();

      expect(history.present, 2);
      expect(history.canUndo, isTrue);
      expect(history.canRedo, isTrue);

      history = history.undo();

      expect(history.present, 1);
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isTrue);

      history = history.redo();

      expect(history.present, 2);

      history = history.redo();

      expect(history.present, 3);
      expect(history.canRedo, isFalse);
    });

    test('limit retains only the most recent past entries', () {
      var history = History<int>(0, limit: 2);

      history = history.withPresent(1);
      history = history.withPresent(2);
      history = history.withPresent(3);

      expect(history.present, 3);
      expect(history.pastLength, 2);

      history = history.undo();
      expect(history.present, 2);

      history = history.undo();
      expect(history.present, 1);

      expect(history.canUndo, isFalse);
    });

    test('zero limit retains no undo history', () {
      var history = History<int>(1, limit: 0);

      history = history.withPresent(2);

      expect(history.present, 2);
      expect(history.canUndo, isFalse);
      expect(history.pastLength, 0);
    });

    test('clear retains present and removes undo and redo stacks', () {
      var history = History<int>(1);

      history = history.withPresent(2);
      history = history.withPresent(3);
      history = history.undo();

      expect(history.canUndo, isTrue);
      expect(history.canRedo, isTrue);

      history = history.clear();

      expect(history.present, 2);
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
      expect(history.pastLength, 0);
      expect(history.futureLength, 0);
    });
  });
}
