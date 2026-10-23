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
import 'package:canvas_editor_flutter_example/example_icon_catalog.dart';
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

const _unsplashProxyBaseUrl = String.fromEnvironment('UNSPLASH_PROXY_BASE_URL');

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
  Future<_DemoRuntime>? _runtime;

  final UnsplashAttributionSession _unsplashAttribution =
      UnsplashAttributionSession();

  late final UnsplashProxyClient? _unsplashClient = _createUnsplashClient();

  Map<String, UnsplashCredit> _visibleUnsplashCredits =
      const <String, UnsplashCredit>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _runtime ??= _prepareDemoRuntime(DefaultAssetBundle.of(context));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DemoRuntime>(
      future: _runtime,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Unable to load example icons.')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Loading example icons',
              ),
            ),
          );
        }
        return _buildEditor(snapshot.requireData);
      },
    );
  }

  Widget _buildEditor(_DemoRuntime runtime) {
    return Column(
      children: [
        Expanded(
          child: CanvasSceneEditor(
            initialScene: _demoDocument,
            resources: runtime.resources,
            shell: EditorShellConfig.standalone,
            onSceneChanged: _handleSceneChanged,
            pngExport: PngExportCapability(
              port: _ExamplePngExportPort(
                renderer: runtime.pngRenderer,
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
        UnsplashCreditBar(creditsBySourceRef: _visibleUnsplashCredits),
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
      debugPrint('Unsplash download tracking failed: $error\n$stackTrace');
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

const _demoFontFamily = 'Noto Sans Symbols';

const _demoFontAssetPath =
    'assets/fonts/noto_sans_symbols/NotoSansSymbols-Regular.ttf';

final _demoFontLoader = BundledFlutterFontLoader(
  fonts: const <BundledFlutterFont>[
    BundledFlutterFont(
      family: _demoFontFamily,
      assetPaths: <String>[_demoFontAssetPath],
    ),
  ],
  fallbackFontFamilies: const <String>[_demoFontFamily],
);

const _demoPickerFonts = <FontPickerItem>[
  FontPickerItem(family: _demoFontFamily, label: 'Noto Sans Symbols'),
];

final _demoImages = _ExampleCanvasImageAssetResolver();

typedef _DemoRuntime = ({
  CanvasRuntimeResources resources,
  CanvasPngRenderer pngRenderer,
});

Future<_DemoRuntime> _prepareDemoRuntime(AssetBundle bundle) async {
  final icons = await ExampleIconCatalog.load(bundle);
  final resources = CanvasRuntimeResources(
    fonts: _demoFontLoader,
    pickerFonts: _demoPickerFonts,
    icons: icons,
    images: _demoImages,
  );
  return (
    resources: resources,
    pngRenderer: FlutterCanvasPngRenderer(
      fonts: resources.fonts,
      icons: resources.icons,
      images: resources.images,
    ),
  );
}

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

final CanvasSceneDocument _demoDocument = CanvasSceneDocument(
  artboardSize: Size2D(740, 420),
  backgroundFill: CanvasFill.gradient(
    LinearGradientSpec(
      start: const Vec2(0, 210),
      end: const Vec2(740, 210),
      stops: const <GradientStop>[
        GradientStop(offset: 0, color: 0xFFF8FAFC),
        GradientStop(offset: 1, color: 0xFFE0E7FF),
      ],
    ),
  ),
  backgroundOpacity: 1.0,
  children: <Node>[
    Node.path(
      id: 'demo-card',
      name: 'Demo card',
      xf: Transform2D(position: Vec2(370, 210)),
      data: PathData(
        source: RectSource(x: -300, y: -140, width: 600, height: 280, rx: 32, ry: 32),
        appearance: CanvasAppearance(
          foreground: CanvasFill.solid(0xFFFFFFFF),
          stroke: CanvasStroke(color: 0xFFE0E7FF, width: 4),
        ),
      ),
    ),
    Node.icon(
      id: 'demo-icon',
      name: 'Vector icon',
      xf: Transform2D(position: Vec2(170, 150)),
      data: CanvasIconData(
        iconRef: 'icon.ring',
        sizePx: 64,
        appearance: CanvasAppearance(
          foreground: CanvasFill.gradient(
            LinearGradientSpec(
              start: const Vec2(-32, -32),
              end: const Vec2(32, 32),
              stops: const [
                GradientStop(offset: 0, color: 0xFF7C3AED),
                GradientStop(offset: 1, color: 0xFF0891B2),
              ],
            ),
          ),
          underlays: const [
            ShadowEffect(
              id: 'demo-icon-shadow',
              offset: Vec2(0, 3),
              blurSigma: 3,
              color: 0x332E1065,
            ),
          ],
        ),
      ),
    ),
    Node.text(
      id: 'demo-title',
      name: 'Title',
      xf: Transform2D(position: Vec2(410, 150)),
      data: TextData(
        text: 'CanvasSceneEditor',
        fontFamily: _demoFontFamily,
        fontWeight: 700,
        fontSize: 32,
        letterSpacing: 0,
        appearance: CanvasAppearance(foreground: CanvasFill.solid(0xFF312E81)),
      ),
    ),
    Node.text(
      id: 'demo-subtitle',
      name: 'Subtitle',
      xf: Transform2D(position: Vec2(370, 255)),
      data: TextData(
        text:
            'Select the ring to change its icon, fill, or shadow.\n'
            'Try Add → Assets for images and background removal.',
        fontFamily: _demoFontFamily,
        fontWeight: 400,
        fontSize: 18,
        letterSpacing: 0,
        appearance: CanvasAppearance(foreground: CanvasFill.solid(0xFF475569)),
      ),
    ),
  ],
);

final class _ExamplePngExportPort implements PngExportPort {
  const _ExamplePngExportPort({
    required this.renderer,
    required this.navigatorKey,
  });

  final CanvasPngRenderer renderer;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Future<String> sharePng({
    required CanvasSceneDocument scene,
    required CanvasPngSpec spec,
    required String filename,
    String? text,
  }) async {
    final context = navigatorKey.currentContext;

    if (context == null) {
      throw StateError('Unable to locate the app context for PNG sharing.');
    }

    final sharePositionOrigin = Offset.zero & MediaQuery.sizeOf(context);

    final bytes = await renderer.renderPng(scene: scene, spec: spec);

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
    required CanvasSceneDocument scene,
    required CanvasPngSpec spec,
    required String filename,
  }) {
    throw UnsupportedError('PNG saving is not available in this example.');
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

final class _ExampleCanvasImageAssetResolver
    implements CanvasImageAssetResolver {
  final DataUriImageMetadataResolver _dataUriMetadata =
      DataUriImageMetadataResolver();

  @override
  Future<Map<String, String>> resolveSources(List<String> sourceRefs) async {
    final resolved = <String, String>{};

    for (final sourceRef in sourceRefs) {
      final renderableSource = _resolveSource(sourceRef);

      if (renderableSource != null) {
        // Resolver maps are always keyed by the exact logical input ref.
        resolved[sourceRef] = renderableSource;
      }
    }

    return resolved;
  }

  String? _resolveSource(String sourceRef) {
    final trimmed = sourceRef.trim();

    if (trimmed.startsWith('data:')) {
      return trimmed;
    }

    final uri = Uri.tryParse(trimmed);

    if (uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty) {
      // Direct remote refs are already renderable by this Flutter host.
      //
      // Preserve the provider-returned URL, including its complete path and
      // query parameters. This is important for Unsplash image URLs.
      return trimmed;
    }

    if (!trimmed.startsWith('asset:')) {
      return null;
    }

    final path = _assetPathFromRef(trimmed);

    return path.isEmpty ? null : path;
  }

  @override
  Future<Map<String, Size2D>> resolveIntrinsicSizes(
    List<String> sourceRefs,
  ) async {
    final entries = await Future.wait([
      for (final sourceRef in sourceRefs) _resolveIntrinsicSizeEntry(sourceRef),
    ]);

    return Map<String, Size2D>.fromEntries(
      entries.whereType<MapEntry<String, Size2D>>(),
    );
  }

  Future<MapEntry<String, Size2D>?> _resolveIntrinsicSizeEntry(
    String sourceRef,
  ) async {
    try {
      final size = await _resolveIntrinsicSize(sourceRef);

      return size == null ? null : MapEntry<String, Size2D>(sourceRef, size);
    } catch (error, stackTrace) {
      debugPrint(
        'Example image metadata resolution failed: '
        '$error\n$stackTrace',
      );

      return null;
    }
  }

  Future<Size2D?> _resolveIntrinsicSize(String sourceRef) async {
    final trimmed = sourceRef.trim();

    if (trimmed == _backgroundRemovalDemoForegroundRef) {
      return const Size2D(320, 180);
    }

    final dataUriSize = await _dataUriMetadata.resolve(trimmed);

    if (dataUriSize != null) {
      return dataUriSize;
    }

    return _demoAssetLibrary.intrinsicSizeFor(trimmed);
  }
}
