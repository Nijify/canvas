#!/usr/bin/env python3
# Path: tools/models/isnet/verify.py
"""Inspect ISNet artifacts and quantify ONNX/TFLite numerical parity."""

from __future__ import annotations

import argparse
import hashlib
import importlib.metadata
import json
import platform
from pathlib import Path
from typing import Any

import numpy as np
import onnxruntime as ort
import tensorflow as tf

ROOT = Path(__file__).resolve().parent
SOURCE_MANIFEST = ROOT / "source.json"
CACHE_DIR = ROOT / ".cache"
BUILD_DIR = ROOT / ".build"
SOURCE_ONNX = CACHE_DIR / "isnet-general-use.onnx"
SIMPLIFIED_ONNX = BUILD_DIR / "isnet_general_use_simplified.onnx"
TFLITE_FP32 = BUILD_DIR / "converted/isnet_general_use_simplified_float32.tflite"
TFLITE_FP16 = BUILD_DIR / "converted/isnet_general_use_simplified_float16.tflite"

# These are regression gates, not model-quality thresholds. They are deliberately
# loose relative to the first clean evidence run while still rejecting a
# materially different conversion.
MAX_ABSOLUTE_ERROR_LIMITS = {
    "source_vs_simplified": 1e-6,
    "simplified_vs_tflite_fp32": 1e-5,
    "tflite_fp32_vs_fp16": 1e-3,
}


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def artifact_record(path: Path) -> dict[str, Any]:
    return {"sha256": sha256_file(path), "size_bytes": path.stat().st_size}


def dtype_name(value: Any) -> str:
    try:
        return np.dtype(value).name
    except TypeError:
        return str(value)


def onnx_contract(path: Path) -> dict[str, Any]:
    session = ort.InferenceSession(str(path), providers=["CPUExecutionProvider"])
    return {
        "inputs": [
            {"name": item.name, "shape": list(item.shape), "dtype": item.type}
            for item in session.get_inputs()
        ],
        "outputs": [
            {"name": item.name, "shape": list(item.shape), "dtype": item.type}
            for item in session.get_outputs()
        ],
    }


def tflite_contract(path: Path) -> dict[str, Any]:
    interpreter = tf.lite.Interpreter(model_path=str(path))
    interpreter.allocate_tensors()
    return {
        "inputs": [
            {
                "input_ordinal": ordinal,
                "tensor_index": int(item["index"]),
                "name": item["name"],
                "shape": item["shape"].astype(int).tolist(),
                "dtype": dtype_name(item["dtype"]),
            }
            for ordinal, item in enumerate(interpreter.get_input_details())
        ],
        "outputs": [
            {
                "output_ordinal": ordinal,
                "tensor_index": int(item["index"]),
                "name": item["name"],
                "shape": item["shape"].astype(int).tolist(),
                "dtype": dtype_name(item["dtype"]),
            }
            for ordinal, item in enumerate(interpreter.get_output_details())
        ],
    }


def run_onnx(path: Path, nhwc: np.ndarray) -> list[np.ndarray]:
    session = ort.InferenceSession(str(path), providers=["CPUExecutionProvider"])
    inputs = session.get_inputs()
    if len(inputs) != 1:
        raise RuntimeError(f"Expected one ONNX input, got {len(inputs)}")
    nchw = np.transpose(nhwc, (0, 3, 1, 2)).astype(np.float32, copy=False)
    return [np.asarray(value) for value in session.run(None, {inputs[0].name: nchw})]


def run_tflite(
    path: Path,
    nhwc: np.ndarray,
) -> list[tuple[int, dict[str, Any], np.ndarray]]:
    interpreter = tf.lite.Interpreter(model_path=str(path))
    interpreter.allocate_tensors()
    inputs = interpreter.get_input_details()
    if len(inputs) != 1:
        raise RuntimeError(f"Expected one TFLite input, got {len(inputs)}")
    input_detail = inputs[0]
    if input_detail["shape"].astype(int).tolist() != list(nhwc.shape):
        raise RuntimeError(
            f"Unexpected TFLite input shape: {input_detail['shape'].tolist()}"
        )
    if np.dtype(input_detail["dtype"]) != np.dtype(np.float32):
        raise RuntimeError(f"Expected float32 TFLite input, got {input_detail['dtype']}")
    interpreter.set_tensor(
        int(input_detail["index"]),
        nhwc.astype(np.float32, copy=False),
    )
    interpreter.invoke()
    return [
        (
            output_ordinal,
            detail,
            np.asarray(interpreter.get_tensor(int(detail["index"]))),
        )
        for output_ordinal, detail in enumerate(interpreter.get_output_details())
    ]


