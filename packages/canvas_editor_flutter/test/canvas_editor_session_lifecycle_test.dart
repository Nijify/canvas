// Path: oss_packages/canvas_editor_flutter/test/canvas_editor_session_lifecycle_test.dart
import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/extensions.dart';
import 'package:canvas_editor_flutter/src/interaction/selection_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'editor_runtime_fakes.dart';

CanvasRuntimeResources _resources(String tag) {
  return canvasRuntimeResourcesForTest(icons: _TaggedIconCatalog(tag));
}

final class _TaggedIconCatalog implements IconCatalogPort {
  const _TaggedIconCatalog(this.tag);

  final String tag;

  @override
  List<IconCatalogItem> get items => const <IconCatalogItem>[];

  @override
  Map<String, ResolvedIcon> get resolveMap => const <String, ResolvedIcon>{};

  @override
  ResolvedIcon? resolve(String iconRef) => null;
}

String _resourceTag(CanvasRuntimeResources resources) {
  return (resources.icons as _TaggedIconCatalog).tag;
}

CanvasSceneDocument _scene(String seedId) {
  return CanvasSceneDocument(
    artboardSize: const Size2D(300, 200),
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1.0,
    children: <Node>[
      const Node.text(
        id: 'placeholder',
        xf: Transform2D(position: Vec2(40, 40)),
        data: TextData(
          text: 'Seed',
          fontFamily: 'TestFont',
          fontWeight: 400,
          fontSize: 18,
          letterSpacing: 0,
          fill: CanvasFill.solid(0xFF111111),
          shadowOffset: 0,
        ),
      ).copyWith(id: seedId),
    ],
  );
}

void _addLocalEdit(EditorController controller) {
  controller.applyEdit(
    EditorEdits.addNode(
      const Node.text(
        id: 'local-edit',
        xf: Transform2D(position: Vec2(120, 80)),
        data: TextData(
          text: 'Local edit',
          fontFamily: 'TestFont',
          fontWeight: 400,
          fontSize: 18,
          letterSpacing: 0,
          fill: CanvasFill.solid(0xFF111111),
          shadowOffset: 0,
        ),
      ),
    ),
  );
}

final class _ResourceProbeExtension
    extends EditorExtension<CanvasSceneDocument> {
  _ResourceProbeExtension(this.actionResourceTags);

  static const actionId = EditorActionId('test.resourceProbe');

  final List<String> actionResourceTags;

  @override
  EditorSurfaceFeatures get surfaceFeatures {
    return EditorSurfaceFeatures(
      inspectorBuilder: (context) {
        return Text('inspector-resource:${_resourceTag(context.resources)}');
      },
    );
  }

  @override
  List<EditorActionSpec> get actionSpecs {
    return <EditorActionSpec>[
      EditorActionSpec(
        id: actionId,
        section: EditorToolbarSection.edit,
        labelBuilder: (_) => 'Probe resources',
        iconBuilder: (_) => Icons.bug_report_outlined,
        isEnabled: (_) => true,
        isVisible: (_) => true,
        invoke: (ctx) {
          actionResourceTags.add(_resourceTag(ctx.resources));
        },
      ),
    ];
  }
}

Future<
  ({
    EditorController controller,
    SelectionController selection,
    EditorActionDispatcher actions,
  })
