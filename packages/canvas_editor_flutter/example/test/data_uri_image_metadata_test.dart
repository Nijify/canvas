import 'dart:convert';
import 'dart:ui' as ui;

import 'package:canvas_core/canvas_core_runtime.dart' show Size2D;
import 'package:canvas_editor_flutter_example/data_uri_image_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

Future<String> _pngDataUri(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF336699),
  );

  final image = await recorder.endRecording().toImage(width, height);

  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data!.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    return 'data:image/png;base64,${base64Encode(bytes)}';
  } finally {
    image.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resolves dimensions from an encoded image data URI', () async {
    final resolver = DataUriImageMetadataResolver();
    final ref = await _pngDataUri(4, 2);

    expect(await resolver.resolve(ref), const Size2D(4, 2));
    expect(await resolver.resolve(ref), const Size2D(4, 2));
  });

  test('returns null for non-data and invalid data references', () async {
    final resolver = DataUriImageMetadataResolver();

    expect(await resolver.resolve('asset:example.png'), isNull);
    expect(
      await resolver.resolve('data:image/png;base64,not-an-image'),
      isNull,
    );
  });
}