def canonical_mask(value: np.ndarray) -> np.ndarray | None:
    value = np.asarray(value)
    if value.ndim != 4 or value.shape[0] != 1:
        return None
    if value.shape[1] == 1:
        return value[0, 0, :, :].astype(np.float32, copy=False)
    if value.shape[3] == 1:
        return value[0, :, :, 0].astype(np.float32, copy=False)
    return None


def metrics(reference: np.ndarray, candidate: np.ndarray) -> dict[str, Any]:
    if reference.shape != candidate.shape:
        raise RuntimeError(f"Shape mismatch: {reference.shape} vs {candidate.shape}")
    diff = np.abs(reference.astype(np.float64) - candidate.astype(np.float64))
    finite = bool(np.isfinite(reference).all() and np.isfinite(candidate).all())
    return {
        "mean_absolute_error": float(np.mean(diff)),
        "max_absolute_error": float(np.max(diff)),
        "p99_absolute_error": float(np.percentile(diff, 99)),
        "all_finite": finite,
    }


def tflite_output_selector(
    output_ordinal: int,
    detail: dict[str, Any],
) -> dict[str, Any]:
    return {
        "output_ordinal": output_ordinal,
        "tensor_index": int(detail["index"]),
        "name": detail["name"],
        "shape": detail["shape"].astype(int).tolist(),
        "dtype": dtype_name(detail["dtype"]),
    }


def selector_key(selector: dict[str, Any]) -> tuple[Any, ...]:
    return (
        selector["output_ordinal"],
        selector["tensor_index"],
        selector["name"],
        tuple(selector["shape"]),
        selector["dtype"],
    )


def match_tflite_primary(
    reference_mask: np.ndarray,
    outputs: list[tuple[int, dict[str, Any], np.ndarray]],
) -> tuple[dict[str, Any], np.ndarray, dict[str, Any]]:
    candidates: list[
        tuple[float, dict[str, Any], np.ndarray, dict[str, Any]]
    ] = []
    for output_ordinal, detail, value in outputs:
        mask = canonical_mask(value)
        if mask is None or mask.shape != reference_mask.shape:
            continue
        current_metrics = metrics(reference_mask, mask)
        candidates.append(
            (
                current_metrics["mean_absolute_error"],
                tflite_output_selector(output_ordinal, detail),
                mask,
                current_metrics,
            )
        )
    if not candidates:
        raise RuntimeError("No TFLite output can represent the ONNX primary mask")
    candidates.sort(key=lambda item: item[0])
    if len(candidates) > 1 and np.isclose(
        candidates[0][0],
        candidates[1][0],
        atol=1e-12,
        rtol=0.0,
    ):
        raise RuntimeError("TFLite primary mask mapping is ambiguous")
    _, selector, mask, current_metrics = candidates[0]
    return selector, mask, current_metrics


def gradient_input() -> np.ndarray:
    height = width = 1024
    x = np.linspace(-0.5, 0.5, width, dtype=np.float32)
    y = np.linspace(-0.5, 0.5, height, dtype=np.float32)
    yy, xx = np.meshgrid(y, x, indexing="ij")
    return np.stack((xx, yy, (xx + yy) * 0.5), axis=-1)[None, ...]


def random_input() -> np.ndarray:
    rng = np.random.default_rng(20260819)
    return rng.uniform(-0.5, 0.5, size=(1, 1024, 1024, 3)).astype(np.float32)


def enforce_parity_record(case_name: str, label: str, record: dict[str, Any]) -> None:
    if not record["all_finite"]:
        raise RuntimeError(f"{case_name}: {label} produced NaN or Inf")
    limit = MAX_ABSOLUTE_ERROR_LIMITS[label]
    observed = record["max_absolute_error"]
    if observed > limit:
        raise RuntimeError(
            f"{case_name}: {label} max absolute error {observed} exceeds {limit}"
        )


