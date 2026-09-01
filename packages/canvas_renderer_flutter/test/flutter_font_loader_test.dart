import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter/services.dart' show CachingAssetBundle;
import 'package:flutter_test/flutter_test.dart';

const _testFontBase64 =
    'AAEAAAAKAIAAAwAgT1MvMkUAQ/IAAAEoAAAAYGNtYXAAdABcAAABlAAAADxnbHlm'
    'GN77eQAAAdgAAAAYaGVhZC7jR0wAAACsAAAANmhoZWEEsgJcAAAA5AAAACRobXR4'
    'BkAAAAAAAYgAAAAMbG9jYQAAAAwAAAHQAAAACG1heHAABQAFAAABCAAAACBuYW1l'
    '8jNN8AAAAfAAAAELcG9zdAAIACQAAAL8AAAAKAABAAAAAQAAkMbsHl8PPPUAAQPo'
    'AAAAAOa7gdgAAAAA5ruB2ABkAAAB9AK8AAAAAwACAAAAAAAAAAEAAAMg/zgAAAJY'
    'AAAAyAGQAAEAAAAAAAAAAAAAAAAAAAADAAEAAAADAAMAAQAAAAAAAgAAAAAAAAAA'
    'AAAAAAAAAAAAAwIVAZAABQAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
    'AAAAAAABAAAAAAAAAAAAAAAAPz8/PwAAACAAQQMg/zgAAAMgAMgAAAAAAAAAAAAA'
    'AAAAAAAAAAAgAAAB9AAAAfQAAAJYAAAAAAACAAAAAwAAABQAAwABAAAAFAAEACgA'
    'AAAGAAQAAQACACAAQf//AAAAIABB////4f/BAAEAAAAAAAAAAAAAAAAADAABAGQA'
    'AAH0ArwAAgAAMxMTZMjIArz9RAAAAAoAfgABAAAAAAABAAgAAAABAAAAAAACAAcA'
    'CAABAAAAAAADABAADwABAAAAAAAEABAADwABAAAAAAAGABAAHwADAAEECQABABAA'
    'LwADAAEECQACAA4APwADAAEECQADACAATQADAAEECQAEACAATQADAAEECQAGACAA'
    'bVRlc3RGb250UmVndWxhclRlc3RGb250IFJlZ3VsYXJUZXN0Rm9udC1SZWd1bGFy'
    'AFQAZQBzAHQARgBvAG4AdABSAGUAZwB1AGwAYQByAFQAZQBzAHQARgBvAG4AdAAg'
    'AFIAZQBnAHUAbABhAHIAVABlAHMAdABGAG8AbgB0AC0AUgBlAGcAdQBsAGEAcgAA'
    'AgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAAAAAwAk';

ByteData _testFontBytes() {
  return ByteData.sublistView(base64Decode(_testFontBase64));
}

final class _TestAssetBundle extends CachingAssetBundle {
  _TestAssetBundle(this.onLoad);

  final Future<ByteData> Function(String key) onLoad;

  @override
  Future<ByteData> load(String key) => onLoad(key);
}

