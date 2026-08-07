// Path: oss_packages/canvas_editor_flutter/example/lib/main.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/asset_library.dart';
import 'package:canvas_editor_flutter/canvas_editor_flutter.dart';
import 'package:canvas_editor_flutter/extensions.dart' show EditorShellConfig;
import 'package:canvas_editor_flutter/image_import.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart' as sharing;

final _navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const CanvasEditorExampleApp());
}

class CanvasEditorExampleApp extends StatelessWidget {
  const CanvasEditorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Canvas Editor Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: CanvasSceneEditor(
        initialScene: _demoDocument,
        resources: _demoResources,
        shell: EditorShellConfig.standalone,
        pngExport: PngExportCapability(
          port: _ExamplePngExportPort(
            resources: _demoResources,
            navigatorKey: _navigatorKey,
          ),
          availability: const PngExportAvailability(
            canShare: true,
            canSave: false,
          ),
        ),
        jsonExport: const JsonExportCapability(
          output: _ExampleJsonOutputPort(),
          availability: JsonExportAvailability(canCopy: true, canSave: false),
        ),
        extensions: [
          imageImportExtension<CanvasSceneDocument>(
            imageImport: _demoImageImport,
          ),
          canvasAssetLibraryExtension<CanvasSceneDocument>(
            library: _demoAssetLibrary,
            presentSelection: _presentDemoAssetSelection,
          ),
        ],
      ),
    );
  }
}

final _demoImageImport = _ExampleImageImportPort();

final _demoResources = CanvasRuntimeResources(
  fonts: _DemoFontAssets(),
  icons: _DemoIconCatalog(),
  media: _ExampleCanvasMediaResolver(),
);

final CanvasAssetLibrary _demoAssetLibrary = LocalCanvasAssetLibrary(
  <CanvasAssetLibraryItem>[
    const CanvasAssetLibraryItem(
      id: 'abstract-orange',
      label: 'Abstract orange',
      category: 'illustrations',
      sourceRef: 'asset:assets/demo_assets/abstract_orange.png',
      thumbnailRef: 'asset:assets/demo_assets/abstract_orange.png',
      intrinsicSize: Size2D(320, 180),
      tags: <String>['abstract', 'orange', 'landscape'],
    ),
    const CanvasAssetLibraryItem(
      id: 'geometric-blue',
      label: 'Geometric blue',
      category: 'illustrations',
      sourceRef: 'asset:assets/demo_assets/geometric_blue.png',
      thumbnailRef: 'asset:assets/demo_assets/geometric_blue.png',
      intrinsicSize: Size2D(180, 320),
      tags: <String>['geometric', 'blue', 'portrait'],
    ),
    const CanvasAssetLibraryItem(
      id: 'star-sticker',
      label: 'Star sticker',
      category: 'stickers',
      sourceRef: 'asset:assets/demo_assets/star_sticker.png',
      thumbnailRef: 'asset:assets/demo_assets/star_sticker.png',
      intrinsicSize: Size2D(192, 192),
      tags: <String>['sticker', 'star', 'square'],
    ),
  ],
);

Future<CanvasAssetLibraryItem?> _presentDemoAssetSelection(
  BuildContext context,
  CanvasAssetLibrary library,
) {
  return showDialog<CanvasAssetLibraryItem>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Demo assets'),
        content: SizedBox(
          width: 360,
          height: 340,
          child: ListView.separated(
            itemCount: library.items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final item = library.items[index];

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    _assetPathFromRef(item.thumbnailRef),
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) {
                      return const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.image_outlined),
                      );
                    },
                  ),
                ),
                title: Text(item.label),
                subtitle: Text(item.category),
                onTap: () => Navigator.of(dialogContext).pop(item),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}

String _assetPathFromRef(String ref) {
  final trimmed = ref.trim();
  const prefix = 'asset:';

  if (trimmed.startsWith(prefix)) {
    return trimmed.substring(prefix.length).trim();
  }

  return trimmed;
}