def verify_case(
    name: str,
    nhwc: np.ndarray,
) -> tuple[dict[str, Any], dict[str, Any], dict[str, Any]]:
    source_outputs = run_onnx(SOURCE_ONNX, nhwc)
    simplified_outputs = run_onnx(SIMPLIFIED_ONNX, nhwc)
    if not source_outputs or not simplified_outputs:
        raise RuntimeError("ONNX model returned no outputs")

    source_primary = canonical_mask(source_outputs[0])
    simplified_primary = canonical_mask(simplified_outputs[0])
    if source_primary is None or simplified_primary is None:
        raise RuntimeError("ONNX output[0] is not a supported primary mask tensor")

    source_vs_simplified = metrics(source_primary, simplified_primary)

    fp32_outputs = run_tflite(TFLITE_FP32, nhwc)
    fp32_selector, fp32_primary, simplified_vs_fp32 = match_tflite_primary(
        simplified_primary,
        fp32_outputs,
    )

    fp16_outputs = run_tflite(TFLITE_FP16, nhwc)
    fp16_selector, _, fp32_vs_fp16 = match_tflite_primary(
        fp32_primary,
        fp16_outputs,
    )

    parity_record = {
        "source_vs_simplified": source_vs_simplified,
        "simplified_vs_tflite_fp32": simplified_vs_fp32,
        "tflite_fp32_vs_fp16": fp32_vs_fp16,
    }
    for label, record in parity_record.items():
        enforce_parity_record(name, label, record)

    return parity_record, fp32_selector, fp16_selector


def package_version(name: str) -> str:
    try:
        return importlib.metadata.version(name)
    except importlib.metadata.PackageNotFoundError:
        return "not-installed"


def require_artifacts() -> None:
    for path in (SOURCE_ONNX, SIMPLIFIED_ONNX, TFLITE_FP32, TFLITE_FP16):
        if not path.is_file():
            raise RuntimeError(f"Missing artifact: {path}. Run build.py --clean first.")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--write-evidence",
        type=Path,
        required=True,
        help="Path for generated evidence JSON, usually evidence.json.",
    )
    args = parser.parse_args()

    require_artifacts()
    with SOURCE_MANIFEST.open("r", encoding="utf-8") as handle:
        source_manifest = json.load(handle)

    expected_source_sha = source_manifest["source"]["sha256"]
    actual_source_sha = sha256_file(SOURCE_ONNX)
    if actual_source_sha.lower() != expected_source_sha.lower():
        raise RuntimeError(
            f"Source SHA-256 mismatch: expected {expected_source_sha}, got {actual_source_sha}"
        )

    parity: dict[str, Any] = {}
    fp32_selectors: list[dict[str, Any]] = []
    fp16_selectors: list[dict[str, Any]] = []
    for case_name, case_input in (
        ("gradient", gradient_input()),
        ("seeded_random", random_input()),
    ):
        case_parity, fp32_selector, fp16_selector = verify_case(
            case_name,
            case_input,
        )
        parity[case_name] = case_parity
        fp32_selectors.append(fp32_selector)
        fp16_selectors.append(fp16_selector)

    if len({selector_key(item) for item in fp32_selectors}) != 1:
        raise RuntimeError("FP32 primary TFLite output mapping changed across inputs")
    if len({selector_key(item) for item in fp16_selectors}) != 1:
        raise RuntimeError("FP16 primary TFLite output mapping changed across inputs")

    evidence = {
        "schema_version": 2,
        "model_id": source_manifest["model_id"],
        "source": artifact_record(SOURCE_ONNX),
        "environment": {
            "python": platform.python_version(),
            "platform": platform.platform(),
            "machine": platform.machine(),
            "packages": {
                name: package_version(name)
                for name in (
                    "numpy",
                    "onnx",
                    "onnxruntime",
                    "onnxsim",
                    "onnx2tf",
                    "tensorflow",
                    "tf-keras",
                )
            },
        },
        "artifacts": {
            "simplified_onnx": artifact_record(SIMPLIFIED_ONNX),
            "tflite_fp32": artifact_record(TFLITE_FP32),
            "tflite_fp16": artifact_record(TFLITE_FP16),
        },
        "contracts": {
            "source_onnx": onnx_contract(SOURCE_ONNX),
            "simplified_onnx": onnx_contract(SIMPLIFIED_ONNX),
            "tflite_fp32": tflite_contract(TFLITE_FP32),
            "tflite_fp16": tflite_contract(TFLITE_FP16),
            "primary_output": {
                "tflite_fp32": fp32_selectors[0],
                "tflite_fp16": fp16_selectors[0],
            },
        },
        "parity_limits": {
            "max_absolute_error": MAX_ABSOLUTE_ERROR_LIMITS,
        },
        "parity": parity,
        "redistribution_status": source_manifest["redistribution_status"],
    }

    output_path = args.write_evidence
    if not output_path.is_absolute():
        output_path = ROOT / output_path
    output_path.write_text(
        json.dumps(evidence, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(evidence, indent=2, sort_keys=True))
    print(f"[ok] wrote evidence: {output_path}")


if __name__ == "__main__":
    main()
