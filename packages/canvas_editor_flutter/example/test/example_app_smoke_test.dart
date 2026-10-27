// Path: packages/canvas_editor_flutter/example/test/example_app_smoke_test.dart

import 'dart:async';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/canvas_editor_flutter.dart'
    show CanvasSceneEditor;
import 'package:canvas_editor_flutter_example/main.dart';
import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('example launches with public editor capabilities', (
    tester,
  ) async {
    final bundle = await _iconBundle(tester);
    await tester.pumpWidget(_app(bundle));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CanvasSceneEditor), findsOneWidget);
    final editor = tester.widget<CanvasSceneEditor>(
      find.byType(CanvasSceneEditor),
    );
    final icon = editor.initialScene.children.whereType<IconNode>().single;
    expect(editor.resources.icons.resolve(icon.data.iconRef), isNotNull);
    expect(editor.resources.icons.items, hasLength(3));
    expect(editor.pngExport, isNotNull);
  });

  testWidgets('example icon can be replaced through the existing inspector', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bundle = await _iconBundle(tester);
    await tester.pumpWidget(_app(bundle));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vector icon'));
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('icon-ref:icon.ring')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diamond').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('icon-ref:icon.diamond')), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(bundle.iconLoads, hasLength(3));
  });

  testWidgets('editor waits for icon preparation', (tester) async {
    final gate = Completer<void>();
    final bundle = await _iconBundle(tester, gate: gate);
    await tester.pumpWidget(_app(bundle));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(CanvasSceneEditor), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CanvasSceneEditor), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed icon preparation shows a failure state', (tester) async {
    await tester.pumpWidget(_app(_IconBundle(const {})));
    await tester.pumpAndSettle();

    expect(find.text('Unable to load example icons.'), findsOneWidget);
    expect(find.byType(CanvasSceneEditor), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(AssetBundle bundle) =>
    DefaultAssetBundle(bundle: bundle, child: const CanvasEditorExampleApp());

Future<_IconBundle> _iconBundle(
  WidgetTester tester, {
  Completer<void>? gate,
}) async {
  final assets = await tester.runAsync(
    () async => {
      for (final name in ['diamond', 'ring', 'arrow'])
        'assets/icons/$name.json': await rootBundle.load(
          'assets/icons/$name.json',
        ),
    },
  );
  return _IconBundle(assets!, gate: gate);
}

final class _IconBundle extends CachingAssetBundle {
  _IconBundle(this.assets, {this.gate});

  final Map<String, ByteData> assets;
  final Completer<void>? gate;
  final List<String> iconLoads = [];

  @override
  Future<ByteData> load(String key) async {
    if (!key.startsWith('assets/icons/')) return rootBundle.load(key);
    iconLoads.add(key);
    if (gate != null) await gate!.future;
    final data = assets[key];
    if (data == null) throw FlutterError('Missing icon fixture: $key');
    return data;
  }
}