>
_pumpEditor(
  WidgetTester tester, {
  required Key key,
  required CanvasSceneDocument scene,
  required CanvasRuntimeResources resources,
  required _ResourceProbeExtension probe,
}) async {
  late EditorActionDispatcher capturedActions;

  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox.expand(
        child: CanvasSceneEditor(
          key: key,
          initialScene: scene,
          resources: resources,
          extensions: <EditorExtension<CanvasSceneDocument>>[probe],
          appBarBuilder: (_, _, actions, _) {
            capturedActions = actions;
            return null;
          },
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();

  final context = tester.element(find.byType(Scaffold).first);

  return (
    controller: context.read<EditorController>(),
    selection: Provider.of<SelectionController>(context, listen: false),
    actions: capturedActions,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'same key preserves the active edited document when initialScene changes',
    (tester) async {
      final resources = _resources('A');
      final probe = _ResourceProbeExtension(<String>[]);

      final first = await _pumpEditor(
        tester,
        key: const ValueKey<String>('editor-session'),
        scene: _scene('seed-a'),
        resources: resources,
        probe: probe,
      );

      _addLocalEdit(first.controller);
      await tester.pumpAndSettle();

      expect(first.controller.canUndo.value, isTrue);

      final rebuilt = await _pumpEditor(
        tester,
        key: const ValueKey<String>('editor-session'),
        scene: _scene('seed-b'),
        resources: resources,
        probe: probe,
      );

      expect(rebuilt.controller, same(first.controller));

      final ids = rebuilt.controller.document.value.children
          .map((node) => node.id)
          .toSet();

      expect(ids, containsAll(<String>{'seed-a', 'local-edit'}));
      expect(ids, isNot(contains('seed-b')));
      expect(rebuilt.controller.canUndo.value, isTrue);
    },
  );

  testWidgets(
    'same key keeps action and inspector resources aligned with the session',
    (tester) async {
      final probe = _ResourceProbeExtension(<String>[]);

      final first = await _pumpEditor(
        tester,
        key: const ValueKey<String>('editor-session'),
        scene: _scene('seed'),
        resources: _resources('A'),
        probe: probe,
      );

      expect(find.text('inspector-resource:A'), findsOneWidget);
      expect(find.text('Background'), findsNothing);

      first.actions.invoke(_ResourceProbeExtension.actionId);
      await tester.pump();

      expect(probe.actionResourceTags, <String>['A']);

      final rebuilt = await _pumpEditor(
        tester,
        key: const ValueKey<String>('editor-session'),
        scene: _scene('seed'),
        resources: _resources('B'),
        probe: probe,
      );

      expect(rebuilt.controller, same(first.controller));

      expect(find.text('inspector-resource:A'), findsOneWidget);
      expect(find.text('inspector-resource:B'), findsNothing);
      expect(find.text('Background'), findsNothing);

      rebuilt.actions.invoke(_ResourceProbeExtension.actionId);
      await tester.pump();

      expect(probe.actionResourceTags, <String>['A', 'A']);
    },
  );

  testWidgets('a new key creates a fresh document and resource session', (
    tester,
  ) async {
    final probe = _ResourceProbeExtension(<String>[]);

    final first = await _pumpEditor(
      tester,
      key: const ValueKey<String>('editor-a'),
      scene: _scene('seed-a'),
      resources: _resources('A'),
      probe: probe,
    );

    _addLocalEdit(first.controller);
    first.selection.selectItems(<String>['local-edit']);
    await tester.pumpAndSettle();

    expect(first.controller.canUndo.value, isTrue);
    expect(first.selection.value.ids, contains('local-edit'));

    final rebuilt = await _pumpEditor(
      tester,
      key: const ValueKey<String>('editor-b'),
      scene: _scene('seed-b'),
      resources: _resources('B'),
      probe: probe,
    );

    expect(rebuilt.controller, isNot(same(first.controller)));

    final ids = rebuilt.controller.document.value.children
        .map((node) => node.id)
        .toSet();

    expect(ids, equals(<String>{'seed-b'}));
    expect(rebuilt.controller.canUndo.value, isFalse);
    expect(rebuilt.controller.canRedo.value, isFalse);
    expect(rebuilt.selection.value.hasItems, isFalse);

    expect(find.text('inspector-resource:B'), findsOneWidget);

    rebuilt.actions.invoke(_ResourceProbeExtension.actionId);
    await tester.pump();

    expect(probe.actionResourceTags, <String>['B']);
  });
}