const CanvasSceneDocument _demoDocument = CanvasSceneDocument(
  artboardSize: Size2D(740, 420),
  backgroundFill: CanvasFill.gradient(
    LinearGradientSpec(
      color1: 0xFFF8FAFC,
      color2: 0xFFE0E7FF,
      angle: 135,
      width: 50,
    ),
  ),
  backgroundOpacity: 1.0,
  children: <Node>[
    Node.path(
      id: 'demo-card',
      name: 'Demo card',
      xf: Transform2D(position: Vec2(370, 210)),
      data: PathData(
        source: RoundRectSource(520, 220, 32, 32),
        fill: CanvasFill.solid(0xFFFFFFFF),
        strokeColor: 0xFFE0E7FF,
        strokeWidth: 4,
      ),
    ),
    Node.text(
      id: 'demo-title',
      name: 'Title',
      xf: Transform2D(position: Vec2(370, 180)),
      data: TextData(
        text: 'CanvasSceneEditor',
        fontFamily: 'Roboto',
        fontWeight: 700,
        fontSize: 42,
        letterSpacing: 0,
        fill: CanvasFill.solid(0xFF312E81),
      ),
    ),
    Node.text(
      id: 'demo-subtitle',
      name: 'Subtitle',
      xf: Transform2D(position: Vec2(370, 245)),
      data: TextData(
        text:
            'Use Add → Image or Add → Assets, then edit the selected image '
            'in the inspector.',
        fontFamily: 'Roboto',
        fontWeight: 400,
        fontSize: 18,
        letterSpacing: 0,
        fill: CanvasFill.solid(0xFF475569),
      ),
    ),
  ],
);

final class _ExamplePngExportPort implements PngExportPort {
  const _ExamplePngExportPort({
    required this.resources,
    required this.navigatorKey,
  });

  final CanvasRuntimeResources resources;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Future<String> sharePng({
    required CanvasSceneDocument editableScene,
    required CanvasSceneDocument preparedScene,
    required EditorExportSpec spec,
    required String filename,
    String? text,
  }) async {
    // This generic example has no document-level export policy, so it does not
    // need to inspect editableScene. Product hosts can use that canonical scene
    // for policy or compatibility checks before doing any rendering work.
    final bytes = await _renderPng(
      preparedScene: preparedScene,
      spec: spec,
    );

    final context = navigatorKey.currentContext;
    if (context == null) {
      throw StateError('Unable to locate the app context for PNG sharing.');
    }

    final size = MediaQuery.sizeOf(context);

    await sharing.SharePlus.instance.share(
      sharing.ShareParams(
        files: <sharing.XFile>[
          sharing.XFile.fromData(
            bytes,
            mimeType: 'image/png',
          ),
        ],
        fileNameOverrides: <String>[filename],
        text: text,
        sharePositionOrigin: Offset.zero & size,
      ),
    );

    return 'PNG share sheet opened.';
  }

  @override
  Future<String> savePng({
    required CanvasSceneDocument editableScene,
    required CanvasSceneDocument preparedScene,
    required EditorExportSpec spec,
    required String filename,
  }) {
    throw UnsupportedError(
      'PNG saving is not available in this example.',
    );
  }

  Future<Uint8List> _renderPng({
    required CanvasSceneDocument preparedScene,
    required EditorExportSpec spec,
  }) async {
    await resources.ensureFontsForScene(preparedScene);

    final textPipeline = FlutterTextPipeline(
      fallbackFontFamilies: resources.fallbackFontFamilies,
    );

    final imagePool = FlutterImagePool(
      assetUrlsResolver: resources.media.resolveUrls,
      assetMetasResolver: resources.media.resolveIntrinsicSizes,
    );

    try {
      await imagePool.resolveSceneIntrinsics(preparedScene);

      await imagePool.preloadScene(
        preparedScene,
        targetW: spec.widthPx,
        targetH: spec.heightPx,
      );

      final exporter = CanvasDocumentExporter(
        textPipeline: textPipeline,
        icons: resources.icons,
      );

      return await exporter.exportPng(
        document: preparedScene,
        resolveImage: (id) async => imagePool.images[id],
        resolveIntrinsicSize: (id) async => imagePool.intrinsicSize(id),
        spec: CanvasExportSpec(
          widthPx: spec.widthPx,
          heightPx: spec.heightPx,
          bleedPx: spec.bleedPx,
          pixelRatio: spec.pixelRatio,
          transparent: spec.transparent,
          fit: spec.fit,
          cropToContent: spec.cropToContent,
          contentPaddingPx: spec.contentPaddingPx,
          tight: spec.tight,
        ),
      );
    } finally {
      imagePool.dispose();
      textPipeline.dispose();
    }
  }
}

