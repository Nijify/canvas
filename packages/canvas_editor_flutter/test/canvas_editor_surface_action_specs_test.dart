// Path: oss_packages/canvas_editor_flutter/test/canvas_editor_surface_action_specs_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'editor_runtime_fakes.dart';

const _lifecycleActionId = EditorActionId('test.action.lifecycle');

CanvasSceneDocument _fixtureScene() {
  return CanvasSceneDocument(
    artboardSize: const Size2D(300, 200),
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1.0,
    children: const <Node>[],
  );
}

final class _ActionMarker {
  const _ActionMarker();
}

final class _LifecycleActionExtension
    extends EditorExtension<CanvasSceneDocument> {
  int scenePreparerReads = 0;
  int fieldCodecsReads = 0;
  int surfaceFeaturesReads = 0;
  int actionSpecsReads = 0;
  int providerBuildReads = 0;
  int inspectorFieldRowBuilderReads = 0;

  final List<String> events = <String>[];

  bool _attached = false;
  bool _enabled = false;
  VoidCallback? _requestRebuild;

  _ActionMarker? invokedMarker;

  @override
  ScenePreparer? get scenePreparer {
    scenePreparerReads++;
    events.add('scenePreparer');
    return null;
  }

  @override
  Map<CanvasFieldKey, FieldCodec> get fieldCodecs {
    fieldCodecsReads++;
    events.add('fieldCodecs');
    return const <CanvasFieldKey, FieldCodec>{};
  }

  @override
  EditorSurfaceFeatures get surfaceFeatures {
    surfaceFeaturesReads++;
    events.add('surfaceFeatures');
    return const EditorSurfaceFeatures();
  }

  @override
  void attach(EditorExtensionContext<CanvasSceneDocument> context) {
    events.add('attach');
    _attached = true;
    _requestRebuild = context.requestRebuild;
  }

  @override
  List<SingleChildWidget> buildProviders() {
    providerBuildReads++;

    return <SingleChildWidget>[
      Provider<_ActionMarker>.value(value: const _ActionMarker()),
    ];
  }

  @override
  InspectorFieldRowBuilder? get inspectorFieldRowBuilder {
    inspectorFieldRowBuilderReads++;
    return null;
  }

  @override
  List<EditorActionSpec> get actionSpecs {
    if (!_attached) {
      throw StateError('actionSpecs must be read after attach');
    }

    actionSpecsReads++;
    events.add('actionSpecs');

    return <EditorActionSpec>[
      EditorActionSpec(
        id: _lifecycleActionId,
        section: EditorToolbarSection.edit,
        labelBuilder: (_) => _enabled ? 'Enabled action' : 'Disabled action',
        iconBuilder: (_) => Icons.bolt_outlined,
        isEnabled: (_) => _enabled,
        isVisible: (_) => true,
        invoke: (context) {
          invokedMarker = context.buildContext.read<_ActionMarker>();
        },
      ),
    ];
  }

  void setEnabled(bool value) {
    _enabled = value;
    _requestRebuild?.call();
  }
}

final class _FixedActionExtension extends EditorExtension<CanvasSceneDocument> {
  const _FixedActionExtension(this.id);

  final EditorActionId id;

  @override
  List<EditorActionSpec> get actionSpecs {
    return <EditorActionSpec>[
      EditorActionSpec(
        id: id,
        section: EditorToolbarSection.edit,
        labelBuilder: (_) => id.value,
        iconBuilder: (_) => Icons.circle_outlined,
        isEnabled: (_) => true,
        isVisible: (_) => true,
        invoke: (_) {},
      ),
    ];
  }
}

