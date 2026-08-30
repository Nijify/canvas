// Path: oss_packages/canvas_editor_flutter/example/lib/main.dart
import 'dart:async';
import 'dart:convert';

import 'package:canvas_core/canvas_core_runtime.dart';
import 'package:canvas_editor_flutter/asset_library.dart';
import 'package:canvas_editor_flutter/canvas_editor_flutter.dart';
import 'package:canvas_editor_flutter/extensions.dart' show EditorShellConfig;
import 'package:canvas_editor_flutter/image_import.dart';
import 'package:canvas_editor_flutter/image_tools.dart';
import 'package:canvas_editor_flutter_example/data_uri_image_metadata.dart';
import 'package:canvas_editor_flutter_example/unsplash/unsplash_attribution_session.dart';
import 'package:canvas_editor_flutter_example/unsplash/unsplash_example_ui.dart';
import 'package:canvas_editor_flutter_example/unsplash/unsplash_photo.dart';
import 'package:canvas_editor_flutter_example/unsplash/unsplash_proxy_client.dart';
import 'package:canvas_renderer_flutter/canvas_renderer_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart' as sharing;

final _navigatorKey = GlobalKey<NavigatorState>();

const _unsplashProxyBaseUrl = String.fromEnvironment(
  'UNSPLASH_PROXY_BASE_URL',
);

const _backgroundRemovalDemoSourceRef =
    'asset:assets/demo_assets/background_removal_input.png';

const _backgroundRemovalDemoForegroundRef =
    'asset:assets/demo_assets/background_removal_foreground.png';

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
      home: const _ExampleEditorPage(),
    );
  }
}

class _ExampleEditorPage extends StatefulWidget {
  const _ExampleEditorPage();

  @override
  State<_ExampleEditorPage> createState() => _ExampleEditorPageState();
}

class _ExampleEditorPageState extends State<_ExampleEditorPage> {
  final UnsplashAttributionSession _unsplashAttribution =
      UnsplashAttributionSession();

  late final UnsplashProxyClient? _unsplashClient = _createUnsplashClient();

  Map<String, UnsplashCredit> _visibleUnsplashCredits =
      const <String, UnsplashCredit>{};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CanvasSceneEditor(
            initialScene: _demoDocument,
            resources: _demoResources,
            shell: EditorShellConfig.standalone,
            onSceneChanged: _handleSceneChanged,
            pngExport: PngExportCapability(
              port: _ExamplePngExportPort(
                resources: _demoResources,
                navigatorKey: _navigatorKey,
              ),
              canShare: true,
              canSave: false,
            ),
            jsonExport: const JsonExportCapability(
              output: _ExampleJsonOutputPort(),
              canCopy: true,
              canSave: false,
            ),
            extensions: [
              imageImportExtension<CanvasSceneDocument>(
                imageImport: _demoImageImport,
              ),
              backgroundRemovalExtension<CanvasSceneDocument>(
                port: const _ExampleBackgroundRemovalPort(),
              ),
              canvasAssetLibraryExtension<CanvasSceneDocument>(
                library: _demoAssetLibrary,
                presentSelection: _presentAssetSelection,
              ),
            ],
          ),
        ),
        UnsplashCreditBar(
          creditsBySourceRef: _visibleUnsplashCredits,
        ),
      ],
    );
  }

  Future<CanvasAssetLibraryItem?> _presentAssetSelection(
    BuildContext context,
    CanvasAssetLibrary library,
  ) {
    return presentExampleAssetSelection(
      context: context,
      library: library,
      unsplashClient: _unsplashClient,
      onUnsplashSelected: _handleUnsplashSelected,
    );
  }

  void _handleUnsplashSelected(UnsplashPhoto photo) {
    _unsplashAttribution.register(photo);

    final client = _unsplashClient;
    if (client == null) return;

    unawaited(_trackUnsplashDownload(client, photo));
  }

  Future<void> _trackUnsplashDownload(
    UnsplashProxyClient client,
    UnsplashPhoto photo,
  ) async {
    try {
      await client.trackDownload(photo);
    } catch (error, stackTrace) {
      debugPrint(
        'Unsplash download tracking failed: $error\n$stackTrace',
      );
    }
  }

  void _handleSceneChanged(CanvasSceneDocument scene) {
    final next = _unsplashAttribution.visibleCreditsForScene(scene);
    if (_sameCredits(_visibleUnsplashCredits, next) || !mounted) {
      return;
    }

    setState(() {
      _visibleUnsplashCredits = next;
    });
  }
}

UnsplashProxyClient? _createUnsplashClient() {
  final raw = _unsplashProxyBaseUrl.trim();
  if (raw.isEmpty) return null;

  final uri = Uri.tryParse(raw);
  if (uri == null ||
      (uri.scheme != 'https' && uri.scheme != 'http') ||
      uri.host.isEmpty) {
    debugPrint(
      'Ignoring invalid UNSPLASH_PROXY_BASE_URL: $_unsplashProxyBaseUrl',
    );
    return null;
  }

  return UnsplashProxyClient(baseUri: uri);
}

