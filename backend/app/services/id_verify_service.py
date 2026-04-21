import os
import re
import tempfile

from app.ai_models.id_verification.utils import detect_and_process_id_card


def _clean_ocr_digits(text: str) -> str:
    if not isinstance(text, str):
        return str(text)
    return (text
        .replace('O', '0').replace('o', '0')
        .replace('I', '1').replace('l', '1')
        .replace('S', '5').replace('B', '8')
        .replace('D', '0').replace('G', '6')
    )


def verify_id_card(image_bytes: bytes) -> dict:
    """
    Accepts raw image bytes, runs the Egyptian ID card AI pipeline,
    and returns a structured result dict.

    Success: {"verified": True, "national_id": "...", "name": "...",
              "governorate": "...", "gender": "...", "birth_date": "..."}
    Failure: {"verified": False, "error": "..."}
    """
    tmp_path = None
    try:
        # Write bytes to a temp file so OpenCV / YOLO can read it
        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp:
            tmp.write(image_bytes)
            tmp_path = tmp.name

        # Returns: (first_name, second_name, merged_name, nid, address, birth_date, governorate, gender)
        first_name, second_name, merged_name, nid, address, birth_date, governorate, gender = \
            detect_and_process_id_card(tmp_path)

        # Clean OCR misreads before validation
        nid = _clean_ocr_digits(nid)

        # Validate that a proper 14-digit national ID was extracted
        if not re.fullmatch(r'\d{14}', nid):
            return {"verified": False, "error": "Could not extract a valid 14-digit national ID number"}

        return {
            "verified": True,
            "national_id": nid,
            "name": merged_name.strip(),
            "governorate": governorate,
            "gender": gender,
            "birth_date": birth_date,
        }

    except (ValueError, TypeError):
        return {"verified": False, "error": "Could not read ID clearly. Please retake the photo in good lighting and make sure the ID is flat and fully visible."}
    except Exception as e:
        return {"verified": False, "error": str(e)}

    finally:
        if tmp_path and os.path.exists(tmp_path):
            os.remove(tmp_path)
