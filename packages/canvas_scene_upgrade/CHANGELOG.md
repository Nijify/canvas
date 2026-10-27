## 0.2.0

- Extend the optional historical chain through v4 -> v5, baking pivots into affine matrices and accepting explicit layout services when required.

## 0.1.0

- Extract explicit historical scene upgrades from `canvas_core` into an optional
  pure-Dart package. Support v1/v2/v3 -> v4, current v4 validation, and explicitly
  identified unversioned canvas_core 0.10.x documents.
- Expose one `upgradeCanvasScene` entry point. Keep intermediate converters and
  historical validators internal, with final current decoding at the boundary.
- Retain historical geometry/resource fidelity limits and ambiguity rejection.
