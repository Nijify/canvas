# ISNet model conversion and verification

Standalone development tooling for reproducibly preparing and verifying TFLite
candidates from rembg's `isnet-general-use.onnx` artifact. The resulting model
contract is used by the [experimental ISNet provider](../../../packages/canvas_background_removal_isnet/)
and its [Android benchmark harness](../../../packages/canvas_background_removal_isnet/example/).

The verified 1024x1024 FP16 candidate remains **NO-GO for production** because of
its active GPU memory footprint. See the
[device benchmark decision](../../../packages/canvas_background_removal_isnet/example/evidence/pixel_7a_2026-08-20.md).
Conversion parity establishes conversion correctness; it does not establish
acceptable runtime cost or visual quality.

## Source and recorded evidence

`source.json` pins the upstream rembg artifact URL, SHA-256, and reference
implementation commit `b439167d2eb22e51e7ec0732efe771bf920ff5c1`.
`build.py` verifies the source hash before using cached or downloaded bytes.

`evidence.json` records the conversion environment, artifact hashes and sizes,
input/output tensor contracts, primary-output mapping, and numerical parity.
Its FP16 candidate is 88,135,432 bytes with SHA-256
`325ecf784635a998bd55e3fa622f4bc3a42834a8a4a1e08ed58f147eebdfda0a`.
This is the same identity checked by the provider and benchmark harness.

Model-weight redistribution status remains `unresolved`. Keep that status with
the evidence; these tools do not grant permission to redistribute model weights.
Model binaries are supplied locally for benchmarking and are excluded from Git.

## Environment

This directory is a standalone Poetry project. Its Python environment is
independent of the Dart/Flutter workspace. The checked-in `.python-version`
selects Python 3.11.9; `pyproject.toml` and `poetry.lock` pin the conversion
toolchain.

From the repository root:

```sh
cd tools/models/isnet
pyenv local 3.11.9
poetry env use "$(pyenv which python)"
poetry install
poetry run python --version
```

The reported Python version should be `3.11.9`. Install from the committed lock
for reproduction. Regenerate `poetry.lock` only as part of an intentional
toolchain update, with fresh conversion evidence. Keep these Python dependencies
out of the Dart/Flutter package dependencies.

## Build

From this directory:

```sh
poetry run python build.py --clean
```

`--clean` is required and recreates `.build/`. The source artifact may remain in
`.cache/`, but its SHA-256 is checked on every run.

The pinned `onnx2tf 1.21.0` converter normally downloads a sample `.npy` file for
internal validation. The builder supplies deterministic normalized float32 data
under `.build/onnx2tf-work/` instead, avoiding that implicit sample download.

The builder requires these exact generated candidates:

```text
.build/converted/isnet_general_use_simplified_float32.tflite
.build/converted/isnet_general_use_simplified_float16.tflite
```

No glob-first artifact selection is used. This build-time source download is
separate from runtime model delivery; the provider does not download models.

## Verify locally

After building, write a fresh local result without replacing recorded evidence:

```sh
poetry run python verify.py --write-evidence .build/evidence.local.json
```

The verifier:

- records source, simplified ONNX, FP32 TFLite, and FP16 TFLite hashes and sizes;
- records all model input/output tensor contracts;
- records TFLite API ordinals separately from internal tensor indices;
- forces ONNX Runtime to the CPU execution provider;
- feeds the same deterministic numeric values to ONNX as NCHW and TFLite as NHWC;
- identifies the TFLite output matching ONNX output 0 by numerical agreement;
- measures source-to-simplified, simplified-to-FP32, and FP32-to-FP16 parity;
- rejects missing artifacts, shape/dtype mismatches, ambiguous output mappings,
  NaN/Inf, inconsistent mappings across inputs, and parity-limit regressions.

Maximum absolute error limits are:

```text
source ONNX -> simplified ONNX       1e-6
simplified ONNX -> TFLite FP32       1e-5
TFLite FP32 -> TFLite FP16           1e-3
```

These are conversion-regression limits relative to the recorded run.
`evidence.json` uses schema version 2: `input_ordinal` and `output_ordinal` are
positions in the interpreter APIs; `tensor_index` identifies an internal tensor.
Runtime selection uses the recorded output ordinal.

For an intentional candidate or toolchain change, regenerate the tracked record:

```sh
poetry run python verify.py --write-evidence evidence.json
```

Review resulting environment, hash, tensor-contract, and parity changes.
A changed model identity also requires an explicit provider/benchmark contract
update and a new device-level viability assessment.

## Image-processing reference

The provider follows the pinned rembg image semantics:

1. Convert the source image to RGB.
2. Resize directly to `1024 x 1024` with Lanczos.
3. Divide the array by `max(max_pixel_value, 1e-6)`.
4. Subtract `0.5` from each RGB channel.
5. Supply float32 values as NCHW to ONNX or NHWC to TFLite.
6. Read the primary mask by the output ordinal recorded in the evidence.
7. Min/max normalize the mask.
8. Resize it to the original image dimensions with Lanczos before alpha composition.

Runtime implementations and physical-device measurements belong to the provider
and benchmark harness linked above.

## Generated files

`.cache/`, `.build/`, `.venv/`, Python bytecode, and ONNX/TFLite binaries are
ignored. Commit source metadata, scripts, environment pins, and reviewed
conversion evidence only.
