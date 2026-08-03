// Path: oss_packages/canvas_editor_flutter/test/inspector_action_group_test.dart

import 'package:canvas_editor_flutter/src/presentation/inspector/inspector_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _galleryKey = ValueKey('test-gallery-action');
const _cameraKey = ValueKey('test-camera-action');

Future<void> _pumpActionGroup(
  WidgetTester tester, {
  required double width,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: InspectorActionGroup(
                children: <Widget>[
                  ElevatedButton.icon(
                    key: _galleryKey,
                    onPressed: () {},
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                  ElevatedButton.icon(
                    key: _cameraKey,
                    onPressed: () {},
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Camera'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('stacks inspector actions below the compact width', (
    tester,
  ) async {
    await _pumpActionGroup(tester, width: InspectorUi.compactWidth - 1);

    final gallery = tester.getRect(find.byKey(_galleryKey));
    final camera = tester.getRect(find.byKey(_cameraKey));

    expect(camera.top, greaterThanOrEqualTo(gallery.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out inspector actions horizontally at the compact width', (
    tester,
  ) async {
    await _pumpActionGroup(tester, width: InspectorUi.compactWidth);

    final gallery = tester.getRect(find.byKey(_galleryKey));
    final camera = tester.getRect(find.byKey(_cameraKey));

    expect(camera.left, greaterThan(gallery.right));
    expect(gallery.top, closeTo(camera.top, 0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits image actions at the reported inspector width', (
    tester,
  ) async {
    await _pumpActionGroup(tester, width: 363.4);

    final gallery = tester.getRect(find.byKey(_galleryKey));
    final camera = tester.getRect(find.byKey(_cameraKey));

    expect(camera.left, greaterThan(gallery.right));
    expect((gallery.width - camera.width).abs(), lessThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('stacks actions when system text is substantially enlarged', (
    tester,
  ) async {
    await _pumpActionGroup(
      tester,
      width: 363.4,
      textScaler: const TextScaler.linear(2),
    );

    final gallery = tester.getRect(find.byKey(_galleryKey));
    final camera = tester.getRect(find.byKey(_cameraKey));

    expect(camera.top, greaterThanOrEqualTo(gallery.bottom));
    expect(tester.takeException(), isNull);
  });
}
