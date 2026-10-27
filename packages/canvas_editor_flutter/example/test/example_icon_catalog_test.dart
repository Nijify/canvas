import 'dart:convert';
import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter_example/example_icon_catalog.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled assets prepare a usable synchronous catalog', () async {
    final catalog = await ExampleIconCatalog.load(rootBundle);

    expect(catalog.items.map((item) => item.label), [
      'Diamond',
      'Ring',
      'Wide arrow',
    ]);
    for (final item in catalog.items) {
      expect(catalog.resolve(item.ref), same(item.resolved));
      expect(item.resolved.pathIR.cmds, isNotEmpty);
    }
    expect(catalog.resolve('icon.missing'), isNull);
  });

  test('a missing asset fails preparation', () async {
    await expectLater(
      ExampleIconCatalog.load(_ReplacingRingBundle(null)),
      throwsA(isA<FlutterError>()),
    );
  });

  test('raw SVG is rejected before it reaches scene evaluation', () async {
    final json =
        jsonDecode(await rootBundle.loadString('assets/icons/ring.json'))
            as Map<String, dynamic>;
    json['source'] = {'kind': 'svg', 'd': 'M0 0L24 0L24 24Z'};

    await expectLater(
      ExampleIconCatalog.load(_ReplacingRingBundle(jsonEncode(json))),
      throwsFormatException,
    );
  });

  test('invalid SVG path data fails during resource preparation', () async {
    final json =
        jsonDecode(await rootBundle.loadString('assets/icons/ring.json'))
            as Map<String, dynamic>;
    json['source'] = {'kind': 'path', 'd': 'M0 0L'};
    await expectLater(
      ExampleIconCatalog.load(_ReplacingRingBundle(jsonEncode(json))),
      throwsFormatException,
    );
  });

  test('invalid viewBox dimensions fail preparation', () async {
    final json =
        jsonDecode(await rootBundle.loadString('assets/icons/ring.json'))
            as Map<String, dynamic>;
    json['viewBox'] = [0, 0, 0, 24];

    await expectLater(
      ExampleIconCatalog.load(_ReplacingRingBundle(jsonEncode(json))),
      throwsFormatException,
    );
  });

  test('bundled icons export to PNG without font assets', () async {
    final catalog = await ExampleIconCatalog.load(rootBundle);
    final renderer = FlutterCanvasPngRenderer(
      fonts: BundledFlutterFontLoader(fonts: const []),
      icons: catalog,
    );
    const color = 0xFF168253;
    final scene = CanvasSceneDocument(
      artboardSize: const Size2D(384, 128),
      backgroundFill: const CanvasFill.none(),
      backgroundOpacity: 1,
      children: [
        for (final (index, item) in catalog.items.indexed)
          Node.icon(
            id: item.ref,
            xf: Affine2D.translation(64 + index * 128, 64),
            data: CanvasIconData(
              iconRef: item.ref,
              sizePx: 96,
              appearance: const CanvasAppearance(
                foreground: CanvasFill.solid(color),
              ),
            ),
          ),
      ],
    );
    final png = await renderer.renderPng(
      scene: scene,
      spec: const CanvasPngSpec(widthPx: 384, heightPx: 128, pixelRatio: 1),
    );
    final codec = await ui.instantiateImageCodec(png);
    try {
      final image = (await codec.getNextFrame()).image;
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        expect(data, isNotNull);
        final pixels = data!.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        List<int> rgba(int x, int y) {
          final offset = (y * image.width + x) * 4;
          return pixels.sublist(offset, offset + 4);
        }

        const painted = [22, 130, 83, 255];
        expect(rgba(64, 64), painted); // Diamond center.
        expect(rgba(24, 24)[3], 0);
        expect(rgba(192, 34), painted); // Curved ring silhouette.
        expect(rgba(192, 64)[3], 0); // Even-odd hole.
        expect(rgba(286, 64), painted); // Offset-origin arrow body.
        expect(rgba(352, 64), painted); // Arrow head.
        expect(rgba(320, 38)[3], 0); // Aspect-preserving vertical fit.
        expect(rgba(274, 64)[3], 0); // Authored left margin.
        expect(rgba(366, 64)[3], 0); // Authored right margin.
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  });
}

final class _ReplacingRingBundle extends CachingAssetBundle {
  _ReplacingRingBundle(this.replacement);

  final String? replacement;

  @override
  Future<ByteData> load(String key) {
    if (key != 'assets/icons/ring.json') return rootBundle.load(key);
    final json = replacement;
    if (json == null) throw FlutterError('Missing ring fixture.');
    return Future.value(ByteData.sublistView(utf8.encode(json)));
  }
}
