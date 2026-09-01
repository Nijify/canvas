// Path: lib/canvas_renderer_flutter.dart
//
// ──────────────────────────────────────────────────────────────────────────────
// canvas_renderer_flutter – Public API (Flutter adapter)
// External packages should import *only* this file (no src/* imports).
//
// Manager-level map (+ mental models, with ROLES):
// • Draw paint ops on Flutter     → CanvasRenderer            // Replays core paint ops on a Canvas
// • Text measurement/painting     → FlutterText*              // Host text pipeline (measure + paint)
// • Images                        → FlutterImagePool          // Raster + intrinsic owner
// • Gradient adapter              → buildLinearShaderFlutter  // Core gradient → ui.Shader
// • Type mappers                  → *ToUi / *ToCore           // Core ↔ Flutter value adapters
//
// Optional ImageProvider helpers live in
// `canvas_renderer_flutter_image_providers.dart`.
// Layering rules:
// • Depends on canvas_core contracts.
// • No business logic. No schema, tokens, or z-order rules here.
// • Renderer = “how” to draw; core already decided “what” to draw.
// ──────────────────────────────────────────────────────────────────────────────

library;

// ============================================================================
// 1) Renderer façade
//    Mental model: take PaintOps from core, draw them onto a Flutter Canvas.
// ============================================================================
export 'src/flutter_canvas_renderer.dart'
    show CanvasRenderer, CanvasRendererOptions, MissingImageBehavior;

export 'src/canvas_document_exporter.dart'
    show CanvasDocumentExporter, CanvasExportSpec;

// ============================================================================
// 2) Font loading
//    Mental model: make logical canvas font families available to Flutter.
// ============================================================================
export 'src/fonts/flutter_font_loader.dart'
    show BundledCanvasFont, BundledFlutterFontLoader, FlutterFontLoader;

// ============================================================================
// 2) Text pipeline (measurement + painting)
//    Mental model: one host-provided text engine for core and Flutter rendering.
// ============================================================================
export 'src/flutter_text_pipeline.dart'
    show FlutterTextPipeline, TextSpec, TextOriginKind;

// ============================================================================
// 3) Images
//    Mental model: one pool owns decoded rasters, intrinsic metadata,
//    repaint notifications, and resource disposal.
// ============================================================================
export 'src/images/flutter_image_pool.dart'
    show FlutterImageDecoder, FlutterImagePool;

// ============================================================================
// 4) Gradients (adapter)
//    Mental model: core resolves gradient math; adapter builds ui.Shader.
// ============================================================================
export 'src/flutter_linear_shader.dart'
    show buildLinearShaderFlutter, buildLinearShaderFromResolved;

// ============================================================================
// 5) Value mappers (core ↔ Flutter)
//    Mental model: tiny extensions to bridge core PODs and ui types.
// ============================================================================
export 'src/flutter_mappers.dart'
    show
        Vec2ToUi,
        OffsetToCore,
        Size2DToUi,
        SizeToCore,
        Rect2DToUi,
        Color32ToUi;
