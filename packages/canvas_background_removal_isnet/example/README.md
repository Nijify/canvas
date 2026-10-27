# ISNet Android benchmark harness

This app provides development evidence for `canvas_background_removal_isnet`. Model files are supplied locally by the person running the example.

## Decision reached

The verified 1024x1024 FP16 ISNet candidate is **NO-GO for mobile production promotion** after physical Pixel 7a testing.

The best tested backend, strict CompiledModel GPU fp16, produced promising latency and first-image parity but still required an excessively high active GPU memory footprint. Android memory reporting also showed that most of the GPU allocation is reclaimed when the worker closes, so the blocker is the operating-footprint/compile-latency trade-off rather than an obvious permanent leak.

The complete measured decision record is:

```text
example/evidence/pixel_7a_2026-08-20.md
```

Do not extend this PR with downloader/model-delivery code, provider selection, fallback, feature flags, rollout plumbing, or additional runtime backends for this candidate. Production background removal remains ML Kit-backed. A future materially smaller/lower-resolution model candidate should be evaluated in a separate PR using this harness as the baseline.

## Inputs

Use the verified FP16 candidate only:

- size: `88,135,432` bytes
- SHA-256: `325ecf784635a998bd55e3fa622f4bc3a42834a8a4a1e08ed58f147eebdfda0a`

Every engine re-verifies the model identity before opening it.

## Engines under test

The harness keeps four evidence modes:

1. **Interpreter** — the frozen classic LiteRT reference implementation.
2. **CompiledModel CPU fp32** — LiteRT Next CPU-only, using host-memory tensor buffers.
3. **CompiledModel GPU fp32** — strict Android GPU-only LiteRT Next compilation using fp32 execution precision.
4. **CompiledModel GPU fp16** — strict Android GPU-only LiteRT Next compilation using fp16 execution precision.

CompiledModel uses `TensorBufferMode.hostMemory` and reads only output ordinal 0. Do not replace this with `CompiledModel.run()`: this ISNet graph declares 12 outputs and managed `run()` would allocate Dart buffers for all of them.

Both GPU modes are intentionally strict. They do not silently fall back to CPU. If GPU compilation/open fails on a device, record that failure as GPU evidence rather than reporting CPU numbers as GPU numbers.

The source model remains the verified FP16 TFLite artifact. The `fp32` / `fp16` engine labels refer to LiteRT Next execution precision, not to different model files.

## Run on a real Android device

From the repository root:

```sh
melos bootstrap
cd packages/canvas_background_removal_isnet/example
flutter run --profile
```

As with `flutter_frontend`, Android wrapper scripts/JARs are generated locally and are intentionally ignored by Git.

Use a physical arm64 Android device for evidence. Debug-mode timings are not acceptance data. The Android build includes LiteRT Next's GPU accelerator because GPU is an explicit benchmark mode.

## Per-image benchmark sequence

When reproducing the existing evidence or evaluating a future candidate, always establish correctness before comparing performance:

1. Select the local `.tflite` candidate through the Android system document picker.
2. Select a static PNG, JPEG, or WebP input image.
3. The Android host streams each selected document directly into app-private cache and returns only the local path/name to Dart. Large files are never marshalled as platform-channel byte payloads.
4. Select **Interpreter**.
5. Tap **Open selected engine**.
6. Tap **Run 1 cold + 5 warm**. This captures the Interpreter output as the correctness reference for the current image.
7. Use **CompiledModel CPU fp32** only as negative/reference evidence when useful.
8. Select **CompiledModel GPU fp32**. Tap **Open selected engine**, then **Run 1 cold + 5 warm**. Record timings, sampled per-operation RSS, and alpha parity.
9. Select **CompiledModel GPU fp16**. Tap **Open selected engine**, then **Run 1 cold + 5 warm**. Record the same measurements and compare them directly with GPU fp32 and the Interpreter output.
10. If either strict GPU mode fails to open, record the failure and do not reinterpret it as CPU fallback.

Re-open the selected engine before every new cold-run measurement. Selecting a different image clears the stored Interpreter reference, so the correctness sequence starts again.

The harness reports the effective accelerator set returned by LiteRT Next and `isFullyAccelerated` when available.

## Memory measurement

The displayed peak RSS is a **sampled per-open/per-run peak**, not Dart's process-lifetime `ProcessInfo.maxRss`. The caller isolate samples process RSS every 25 ms while the worker is opening or running. This matters when comparing engines sequentially: a previous high-memory run must not force every later result to inherit that historical peak.

RSS before/after remains process-wide. The sampled peak is evidence suitable for comparing these benchmark modes, but it is not a byte-perfect native allocator trace; short-lived spikes between samples can be missed.

Corroborate important GPU results with Android's own process-memory report:

```sh
adb shell dumpsys meminfo com.nijify.isnetbenchmark
```

Capture it after engine open, after inference, and after closing/switching away from the GPU worker when release behavior matters.

## Correctness gate

A successful CompiledModel status is not enough. The harness compares its final transparent PNG alpha channel with the Interpreter output for the same image and reports:

- mean absolute alpha difference on a 0-255 scale;
- maximum absolute alpha difference;
- fraction of pixels differing by more than 1 alpha level;
- fraction of pixels differing by more than 5 alpha levels.

Always inspect the visual result as well. These metrics are benchmark evidence, not a predeclared product-quality threshold.

## Current candidate outcome

The Pixel 7a evidence established:

- Interpreter: correct but too slow and memory-heavy;
- CompiledModel CPU fp32: correct but slower and heavier than Interpreter;
- CompiledModel GPU fp32: much faster with excellent parity, but with an excessive GPU memory footprint;
- CompiledModel GPU fp16: best latency/memory trade-off tested and good first-image parity, but still with an excessive active GPU footprint for a general Android feature;
- closing/switching away from the GPU fp16 worker reclaims most of the graphics allocation, so the high footprint is not evidence of an obvious permanent leak.

The runtime viability gate therefore failed before the broader representative-image quality suite became worthwhile. Do not expand that suite for this candidate merely to complete a checklist; first establish a future model/runtime candidate with a materially viable memory operating point.

## Future evidence set

For a future candidate that first passes the runtime viability gate, run representative owned images covering:

- portrait / hair / thin edges;
- landscape;
- square image;
- product or isolated object;
- low-contrast foreground/background;
- a high-resolution phone photo.

For the decision record, capture device model, Android version, ABI, build mode, engine, execution precision, effective accelerators, fully-accelerated flag, worker-open time, RSS before/after open, cold total/inference, five warm total/inference values, preprocessing, postprocessing, sampled peak RSS, alpha-parity metrics, output dimensions, and visible quality deviations.

The cached selections are replaced/cleaned by the harness; no model binary belongs in this repository.