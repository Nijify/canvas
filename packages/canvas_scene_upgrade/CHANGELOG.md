## Unreleased

- Project historical documents to scene v7. Require explicit host preparation for group behaviors and preserve visible ordinary layers without mutating source documents.

## 0.3.0

- Upgrade v5 and supported earlier documents to canonical v6 JSON.
- Reconstruct historical pivots from v4 wire fields using shared geometry
  primitives. Validate the final document through the current core decoder.

## 0.2.0

- Extend the optional historical chain through v4 -> v5, baking pivots into affine matrices and accepting explicit layout services when required.

## 0.1.0

- Extract explicit historical scene upgrades from `canvas_core` into an optional
  pure-Dart package. Support v1/v2/v3 -> v4, current v4 validation, and explicitly
  identified unversioned canvas_core 0.10.x documents.
- Expose one `upgradeCanvasScene` entry point. Keep intermediate converters and
  historical validators internal, with final current decoding at the boundary.
- Retain historical geometry/resource fidelity limits and ambiguity rejection.
