# Versioning

The public packages in this workspace follow
[Dart package versioning](https://dart.dev/tools/pub/versioning) and semantic
versioning.

While a package is below `1.0.0`, it follows the Dart package convention for
pre-1.0 releases:

- `0.(x+1).0` may include breaking public API or behavior changes.
- `0.x.(y+1)` is used for backward-compatible public API additions.
- `0.x.y+1` may be used for changes that do not affect the public API.

After `1.0.0`, standard semantic versioning applies:

- `MAJOR` versions may include breaking changes.
- `MINOR` versions add backward-compatible functionality.
- `PATCH` versions include backward-compatible fixes.

Public API includes exported Dart APIs, serialized model shapes, and behavior
that package users can reasonably depend on.

When in doubt, the workspace treats a change as breaking.

## Publishing releases

For each package version published to pub.dev:

1. Update the package's `pubspec.yaml` and `CHANGELOG.md`.
2. Run the package-appropriate analysis and tests, followed by
   `dart pub publish --dry-run`.
3. Publish with `dart pub publish`.
4. Tag the exact published commit with a package-qualified tag and push it.

Use these tag formats:

- `canvas_core-v<version>`
- `canvas_renderer_flutter-v<version>`
- `canvas_editor_flutter-v<version>`

A coordinated release may place multiple package tags on the same commit.
Do not use an unqualified `v<version>` tag because independent package
versions can overlap.
