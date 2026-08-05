// Path: packages/canvas_core/test/group_behavior_ref_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:test/test.dart';

void main() {
  group('GroupBehaviorRef', () {
    test('round-trips an explicit behavior envelope', () {
      const ref = GroupBehaviorRef(
        type: 'canvas.logo',
        version: 1,
        data: <String, dynamic>{'layout': 'horizontal'},
      );

      expect(GroupBehaviorRef.fromJson(ref.toJson()), ref);
    });

    test('rejects a missing type', () {
      expect(
        () => GroupBehaviorRef.fromJson(const <String, dynamic>{
          'version': 1,
          'data': <String, dynamic>{},
        }),
        throwsA(anything),
      );
    });

    test('rejects a missing version', () {
      expect(
        () => GroupBehaviorRef.fromJson(const <String, dynamic>{
          'type': 'canvas.logo',
          'data': <String, dynamic>{},
        }),
        throwsA(anything),
      );
    });

    test('rejects missing data', () {
      expect(
        () => GroupBehaviorRef.fromJson(const <String, dynamic>{
          'type': 'canvas.logo',
          'version': 1,
        }),
        throwsA(anything),
      );
    });

    test('rejects a non-integer version', () {
      expect(
        () => GroupBehaviorRef.fromJson(const <String, dynamic>{
          'type': 'canvas.logo',
          'version': '1',
          'data': <String, dynamic>{},
        }),
        throwsA(anything),
      );
    });

    test('rejects non-object data', () {
      expect(
        () => GroupBehaviorRef.fromJson(const <String, dynamic>{
          'type': 'canvas.logo',
          'version': 1,
          'data': 'not-an-object',
        }),
        throwsA(anything),
      );
    });
  });
}