BundledCanvasFont _font(
  String family, {
  List<String> assetPaths = const <String>['fonts/test.ttf'],
}) {
  return BundledCanvasFont(
    family: family,
    label: family,
    assetPaths: assetPaths,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BundledFlutterFontLoader configuration', () {
    test('normalizes and validates configured fallback families', () {
      final loader = BundledFlutterFontLoader(
        fonts: <BundledCanvasFont>[_font('Primary'), _font(' Fallback ')],
        fallbackFontFamilies: const <String>[' Fallback ', '', 'Fallback'],
        assetBundle: _TestAssetBundle((_) async => _testFontBytes()),
      );

      expect(loader.fallbackFontFamilies, orderedEquals(<String>['Fallback']));
    });

    test('rejects an unknown fallback family', () {
      expect(
        () => BundledFlutterFontLoader(
          fonts: <BundledCanvasFont>[_font('Primary')],
          fallbackFontFamilies: const <String>['Missing'],
          assetBundle: _TestAssetBundle((_) async => _testFontBytes()),
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate normalized family definitions', () {
      expect(
        () => BundledFlutterFontLoader(
          fonts: <BundledCanvasFont>[_font('Inter'), _font(' Inter ')],
          assetBundle: _TestAssetBundle((_) async => _testFontBytes()),
        ),
        throwsArgumentError,
      );
    });

    test('rejects blank asset paths', () {
      expect(
        () => BundledFlutterFontLoader(
          fonts: <BundledCanvasFont>[
            _font('Inter', assetPaths: const <String>['   ']),
          ],
          assetBundle: _TestAssetBundle((_) async => _testFontBytes()),
        ),
        throwsArgumentError,
      );
    });
  });

  group('BundledFlutterFontLoader loading', () {
    test('loads a known family once and caches success', () async {
      final loadedPaths = <String>[];

      final loader = BundledFlutterFontLoader(
        fonts: <BundledCanvasFont>[_font('LoaderSuccessFont')],
        assetBundle: _TestAssetBundle((key) async {
          loadedPaths.add(key);
          return _testFontBytes();
        }),
      );

      expect(
        await loader.ensureLoaded(const <String>[' LoaderSuccessFont ']),
        isTrue,
      );

      expect(loadedPaths, <String>['fonts/test.ttf']);

      expect(
        await loader.ensureLoaded(const <String>['LoaderSuccessFont']),
        isFalse,
      );

      expect(loadedPaths, <String>[
        'fonts/test.ttf',
      ], reason: 'Successful font registration must be cached.');
    });

    test('validates the complete request before starting loads', () async {
      var assetLoads = 0;

      final loader = BundledFlutterFontLoader(
        fonts: <BundledCanvasFont>[_font('KnownFont')],
        assetBundle: _TestAssetBundle((_) async {
          assetLoads++;
          return _testFontBytes();
        }),
      );

      await expectLater(
        loader.ensureLoaded(const <String>['KnownFont', 'MissingFont']),
        throwsA(isA<StateError>()),
      );

      expect(assetLoads, 0);
    });

    test('concurrent callers share an in-flight load', () async {
      final assetResult = Completer<ByteData>();
      var assetLoads = 0;

      final loader = BundledFlutterFontLoader(
        fonts: <BundledCanvasFont>[_font('ConcurrentFont')],
        assetBundle: _TestAssetBundle((_) {
          assetLoads++;
          return assetResult.future;
        }),
      );

      final first = loader.ensureLoaded(const <String>['ConcurrentFont']);

      final second = loader.ensureLoaded(const <String>['ConcurrentFont']);

      expect(assetLoads, 1);

      assetResult.complete(_testFontBytes());

      expect(await first, isTrue);
      expect(await second, isTrue);

      expect(
        await loader.ensureLoaded(const <String>['ConcurrentFont']),
        isFalse,
      );

      expect(assetLoads, 1);
    });

    test('failed loads are retryable and are not marked loaded', () async {
      var assetLoads = 0;

      final loader = BundledFlutterFontLoader(
        fonts: <BundledCanvasFont>[_font('RetryFont')],
        assetBundle: _TestAssetBundle((_) async {
          assetLoads++;

          if (assetLoads == 1) {
            throw StateError('Temporary font load failure');
          }

          return _testFontBytes();
        }),
      );

      await expectLater(
        loader.ensureLoaded(const <String>['RetryFont']),
        throwsA(isA<StateError>()),
      );

      expect(assetLoads, 1);

      expect(await loader.ensureLoaded(const <String>['RetryFont']), isTrue);

      expect(assetLoads, 2);

      expect(await loader.ensureLoaded(const <String>['RetryFont']), isFalse);

      expect(assetLoads, 2);
    });
  });
}
