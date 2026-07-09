# Versioning

`canvas_core` follows [Dart package versioning](https://dart.dev/tools/pub/versioning) and semantic versioning.

While the package is below `1.0.0`, it follows the Dart package convention for pre-1.0 releases:

- `0.(x+1).0` may include breaking public API or behavior changes.
- `0.x.(y+1)` is used for backward-compatible public API additions.
- `0.x.y+1` may be used for changes that do not affect the public API.

After `1.0.0`, standard semantic versioning applies:

- `MAJOR` versions may include breaking changes.
- `MINOR` versions add backward-compatible functionality.
- `PATCH` versions include backward-compatible fixes.

Public API includes exported Dart APIs, serialized model shapes, and behavior that package users can reasonably depend on.

When in doubt, `canvas_core` treats a change as breaking.
