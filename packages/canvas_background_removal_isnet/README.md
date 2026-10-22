# canvas_background_removal_isnet

**Experimental only — NOT supported for production.** The verified 1024×1024
FP16 ISNet candidate is a NO-GO for production due to excessive active GPU
memory on Pixel 7a. See
[benchmark evidence](example/evidence/pixel_7a_2026-08-20.md).

This package does not include or download any model. The host supplies the
verified model file, model configuration, and owns the worker lifecycle.
`IsnetByteProcessor` adapts the host-opened worker to the shared interface.
Do not add provider selection, production fallback, model distribution, or
rollout infrastructure for the current candidate. Model redistribution rights
are unresolved and must be assessed before future distribution.
