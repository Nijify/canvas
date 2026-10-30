#!/usr/bin/env python3
# Path: tools/models/isnet/build.py
"""Build reproducible ISNet TFLite candidates from the pinned rembg ONNX."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import tempfile
import urllib.request

ROOT = Path(__file__).resolve().parent
SOURCE_MANIFEST = ROOT / "source.json"
CACHE_DIR = ROOT / ".cache"
BUILD_DIR = ROOT / ".build"
SOURCE_ONNX = CACHE_DIR / "isnet-general-use.onnx"
SIMPLIFIED_ONNX = BUILD_DIR / "isnet_general_use_simplified.onnx"
CONVERTED_DIR = BUILD_DIR / "converted"
ONNX2TF_WORK_DIR = BUILD_DIR / "onnx2tf-work"
ONNX2TF_SAMPLE_FILE = "calibration_image_sample_data_20x128x128x3_float32.npy"
TFLITE_FP32 = CONVERTED_DIR / "isnet_general_use_simplified_float32.tflite"
TFLITE_FP16 = CONVERTED_DIR / "isnet_general_use_simplified_float16.tflite"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_manifest() -> dict:
    with SOURCE_MANIFEST.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def require_sha256(path: Path, expected: str) -> None:
    actual = sha256_file(path)
    if actual.lower() != expected.lower():
        raise RuntimeError(
            f"SHA-256 mismatch for {path}: expected {expected}, got {actual}"
        )


def ensure_source(manifest: dict) -> Path:
    source = manifest["source"]
    url = source["url"]
    expected_sha256 = source["sha256"]
    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    if SOURCE_ONNX.exists():
        require_sha256(SOURCE_ONNX, expected_sha256)
        print(f"[ok] verified cached source: {SOURCE_ONNX}")
        return SOURCE_ONNX

    fd, temp_name = tempfile.mkstemp(
        prefix="isnet-general-use-", suffix=".onnx", dir=CACHE_DIR
    )
    os.close(fd)
    temp_path = Path(temp_name)
    try:
        print(f"[download] {url}")
        with urllib.request.urlopen(url) as response, temp_path.open("wb") as output:
            shutil.copyfileobj(response, output)
        require_sha256(temp_path, expected_sha256)
        os.replace(temp_path, SOURCE_ONNX)
    finally:
        if temp_path.exists():
            temp_path.unlink()

    print(f"[ok] downloaded and verified: {SOURCE_ONNX}")
    return SOURCE_ONNX


def clean_build() -> None:
    if BUILD_DIR.exists():
        shutil.rmtree(BUILD_DIR)
    CONVERTED_DIR.mkdir(parents=True, exist_ok=True)


def simplify_onnx(source_path: Path) -> None:
    import onnx
    from onnxsim import simplify

    print("[build] validating source ONNX")
    model = onnx.load(str(source_path))
    onnx.checker.check_model(model)

    print("[build] simplifying ONNX")
    simplified, ok = simplify(model)
    if not ok:
        raise RuntimeError("onnxsim reported an unsuccessful simplification")
    onnx.checker.check_model(simplified)
    onnx.save(simplified, str(SIMPLIFIED_ONNX))


def prepare_onnx2tf_test_data() -> Path:
    """Seed onnx2tf's pinned validation fixture locally and deterministically."""
    import numpy as np

    ONNX2TF_WORK_DIR.mkdir(parents=True, exist_ok=True)
    sample_path = ONNX2TF_WORK_DIR / ONNX2TF_SAMPLE_FILE

    value_count = 20 * 128 * 128 * 3
    sample = np.linspace(
        0.0,
        1.0,
        num=value_count,
        endpoint=True,
        dtype=np.float32,
    ).reshape((20, 128, 128, 3))
    np.save(sample_path, sample, allow_pickle=False)

    print(f"[build] seeded deterministic onnx2tf validation data: {sample_path}")
    return ONNX2TF_WORK_DIR


def convert_tflite() -> None:
    from onnx2tf import convert

    work_dir = prepare_onnx2tf_test_data()
    original_cwd = Path.cwd()

    print("[build] converting simplified ONNX with onnx2tf")
    try:
        # onnx2tf 1.21.0 looks for its validation sample in os.getcwd(). Running
        # from the ignored build workspace prevents an implicit network download
        # while keeping all converter scratch files out of the repository tree.
        os.chdir(work_dir)
        convert(
            input_onnx_file_path=str(SIMPLIFIED_ONNX),
            output_folder_path=str(CONVERTED_DIR),
            batch_size=1,
        )
    finally:
        os.chdir(original_cwd)

    missing = [path for path in (TFLITE_FP32, TFLITE_FP16) if not path.is_file()]
    if missing:
        rendered = ", ".join(str(path) for path in missing)
        raise RuntimeError(f"onnx2tf did not produce required artifacts: {rendered}")


def print_artifacts(source_path: Path) -> None:
    artifacts = {
        "source_onnx": source_path,
        "simplified_onnx": SIMPLIFIED_ONNX,
        "tflite_fp32": TFLITE_FP32,
        "tflite_fp16": TFLITE_FP16,
    }
    print("[artifacts]")
    for name, path in artifacts.items():
        print(
            f"  {name}: {path} | {path.stat().st_size} bytes | sha256={sha256_file(path)}"
        )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--clean",
        action="store_true",
        help="Delete generated conversion outputs before rebuilding.",
    )
    args = parser.parse_args()

    if not args.clean:
        raise SystemExit("Refusing incremental conversion. Run with --clean.")

    manifest = load_manifest()
    source_path = ensure_source(manifest)
    clean_build()
    simplify_onnx(source_path)
    convert_tflite()
    print_artifacts(source_path)


if __name__ == "__main__":
    main()
