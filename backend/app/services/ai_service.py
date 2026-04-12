"""
AI Service — Photo Analysis + Voice Transcription
Loads YOLOv8m once at module startup.
Provides:
  analyze_photo(image_bytes)  → {"category": str, "confidence": float}
  transcribe_voice(audio_path) → str  (plain transcription text)
"""

from pathlib import Path

import cv2
import numpy as np
from ultralytics import YOLO
from faster_whisper import WhisperModel

# ── Model path ────────────────────────────────────────────────────────────────
# ai_service.py lives in  backend/app/services/
# parents[1]            =  backend/app/
_MODEL_PATH = Path(__file__).resolve().parents[1] / "ai_models" / "yolov8m.pt"

if not _MODEL_PATH.exists():
    raise FileNotFoundError(
        f"YOLOv8m model not found at {_MODEL_PATH}. "
        "Copy yolov8m.pt into backend/app/ai_models/"
    )

# Load once — module-level singleton
_model = YOLO(str(_MODEL_PATH))

# Minimum confidence to accept a detection
_CONF_THRESHOLD = 0.70


# ── Public API ─────────────────────────────────────────────────────────────────

def analyze_photo(image_bytes: bytes) -> dict:
    """
    Run YOLOv8m detection on raw image bytes.

    Returns:
        {"category": str, "confidence": float}
        If nothing is detected above threshold: {"category": "unknown", "confidence": 0.0}
    """
    arr = np.frombuffer(image_bytes, np.uint8)
    image = cv2.imdecode(arr, cv2.IMREAD_COLOR)

    if image is None:
        return {"category": "unknown", "confidence": 0.0}

    # Run YOLO inference
    results = _model.predict(source=image, verbose=False)

    if not results or results[0].boxes is None:
        return {"category": "unknown", "confidence": 0.0}

    # Collect detections above threshold
    detections = []
    for box in results[0].boxes:
        conf = float(box.conf[0])
        if conf < _CONF_THRESHOLD:
            continue
        cls_id = int(box.cls[0])
        category = _model.names[cls_id]
        detections.append({"category": category, "conf": conf})

    if not detections:
        return {"category": "unknown", "confidence": 0.0}

    # Take the highest-confidence detection
    detections.sort(key=lambda d: d["conf"], reverse=True)
    top = detections[0]

    return {
        "category": top["category"],
        "confidence": round(top["conf"], 4),
    }


def analyze_photos(images_bytes_list: list) -> dict:
    """
    Run analyze_photo() on each image in the list and return the single
    highest-confidence result across all images.

    Returns:
        {"category": str, "confidence": float}
        If every image returns "unknown": {"category": "unknown", "confidence": 0.0}
    """
    best = {"category": "unknown", "confidence": 0.0}
    for image_bytes in images_bytes_list:
        result = analyze_photo(image_bytes)
        if result["confidence"] > best["confidence"]:
            best = result
    return best


# ── Whisper model — loaded once at module level ────────────────────────────────
# "small" gives better accuracy for Arabic + English than "base".
# device="cuda" + compute_type="float16" uses GPU half-precision for fast inference.
# faster-whisper auto-downloads the model (~460 MB) on first use.
_whisper_model = WhisperModel("small", device="cpu", compute_type="int8")


def transcribe_voice(audio_path: str) -> str:
    """
    Transcribe an audio file using faster-whisper (base model).

    Args:
        audio_path: Absolute path to the audio file on disk.

    Returns:
        Full transcription as a single plain string.
        Returns an empty string if no speech was detected.
    """
    segments, _info = _whisper_model.transcribe(audio_path , language="en")
    return " ".join(segment.text.strip() for segment in segments).strip()