bool _sameCredits(
  Map<String, UnsplashCredit> current,
  Map<String, UnsplashCredit> next,
) {
  if (current.length != next.length) return false;

  for (final entry in current.entries) {
    final other = next[entry.key];
    if (other == null ||
        other.photographerName != entry.value.photographerName ||
        other.photographerUrl != entry.value.photographerUrl) {
      return false;
    }
  }

  return true;
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
      id: 'background-removal-demo',
      label: 'Background removal demo',
      category: 'image tools',
      sourceRef: _backgroundRemovalDemoSourceRef,
      thumbnailRef: _backgroundRemovalDemoSourceRef,
      intrinsicSize: Size2D(320, 180),
      tags: <String>['background', 'removal', 'foreground', 'demo'],
    ),
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
            'Try Add → Assets → Background removal demo, then use '
            'Image tools in the inspector.',
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
    final context = navigatorKey.currentContext;
    if (context == null) {
      throw StateError('Unable to locate the app context for PNG sharing.');
    }

    final sharePositionOrigin = Offset.zero & MediaQuery.sizeOf(context);

    final bytes = await _renderPng(preparedScene: preparedScene, spec: spec);

    await sharing.SharePlus.instance.share(
      sharing.ShareParams(
        files: <sharing.XFile>[
          sharing.XFile.fromData(bytes, mimeType: 'image/png'),
        ],
        fileNameOverrides: <String>[filename],
        text: text,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );

    return 'PNG sharing started.';
  }

  @override
  Future<String> savePng({
    required CanvasSceneDocument editableScene,
    required CanvasSceneDocument preparedScene,
    required EditorExportSpec spec,
    required String filename,
  }) {
    throw UnsupportedError('PNG saving is not available in this example.');
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

    if (json.contains(';base64,')) {
      return 'Scene JSON copied. Imported images are embedded, so the JSON '
          'can be large.';
    }

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

final class _ExampleBackgroundRemovalPort implements BackgroundRemovalPort {
  const _ExampleBackgroundRemovalPort();

  @override
  Future<BackgroundRemovalResult> removeBackground({
    required String sourceRef,
  }) async {
    final normalizedSourceRef = sourceRef.trim();

    if (normalizedSourceRef != _backgroundRemovalDemoSourceRef) {
      return const BackgroundRemovalFailure(
        kind: BackgroundRemovalFailureKind.unsupported,
        message:
            'The public example only supports the bundled '
            'background-removal demo image.',
      );
    }

    return const BackgroundRemovalSuccess(
      sourceRef: _backgroundRemovalDemoForegroundRef,
    );
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
  Iterable<String> get fallbackFontFamilies => const <String>[
    'Noto Sans Symbols',
  ];

  @override
  List<FontDef> get loadableFonts => const <FontDef>[
    FontDef(family: 'Roboto', label: 'Roboto'),
    FontDef(family: 'Noto Sans Symbols', label: 'Noto Sans Symbols'),
  ];

  @override
  List<FontDef> get pickerFonts => const <FontDef>[
    FontDef(family: 'Roboto', label: 'Roboto'),
  ];

  @override
  Future<void> ensureLoaded(Iterable<String> families) async {
    // The example fonts are bundled by Flutter and available at startup.
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
  final DataUriImageMetadataResolver _dataUriMetadata =
      DataUriImageMetadataResolver();

  @override
  Future<Size2D?> resolveIntrinsicSize(String ref) async {
    final trimmed = ref.trim();

    if (trimmed == _backgroundRemovalDemoForegroundRef) {
      return const Size2D(320, 180);
    }

    final dataUriSize = await _dataUriMetadata.resolve(trimmed);
    return dataUriSize ?? _demoAssetLibrary.intrinsicSizeFor(trimmed);
  }

  @override
  Future<Map<String, Size2D>> resolveIntrinsicSizes(List<String> refs) async {
    final entries = await Future.wait([
      for (final ref in refs) _resolveIntrinsicSizeEntry(ref),
    ]);

    return Map<String, Size2D>.fromEntries(
      entries.whereType<MapEntry<String, Size2D>>(),
    );
  }

  Future<MapEntry<String, Size2D>?> _resolveIntrinsicSizeEntry(
    String ref,
  ) async {
    try {
      final size = await resolveIntrinsicSize(ref);
      return size == null ? null : MapEntry(ref, size);
    } catch (error, stackTrace) {
      debugPrint(
        'Example image metadata resolution failed: '
        '$error\n$stackTrace',
      );
      return null;
    }
  }

  @override
  Future<String?> resolveUrl(String ref) async {
    final trimmed = ref.trim();

    if (trimmed.startsWith('data:')) {
      return trimmed;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty) {
      // Direct remote URLs are already renderable. Preserve the API-returned
      // URL verbatim, including query parameters required by providers such as
      // Unsplash.
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
