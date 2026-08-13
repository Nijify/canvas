import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

CanvasSceneDocument _scene({
  Size2D artboardSize = const Size2D(740, 360),
  CanvasFill backgroundFill = const CanvasFill.none(),
  double backgroundOpacity = 1.0,
  List<Node> children = const <Node>[],
}) {
  return CanvasSceneDocument(
    artboardSize: artboardSize,
    backgroundFill: backgroundFill,
    backgroundOpacity: backgroundOpacity,
    children: children,
  );
}

Node _text(String id, {String? name, Transform2D xf = const Transform2D()}) {
  return Node.text(
    id: id,
    name: name,
    xf: xf,
    data: const TextData(
      text: 'Hello',
      fontFamily: 'Inter',
      fontWeight: 400,
      fontSize: 16,
    ),
  );
}

List<String> _signature(List<CanvasSceneValidationIssue> issues) => [
  for (final issue in issues)
    '${issue.code.name}|${issue.path}|${issue.relatedPath ?? ''}',
];

void main() {
  group('validateCanvasSceneDocument', () {
    test('accepts a valid empty scene', () {
      expect(validateCanvasSceneDocument(_scene()), isEmpty);
    });

    test('accepts unknown well-formed group behavior', () {
      final scene = _scene(
        children: <Node>[
          _text(
            'text',
            xf: const Transform2D(
              origin: OriginKind.custom,
              customPivotPx: null,
            ),
          ),
          Node.group(
            id: 'future-component',
            behavior: GroupBehaviorRef(
              type: 'canvas.future_component',
              version: 999,
              data: <String, dynamic>{
                'enabled': true,
                'count': 3,
                'label': 'Future',
                'nested': <dynamic>[
                  null,
                  <String, dynamic>{'ok': true},
                ],
              },
            ),
            children: const <Node>[],
          ),
        ],
      );

      expect(validateCanvasSceneDocument(scene), isEmpty);
    });

    test('reports nested duplicate node IDs with the first occurrence', () {
      final scene = _scene(
        children: <Node>[
          _text('duplicate'),
          Node.group(id: 'group', children: <Node>[_text('duplicate')]),
        ],
      );

      final issues = validateCanvasSceneDocument(scene);

      expect(issues, hasLength(1));
      expect(issues.single.code, CanvasSceneValidationCode.duplicateNodeId);
      expect(issues.single.path, '/children/1/children/0/id');
      expect(issues.single.relatedPath, '/children/0/id');
    });

    test('reports blank IDs and names longer than 80 characters', () {
      final scene = _scene(
        children: <Node>[
          _text('   ', name: List<String>.filled(81, 'x').join()),
        ],
      );

      final issues = validateCanvasSceneDocument(scene);

      expect(_signature(issues), <String>[
        'blankNodeId|/children/0/id|',
        'nameTooLong|/children/0/name|',
      ]);
    });

    test('validates document ranges, colors, and gradient values in order', () {
      final scene = _scene(
        artboardSize: const Size2D(0, double.infinity),
        backgroundFill: const CanvasFill.gradient(
          LinearGradientSpec(
            color1: -1,
            color2: 0x100000000,
            angle: double.infinity,
            width: 51,
          ),
        ),
        backgroundOpacity: -0.1,
      );

      final issues = validateCanvasSceneDocument(scene);

      expect(_signature(issues), <String>[
        'valueOutOfRange|/artboardSize/w|',
        'nonFiniteNumber|/artboardSize/h|',
        'invalidColor|/backgroundFill/grad/color1|',
        'invalidColor|/backgroundFill/grad/color2|',
        'nonFiniteNumber|/backgroundFill/grad/angle|',
        'valueOutOfRange|/backgroundFill/grad/width|',
        'valueOutOfRange|/backgroundOpacity|',
      ]);
    });

    test('validates transforms and path numeric values', () {
      final scene = _scene(
        children: <Node>[
          Node.path(
            id: 'path',
            xf: const Transform2D(
              position: Vec2(double.nan, 0),
              rotationRad: double.infinity,
              scale: Vec2(1, double.nan),
              origin: OriginKind.custom,
              customPivotPx: Vec2(double.infinity, 0),
            ),
            data: const PathData(
              points: <Vec2?>[Vec2(double.nan, 0)],
              source: CircleSource(double.infinity),
              strokeWidth: -1,
              miterLimit: -1,
              dash: <double>[double.infinity, -1],
            ),
          ),
        ],
      );

      final issues = validateCanvasSceneDocument(scene);

      expect(
        _signature(issues),
        containsAll(<String>[
          'nonFiniteNumber|/children/0/xf/position/x|',
          'nonFiniteNumber|/children/0/xf/rotationRad|',
          'nonFiniteNumber|/children/0/xf/scale/y|',
          'nonFiniteNumber|/children/0/xf/customPivotPx/x|',
          'nonFiniteNumber|/children/0/data/points/0/x|',
          'nonFiniteNumber|/children/0/data/source/r|',
          'valueOutOfRange|/children/0/data/strokeWidth|',
          'valueOutOfRange|/children/0/data/miterLimit|',
          'nonFiniteNumber|/children/0/data/dash/0|',
          'valueOutOfRange|/children/0/data/dash/1|',
        ]),
      );
    });

    test('custom origin does not require a custom pivot', () {
      final scene = _scene(
        children: <Node>[
          _text('text', xf: const Transform2D(origin: OriginKind.custom)),
        ],
      );

      expect(validateCanvasSceneDocument(scene), isEmpty);
    });

    test('validates a custom pivot when one is present', () {
      final scene = _scene(
        children: <Node>[
          _text(
            'text',
            xf: const Transform2D(
              origin: OriginKind.custom,
              customPivotPx: Vec2(double.nan, double.infinity),
            ),
          ),
        ],
      );

      expect(_signature(validateCanvasSceneDocument(scene)), <String>[
        'nonFiniteNumber|/children/0/xf/customPivotPx/x|',
        'nonFiniteNumber|/children/0/xf/customPivotPx/y|',
      ]);
    });

    test('validates the generic behavior envelope only', () {
      final scene = _scene(
        children: <Node>[
          Node.group(
            id: 'component',
            behavior: const GroupBehaviorRef(
              type: '   ',
              version: 0,
              data: <String, dynamic>{},
            ),
            children: const <Node>[],
          ),
        ],
      );

      expect(_signature(validateCanvasSceneDocument(scene)), <String>[
        'invalidBehaviorType|/children/0/behavior/type|',
        'invalidBehaviorVersion|/children/0/behavior/version|',
      ]);
    });

    test('behavior data is JSON-safe and uses sorted escaped paths', () {
      final scene = _scene(
        children: <Node>[
          Node.group(
            id: 'component',
            behavior: GroupBehaviorRef(
              type: 'canvas.future',
              version: 7,
              data: <String, dynamic>{
                'z': double.infinity,
                'bad': Object(),
                'a/b~c': double.nan,
              },
            ),
            children: const <Node>[],
          ),
        ],
      );

      expect(_signature(validateCanvasSceneDocument(scene)), <String>[
        'nonFiniteNumber|/children/0/behavior/data/a~1b~0c|',
        'nonJsonBehaviorValue|/children/0/behavior/data/bad|',
        'nonFiniteNumber|/children/0/behavior/data/z|',
      ]);
    });

    test('behavior data cycles terminate deterministically', () {
      final data = <String, dynamic>{};
      final behavior = GroupBehaviorRef(
        type: 'canvas.future',
        version: 1,
        data: data,
      );

      data['self'] = data;

      final scene = _scene(
        children: <Node>[
          Node.group(
            id: 'component',
            behavior: behavior,
            children: const <Node>[],
          ),
        ],
      );

      final issues = validateCanvasSceneDocument(scene);
      final cycleIssues = issues
          .where(
            (issue) =>
                issue.code == CanvasSceneValidationCode.cyclicBehaviorData,
          )
          .toList();

      expect(cycleIssues, hasLength(1));
      expect(cycleIssues.single.path, contains('/behavior/data/self'));
    });

    test('scene graph cycles terminate deterministically', () {
      final children = <Node>[];
      final group = Node.group(id: 'group', children: children);

      // Freezed keeps the supplied collection as the underlying collection, so
      // malformed in-memory callers can still create a cycle after construction.
      children.add(group);

      final scene = _scene(children: <Node>[group]);
      final issues = validateCanvasSceneDocument(scene);

      expect(
        issues.map((issue) => issue.code),
        contains(CanvasSceneValidationCode.cyclicNodeGraph),
      );
    });

    test('node-name limit counts Unicode code points, not UTF-16 units', () {
      final eightyEmoji = List<String>.filled(80, '😀').join();
      final eightyOneEmoji = List<String>.filled(81, '😀').join();

      expect(
        validateCanvasSceneDocument(
          _scene(children: <Node>[_text('valid', name: eightyEmoji)]),
        ),
        isEmpty,
      );

      expect(
        _signature(
          validateCanvasSceneDocument(
            _scene(children: <Node>[_text('invalid', name: eightyOneEmoji)]),
          ),
        ),
        <String>['nameTooLong|/children/0/name|'],
      );
    });

    test('validates explicit image dimensions and alignment', () {
      final scene = _scene(
        children: <Node>[
          Node.image(
            id: 'image',
            data: const ImageData(size: Size2D(-1, 0), align: Vec2(-0.1, 1.1)),
          ),
        ],
      );

      expect(_signature(validateCanvasSceneDocument(scene)), <String>[
        'valueOutOfRange|/children/0/data/size/w|',
        'valueOutOfRange|/children/0/data/size/h|',
        'valueOutOfRange|/children/0/data/align/x|',
        'valueOutOfRange|/children/0/data/align/y|',
      ]);
    });

    test('regular polygon requires at least three sides', () {
      final scene = _scene(
        children: <Node>[
          Node.path(
            id: 'polygon',
            data: const PathData(source: RegularPolygonSource(2, 10)),
          ),
        ],
      );

      expect(_signature(validateCanvasSceneDocument(scene)), <String>[
        'valueOutOfRange|/children/0/data/source/sides|',
      ]);
    });

    test('multiple errors have deterministic codes, paths, and ordering', () {
      final scene = _scene(
        artboardSize: const Size2D(0, 360),
        backgroundOpacity: 2,
        children: <Node>[
          _text('duplicate'),
          Node.group(
            id: 'group',
            behavior: const GroupBehaviorRef(
              type: '',
              version: 0,
              data: <String, dynamic>{},
            ),
            children: <Node>[_text('duplicate')],
          ),
        ],
      );

      final first = validateCanvasSceneDocument(scene);
      final second = validateCanvasSceneDocument(scene);

      expect(_signature(first), _signature(second));
      expect(_signature(first), <String>[
        'valueOutOfRange|/artboardSize/w|',
        'valueOutOfRange|/backgroundOpacity|',
        'invalidBehaviorType|/children/1/behavior/type|',
        'invalidBehaviorVersion|/children/1/behavior/version|',
        'duplicateNodeId|/children/1/children/0/id|/children/0/id',
      ]);
    });
  });
}
