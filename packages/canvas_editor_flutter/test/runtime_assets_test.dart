// Path: oss_packages/canvas_editor_flutter/test/runtime_assets_test.dart

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/src/canvas_runtime_resources.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingFontAssets implements CanvasFontAssets {
  _RecordingFontAssets({this.fallback = const <String>[]});

  final List<String> fallback;

  final List<Set<String>> ensureCalls = <Set<String>>[];

  @override
  List<FontDef> get pickerFonts => const <FontDef>[];

  @override
  List<FontDef> get loadableFonts => const <FontDef>[];

  @override
  Iterable<String> get fallbackFontFamilies => fallback;

  @override
  Future<void> ensureLoaded(Iterable<String> families) async {
    ensureCalls.add(
      families
          .map((family) => family.trim())
          .where((family) => family.isNotEmpty)
          .toSet(),
    );
  }
}

class _FakeIconCatalog implements IconCatalogPort {
  const _FakeIconCatalog();

  @override
  ResolvedIcon? resolve(String iconRef) => resolveMap[iconRef];

  @override
  Map<String, ResolvedIcon> get resolveMap => <String, ResolvedIcon>{
    for (final item in items) item.ref: item.resolved,
  };

  @override
  List<IconCatalogItem> get items => const <IconCatalogItem>[
    IconCatalogItem(
      ref: 'heart',
      label: 'Heart',
      resolved: ResolvedIconText(
        glyph: '\u2665',
        fontFamily: 'Icon Font',
        fontWeight: 900,
      ),
    ),
  ];
}

class _NoopMediaResolver implements CanvasMediaResolver {
  const _NoopMediaResolver();

  @override
  Future<String?> resolveUrl(String ref) async => null;

  @override
  Future<Map<String, String>> resolveUrls(List<String> refs) async {
    return const <String, String>{};
  }

  @override
  Future<Size2D?> resolveIntrinsicSize(String ref) async => null;

  @override
  Future<Map<String, Size2D>> resolveIntrinsicSizes(List<String> refs) async {
    return const <String, Size2D>{};
  }
}

CanvasSceneDocument _sceneWithTextAndIcon() {
  return CanvasSceneDocument(
    artboardSize: const Size2D(300, 200),
    backgroundFill: const CanvasFill.none(),
    backgroundOpacity: 1.0,
    children: const <Node>[
      Node.text(
        id: 'text-1',
        data: TextData(
          text: 'Sample headline',
          fontFamily: 'Poppins',
          fontWeight: 700,
          fontSize: 32,
        ),
      ),
      Node.icon(
        id: 'icon-1',
        data: CanvasIconData(iconRef: 'heart'),
      ),
      Node.group(
        id: 'group-1',
        children: <Node>[
          Node.text(
            id: 'nested-text-1',
            data: TextData(
              text: 'Nested Hindi',
              fontFamily: 'Noto Sans Devanagari',
              fontWeight: 400,
              fontSize: 20,
            ),
          ),
        ],
      ),
    ],
  );
}

void main() {
  test(
    'fontFamiliesForScene collects fallback, text, nested text, and icon fonts',
    () {
      final fonts = _RecordingFontAssets(
        fallback: const <String>['Noto Sans Devanagari', 'Poppins', 'Inter'],
      );

      final runtimeAssets = CanvasRuntimeResources(
        fonts: fonts,
        icons: const _FakeIconCatalog(),
        media: const _NoopMediaResolver(),
      );

      final families = runtimeAssets.fontFamiliesForScene(
        _sceneWithTextAndIcon(),
      );

      expect(
        families,
        containsAll(<String>{
          'Noto Sans Devanagari',
          'Poppins',
          'Inter',
          'Icon Font',
        }),
      );
    },
  );

  test('fontFamiliesForScene can skip fallback and icon fonts', () {
    final fonts = _RecordingFontAssets(
      fallback: const <String>['Noto Sans Devanagari', 'Poppins', 'Inter'],
    );

    final runtimeAssets = CanvasRuntimeResources(
      fonts: fonts,
      icons: const _FakeIconCatalog(),
      media: const _NoopMediaResolver(),
    );

    final families = runtimeAssets.fontFamiliesForScene(
      _sceneWithTextAndIcon(),
      includeFallbackFonts: false,
      includeIconFonts: false,
    );

    expect(families, contains('Poppins'));
    expect(families, contains('Noto Sans Devanagari'));
    expect(families, isNot(contains('Inter')));
    expect(families, isNot(contains('Icon Font')));
  });

  test(
    'ensureFontsForScene delegates unique required families to font assets',
    () async {
      final fonts = _RecordingFontAssets(
        fallback: const <String>['Noto Sans Devanagari', 'Poppins', 'Inter'],
      );

      final runtimeAssets = CanvasRuntimeResources(
        fonts: fonts,
        icons: const _FakeIconCatalog(),
        media: const _NoopMediaResolver(),
      );

      await runtimeAssets.ensureFontsForScene(_sceneWithTextAndIcon());

      expect(fonts.ensureCalls, hasLength(1));
      expect(
        fonts.ensureCalls.single,
        containsAll(<String>{
          'Noto Sans Devanagari',
          'Poppins',
          'Inter',
          'Icon Font',
        }),
      );
    },
  );
}
