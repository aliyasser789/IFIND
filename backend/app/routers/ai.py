"""
AI Router — Step 10: Photo Analysis Preview
           Step 11: Voice Transcription
POST /ai/analyze-photo    — no auth required, does NOT save to DB.
POST /ai/transcribe-voice — no auth required, returns transcription text.
"""

import os
import tempfile

from fastapi import APIRouter, File, HTTPException, UploadFile, status

from app.services.ai_service import analyze_photo, transcribe_voice

router = APIRouter(prefix="/ai", tags=["ai"])


@router.post("/analyze-photo", status_code=status.HTTP_200_OK)
async def analyze_photo_endpoint(file: UploadFile = File(...)):
    """
    Accept a multipart image upload, run YOLOv8m + OpenCV color detection,
    and return the result.  Nothing is saved to the database.
    Used by the Flutter app to show a preview before the user confirms.
    """
    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file is empty",
        )

    result = analyze_photo(image_bytes)
    return result


@router.post("/transcribe-voice", status_code=status.HTTP_200_OK)
async def transcribe_voice_endpoint(file: UploadFile = File(...)):
    """
    Accept an audio file upload, transcribe it locally with faster-whisper,
    and return the transcription text.  Nothing is saved to the database.
    Used by the Flutter app to preview the transcription before the user confirms.
    """
    audio_bytes = await file.read()
    if not audio_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded audio file is empty",
        )

    # Determine file extension from the upload (default to .wav)
    suffix = os.path.splitext(file.filename)[1] if file.filename else ".wav"

    # Write to a temp file, transcribe, then clean up
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        tmp.write(audio_bytes)
        tmp_path = tmp.name

    try:
        transcription = transcribe_voice(tmp_path)
    finally:
        os.remove(tmp_path)

    return {"transcription": transcription}