final class _InspectorBuilderExtension
    extends EditorExtension<CanvasSceneDocument> {
  const _InspectorBuilderExtension(this.builder);

  final InspectorBuilder builder;

  @override
  EditorSurfaceFeatures get surfaceFeatures {
    return EditorSurfaceFeatures(inspectorBuilder: builder);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'reads construction seams before attach, freezes action specs, and keeps '
    'providers and inspector rows as build-time hooks',
    (tester) async {
      final extension = _LifecycleActionExtension();

      EditorToolbarState? observedState;
      List<EditorActionSpec>? observedSpecs;
      EditorActionDispatcher? observedDispatcher;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox.expand(
            child: CanvasSceneEditor(
              initialScene: _fixtureScene(),
              resources: canvasRuntimeResourcesForTest(),
              extensions: <EditorExtension<CanvasSceneDocument>>[extension],
              appBarBuilder: (_, state, actions, specs) {
                observedState = state;
                observedSpecs = specs;
                observedDispatcher = actions;

                return const PreferredSize(
                  preferredSize: Size.zero,
                  child: SizedBox.shrink(),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(extension.events.take(5).toList(), <String>[
        'scenePreparer',
        'fieldCodecs',
        'surfaceFeatures',
        'attach',
        'actionSpecs',
      ]);

      expect(extension.scenePreparerReads, 1);
      expect(extension.fieldCodecsReads, 1);
      expect(extension.surfaceFeaturesReads, 1);
      expect(extension.actionSpecsReads, 1);

      expect(extension.providerBuildReads, greaterThanOrEqualTo(1));
      expect(extension.inspectorFieldRowBuilderReads, greaterThanOrEqualTo(1));

      expect(observedState, isNotNull);
      expect(observedSpecs, isNotNull);
      expect(observedDispatcher, isNotNull);

      final initialProviderBuildReads = extension.providerBuildReads;
      final initialInspectorFieldRowBuilderReads =
          extension.inspectorFieldRowBuilderReads;

      final initialSpecs = observedSpecs!;
      final initialAction = initialSpecs.singleWhere(
        (spec) => spec.id == _lifecycleActionId,
      );

      expect(initialAction.labelBuilder(observedState!), 'Disabled action');
      expect(initialAction.isEnabled(observedState!), isFalse);

      extension.setEnabled(true);
      await tester.pump();

      expect(extension.scenePreparerReads, 1);
      expect(extension.fieldCodecsReads, 1);
      expect(extension.surfaceFeaturesReads, 1);
      expect(extension.actionSpecsReads, 1);

      expect(
        extension.providerBuildReads,
        greaterThan(initialProviderBuildReads),
      );
      expect(
        extension.inspectorFieldRowBuilderReads,
        greaterThan(initialInspectorFieldRowBuilderReads),
      );

      expect(identical(observedSpecs, initialSpecs), isTrue);

      final updatedAction = observedSpecs!.singleWhere(
        (spec) => spec.id == _lifecycleActionId,
      );
      expect(updatedAction.labelBuilder(observedState!), 'Enabled action');
      expect(updatedAction.isEnabled(observedState!), isTrue);

      observedDispatcher!.invoke(_lifecycleActionId);
      await tester.pump();

      expect(extension.invokedMarker, isA<_ActionMarker>());
    },
  );

  testWidgets(
    'base inspector and base actions are intrinsic without extensions',
    (tester) async {
      List<EditorActionSpec>? observedSpecs;
      EditorActionDispatcher? observedDispatcher;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox.expand(
            child: CanvasSceneEditor(
              initialScene: _fixtureScene(),
              resources: canvasRuntimeResourcesForTest(),
              appBarBuilder: (_, _, actions, specs) {
                observedDispatcher = actions;
                observedSpecs = specs;

                return const PreferredSize(
                  preferredSize: Size.zero,
                  child: SizedBox.shrink(),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Background'), findsOneWidget);
      expect(observedSpecs, isNotNull);
      expect(observedDispatcher, isNotNull);

      final ids = observedSpecs!.map((spec) => spec.id).toList(growable: false);

      expect(
        observedSpecs!
            .where((spec) => spec.section == EditorToolbarSection.edit)
            .map((spec) => spec.id)
            .toSet(),
        <EditorActionId>{
          EditorActionIds.duplicate,
          EditorActionIds.deleteSelection,
        },
      );

      for (final id in <EditorActionId>[
        EditorActionIds.undo,
        EditorActionIds.redo,
        EditorActionIds.deleteSelection,
        EditorActionIds.bringToFront,
        EditorActionIds.addText,
        EditorActionIds.addRect,
      ]) {
        expect(
          ids.where((candidate) => candidate == id),
          hasLength(1),
          reason: '$id should be installed exactly once',
        );

        expect(observedDispatcher!.canInvoke(id), isTrue);
      }
    },
  );

  testWidgets(
    'custom inspector returning null delegates to the intrinsic inspector',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox.expand(
            child: CanvasSceneEditor(
              initialScene: _fixtureScene(),
              resources: canvasRuntimeResourcesForTest(),
              extensions: <EditorExtension<CanvasSceneDocument>>[
                _InspectorBuilderExtension((_) => null),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Background'), findsOneWidget);
    },
  );

  testWidgets(
    'custom inspector can deliberately suppress the intrinsic inspector',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox.expand(
            child: CanvasSceneEditor(
              initialScene: _fixtureScene(),
              resources: canvasRuntimeResourcesForTest(),
              extensions: <EditorExtension<CanvasSceneDocument>>[
                _InspectorBuilderExtension((_) => const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Background'), findsNothing);
    },
  );

  testWidgets(
    'rejects a custom action that collides with an intrinsic base action',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox.expand(
            child: CanvasSceneEditor(
              initialScene: _fixtureScene(),
              resources: canvasRuntimeResourcesForTest(),
              extensions: const <EditorExtension<CanvasSceneDocument>>[
                _FixedActionExtension(EditorActionIds.undo),
              ],
            ),
          ),
        ),
      );

      expect(
        tester.takeException(),
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains(EditorActionIds.undo.value),
        ),
      );
    },
  );

  testWidgets('rejects duplicate action IDs during editor setup', (
    tester,
  ) async {
    const duplicateId = EditorActionId('test.action.duplicate');

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: CanvasSceneEditor(
            initialScene: _fixtureScene(),
            resources: canvasRuntimeResourcesForTest(),
            extensions: const <EditorExtension<CanvasSceneDocument>>[
              _FixedActionExtension(duplicateId),
              _FixedActionExtension(duplicateId),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.takeException(),
      isA<StateError>().having(
        (error) => error.message,
        'message',
        contains(duplicateId.value),
      ),
    );
  });
}
