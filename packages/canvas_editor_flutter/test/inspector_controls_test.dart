import 'package:canvas_editor_flutter/src/presentation/inspector/controls.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('swatches expose selection and a 48-pixel tap target', (
    tester,
  ) async {
    var picked = 0;
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwatchPickerRow(
              label: 'Fill',
              swatchesArgb32: const [0xFF000000, 0xFFFFFFFF],
              selectedArgb32: 0xFF000000,
              onPick: (value) => picked = value,
            ),
          ),
        ),
      );

      final white = find.bySemanticsLabel('Fill, color FFFFFFFF');
      expect(white, findsOneWidget);
      expect(tester.getSize(white), const Size(48, 48));
      await tester.tap(white);
      expect(picked, 0xFFFFFFFF);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'dropdown uses current selection and disables unavailable items',
    (tester) async {
      Future<void> showDropdown(String value) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LabeledDropdown<String>(
              value: value,
              items: const [
                DropdownMenuItem(value: 'a', child: Text('Alpha')),
                DropdownMenuItem(
                  value: 'b',
                  enabled: false,
                  child: Text('Beta'),
                ),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await showDropdown('a');
      var menu = tester.widget<DropdownMenu<String>>(
        find.byType(DropdownMenu<String>),
      );
      expect(menu.initialSelection, 'a');
      expect(menu.dropdownMenuEntries.last.enabled, isFalse);

      await showDropdown('b');
      menu = tester.widget<DropdownMenu<String>>(
        find.byType(DropdownMenu<String>),
      );
      expect(menu.initialSelection, 'b');
    },
  );
}
