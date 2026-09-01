// Path: lib/canvas_renderer_flutter.dart
//
// ──────────────────────────────────────────────────────────────────────────────
// canvas_renderer_flutter – Public API (Flutter adapter)
// External packages should import *only* this file (no src/* imports).
//
// Manager-level map (+ mental models, with ROLES):

// • Low-level paint-op replay     → CanvasRenderer
// • Canonical final PNG output    → FlutterCanvasPngRenderer
// • Text measurement/painting     → FlutterTextPipeline
// • Font availability             → FlutterFontLoader
// • Images                        → FlutterImagePool
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
// 1) Low-level renderer
//    Mental model: replay core PaintOps onto a Flutter Canvas.
// ============================================================================
export 'src/flutter_canvas_renderer.dart'
    show CanvasRenderer, CanvasRendererOptions, MissingImageBehavior;

// ============================================================================
// 2) Canonical final PNG rendering
//    Mental model: scene -> resources -> preparation -> strict PNG output.
// ============================================================================
export 'src/canvas_png_renderer.dart'
    show CanvasPngRenderer, CanvasPngSpec;
export 'src/flutter_canvas_png_renderer.dart'
    show FlutterCanvasPngRenderer;

// ============================================================================
// 3) Font loading
//    Mental model: make logical canvas font families available to Flutter.
// ============================================================================
export 'src/fonts/flutter_font_loader.dart'
    show BundledFlutterFont, BundledFlutterFontLoader, FlutterFontLoader;

// ============================================================================
// 4) Text pipeline (measurement + painting)
//    Mental model: one host-provided text engine for core and Flutter rendering.
// ============================================================================
export 'src/flutter_text_pipeline.dart'
    show FlutterTextPipeline, TextSpec, TextOriginKind;

// ============================================================================
// 5) Images
//    Mental model: one pool owns decoded rasters, intrinsic metadata,
//    repaint notifications, and resource disposal.
// ============================================================================
export 'src/images/flutter_image_pool.dart'
    show FlutterImageDecoder, FlutterImagePool;

// ============================================================================
// 6) Gradients (adapter)
//    Mental model: core resolves gradient math; adapter builds ui.Shader.
// ============================================================================
export 'src/flutter_linear_shader.dart'
    show buildLinearShaderFlutter, buildLinearShaderFromResolved;

// ============================================================================
// 7) Value mappers (core ↔ Flutter)
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
