# canvas_background_removal

Unpublished, opt-in background-removal orchestration for Canvas. This package
implements the existing `BackgroundRemovalPort` contract without a native
provider dependency. Host callbacks read an opaque source reference and save a
validated, static, transparency-capable PNG at the original display-oriented
dimensions. The host owns persistence, stale/unreferenced output cleanup, and
platform availability policy.

`CanvasBackgroundRemovalPort(readSource: ..., persistPng: ..., processor: ...)`
accepts a `BackgroundRemovalByteProcessor` from an optional provider.
Provider errors and malformed outputs never expose raw diagnostics to the editor.
Supported inputs: static PNG, JPEG, and WebP.
