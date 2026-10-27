// Path: packages/canvas_background_removal_isnet/test/lanczos3_test.dart

import 'dart:typed_data';

import 'package:canvas_background_removal_isnet/src/lanczos3.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('RGB identity resize preserves pixels exactly', () {
    final source = img.Image(width: 2, height: 2, numChannels: 3)
      ..setPixelRgb(0, 0, 10, 20, 30)
      ..setPixelRgb(1, 0, 40, 50, 60)
      ..setPixelRgb(0, 1, 70, 80, 90)
      ..setPixelRgb(1, 1, 100, 110, 120);

    final resized = Lanczos3.resizeRgb8(source, width: 2, height: 2);

    expect(_flattenRgb(resized), orderedEquals(_flattenRgb(source)));
  });

  test('gray identity resize preserves bytes exactly', () {
    final source = Uint8List.fromList(<int>[0, 64, 128, 255]);

    final resized = Lanczos3.resizeGray8(
      source,
      sourceWidth: 2,
      sourceHeight: 2,
      width: 2,
      height: 2,
    );

    expect(resized, orderedEquals(source));
  });

  test('RGB upsample matches Pillow LANCZOS reference exactly', () {
    final source = _referenceRgbSource();

    final resized = Lanczos3.resizeRgb8(source, width: 7, height: 5);

    // Generated with Pillow 12.3.0 Image.Resampling.LANCZOS from the exact
    // source pixels below. This exercises borders and two-pass rounding.
    const expected = <int>[
      0,
      0,
      1,
      169,
      0,
      0,
      250,
      71,
      0,
      0,
      255,
      0,
      0,
      51,
      203,
      136,
      90,
      255,
      255,
      255,
      255,
      109,
      110,
      0,
      145,
      106,
      56,
      164,
      131,
      103,
      103,
      163,
      101,
      76,
      36,
      152,
      97,
      71,
      167,
      162,
      169,
      183,
      255,
      249,
      0,
      89,
      255,
      130,
      36,
      185,
      255,
      255,
      0,
      255,
      198,
      34,
      82,
      56,
      62,
      23,
      10,
      28,
      72,
      115,
      119,
      19,
      38,
      133,
      85,
      26,
      111,
      157,
      157,
      28,
      170,
      146,
      77,
      90,
      89,
      103,
      75,
      67,
      81,
      108,
      0,
      0,
      31,
      19,
      2,
      31,
      58,
      43,
      42,
      42,
      97,
      64,
      72,
      108,
      117,
      125,
      134,
      156,
      153,
      162,
      166,
    ];

    expect(_flattenRgb(resized), orderedEquals(expected));
  });

  test('RGB downsample matches Pillow LANCZOS reference exactly', () {
    final source = _referenceRgbSource();

    final resized = Lanczos3.resizeRgb8(source, width: 3, height: 2);

    const expected = <int>[
      138,
      107,
      46,
      99,
      109,
      122,
      108,
      103,
      171,
      63,
      126,
      76,
      111,
      71,
      149,
      99,
      89,
      87,
    ];

    expect(_flattenRgb(resized), orderedEquals(expected));
  });

  test('gray upsample matches Pillow LANCZOS reference exactly', () {
    final source = Uint8List.fromList(<int>[
      0,
      64,
      128,
      192,
      255,
      255,
      192,
      128,
      64,
      0,
      32,
      96,
      160,
      224,
      16,
    ]);

    final resized = Lanczos3.resizeGray8(
      source,
      sourceWidth: 5,
      sourceHeight: 3,
      width: 7,
      height: 4,
    );

    const expected = <int>[
      0,
      11,
      79,
      129,
      179,
      243,
      255,
      181,
      168,
      143,
      124,
      99,
      97,
      106,
      196,
      186,
      159,
      141,
      139,
      44,
      0,
      6,
      45,
      109,
      162,
      255,
      144,
      6,
    ];

    expect(resized, orderedEquals(expected));
  });

  test('gray downsample matches Pillow LANCZOS reference exactly', () {
    final source = Uint8List.fromList(<int>[
      0,
      64,
      128,
      192,
      255,
      255,
      192,
      128,
      64,
      0,
      32,
      96,
      160,
      224,
      16,
    ]);

    final resized = Lanczos3.resizeGray8(
      source,
      sourceWidth: 5,
      sourceHeight: 3,
      width: 3,
      height: 2,
    );

    expect(resized, orderedEquals(<int>[109, 124, 155, 128, 161, 62]));
  });
}

img.Image _referenceRgbSource() {
  final source = img.Image(width: 5, height: 3, numChannels: 3);

  const pixels = <List<List<int>>>[
    <List<int>>[
      <int>[0, 0, 0],
      <int>[255, 0, 0],
      <int>[0, 255, 0],
      <int>[0, 0, 255],
      <int>[255, 255, 255],
    ],
    <List<int>>[
      <int>[255, 255, 0],
      <int>[0, 255, 255],
      <int>[255, 0, 255],
      <int>[128, 64, 32],
      <int>[16, 32, 64],
    ],
    <List<int>>[
      <int>[10, 20, 30],
      <int>[40, 50, 60],
      <int>[70, 80, 90],
      <int>[100, 110, 120],
      <int>[130, 140, 150],
    ],
  ];

  for (var y = 0; y < pixels.length; y++) {
    for (var x = 0; x < pixels[y].length; x++) {
      final pixel = pixels[y][x];
      source.setPixelRgb(x, y, pixel[0], pixel[1], pixel[2]);
    }
  }

  return source;
}

List<int> _flattenRgb(img.Image image) {
  final values = <int>[];
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      values
        ..add(pixel.r.toInt())
        ..add(pixel.g.toInt())
        ..add(pixel.b.toInt());
    }
  }
  return values;
}