final class _ExampleJsonOutputPort extends JsonOutputPort {
  const _ExampleJsonOutputPort();

  @override
  Future<String> copyJson({required String json}) async {
    await Clipboard.setData(ClipboardData(text: json));
    return 'Scene JSON copied to clipboard.';
  }

  @override
  Future<String> saveJson({
    required String json,
    required String filename,
  }) async {
    return 'Scene JSON saving is not available in this example.';
  }
}

final class _ExampleImageImportPort implements ImageImportPort {
  _ExampleImageImportPort({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<ImageImportResult> importImage({
    required ImageImportSource source,
  }) async {
    try {
      final image = await _picker.pickImage(
        source: switch (source) {
          ImageImportSource.gallery => ImageSource.gallery,
          ImageImportSource.camera => ImageSource.camera,
        },
      );

      if (image == null) {
        return const ImageImportResult.cancelled();
      }

      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) {
        return ImageImportResult.failure(
          'The selected image could not be read.',
        );
      }

      final mimeType = _normalizedMimeType(image.mimeType);

      // Example-only: return a directly renderable sourceRef without
      // introducing a backend, upload API, or persistent media store.
      final sourceRef = 'data:$mimeType;base64,${base64Encode(bytes)}';

      return ImageImportResult.success(sourceRef);
    } on Exception {
      return ImageImportResult.failure(
        'Unable to import image. Please try again.',
      );
    }
  }

  String _normalizedMimeType(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';

    if (normalized.startsWith('image/')) {
      return normalized == 'image/jpg' ? 'image/jpeg' : normalized;
    }

    // canvas_renderer_flutter decodes the bytes through MemoryImage.
    // The MIME value is best-effort in this lightweight example.
    return 'application/octet-stream';
  }
}

final class _DemoFontAssets implements CanvasFontAssets {
  const _DemoFontAssets();

  @override
  Iterable<String> get fallbackFontFamilies => const <String>['Roboto'];

  @override
  List<FontDef> get loadableFonts => const <FontDef>[
    FontDef(family: 'Roboto', label: 'Roboto'),
  ];

  @override
  List<FontDef> get pickerFonts => loadableFonts;

  @override
  Future<void> ensureLoaded(Iterable<String> families) async {
    // The example uses Flutter's default Material font.
  }
}

final class _DemoIconCatalog implements IconCatalogPort {
  const _DemoIconCatalog();

  @override
  List<IconCatalogItem> get items => const <IconCatalogItem>[];

  @override
  Map<String, ResolvedIcon> get resolveMap => const <String, ResolvedIcon>{};

  @override
  ResolvedIcon? resolve(String iconRef) => null;
}

final class _ExampleCanvasMediaResolver implements CanvasMediaResolver {
  const _ExampleCanvasMediaResolver();

  @override
  Future<Size2D?> resolveIntrinsicSize(String ref) async {
    return _demoAssetLibrary.intrinsicSizeFor(ref);
  }

  @override
  Future<Map<String, Size2D>> resolveIntrinsicSizes(List<String> refs) async {
    final resolved = <String, Size2D>{};

    for (final ref in refs) {
      final size = await resolveIntrinsicSize(ref);

      if (size != null) {
        resolved[ref] = size;
      }
    }

    return resolved;
  }

  @override
  Future<String?> resolveUrl(String ref) async {
    final trimmed = ref.trim();

    if (trimmed.startsWith('data:')) {
      return trimmed;
    }

    if (!trimmed.startsWith('asset:')) {
      return null;
    }

    final path = _assetPathFromRef(trimmed);
    return path.isEmpty ? null : path;
  }

  @override
  Future<Map<String, String>> resolveUrls(List<String> refs) async {
    final resolved = <String, String>{};

    for (final ref in refs) {
      final url = await resolveUrl(ref);

      if (url != null) {
        resolved[ref] = url;
      }
    }

    return resolved;
  }
}
