"""
Items Router
GET  /items/search        — Search found items by keywords, district, category.
GET  /items/recent        — Return recently reported found items.
GET  /items/districts     — Return hardcoded list of Cairo districts.
GET  /items/categories    — Return YOLO category list.
POST /items/found/photo   — JWT required. Accepts 1–5 photos, runs YOLO on all of
                            them, stores the highest-confidence detection, and saves
                            all photo paths as JSONB.
"""

import os
import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from app.DB_handeling.engine import get_db
from app.models.found_item import FoundItem
from app.models.user import User
from app.ai_models.ai_service import analyze_photos, extract_features
from app.services.auth_service import get_current_user
from app.services.item_service import CAIRO_DISTRICTS, YOLO_CATEGORIES, get_recent_items, search_found_items

router = APIRouter(prefix="/items", tags=["items"])

# Base directory for saved photos — resolved relative to this file:
# items.py → backend/app/routers/ → parents[2] = backend/app/
# We want: backend/app/ai_models/photos/
_PHOTOS_BASE = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "..", "ai_models", "photos"
)


@router.get("/photos/{item_id}/{filename}")
def serve_photo(item_id: str, filename: str):
    """
    Serve a stored photo file publicly — no auth required.
    Flutter's Image.network() needs unauthenticated access to load images.
    """
    file_path = os.path.normpath(os.path.join(_PHOTOS_BASE, item_id, filename))
    if not os.path.isfile(file_path):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Photo not found",
        )
    return FileResponse(file_path)


@router.get("/search")
def search_items(
    keywords: str,
    district: Optional[str] = None,
    category: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> List[dict]:
    return search_found_items(db=db, keywords=keywords, user_id=current_user.id, district=district, category=category)


@router.get("/recent")
def recent_items(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> List[dict]:
    return get_recent_items(db)


@router.get("/districts")
def list_districts(
    current_user: User = Depends(get_current_user),
) -> List[str]:
    return CAIRO_DISTRICTS


@router.get("/categories")
def list_categories(
    current_user: User = Depends(get_current_user),
) -> List[str]:
    return YOLO_CATEGORIES


@router.post("/found/photo", status_code=status.HTTP_201_CREATED)
async def report_found_item_photo(
    photos: List[UploadFile] = File(...),   # 1–5 image files
    district: str = Form(...),              # chosen from the district dropdown
    description: str = Form(""),            # typed or voice-transcribed text
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Accept 1–5 photos for a found item.

    Steps:
      1. Validate photo count (1–5).
      2. Generate a UUID for the item upfront.
      3. Create subfolder: ai_models/photos/{item_uuid}/
      4. Save each photo as photo_1.jpg, photo_2.jpg, etc.
      5. Run YOLO on all images → pick highest-confidence detection.
      6. Persist item with photo_url as a JSONB list of paths.
    """
    # ── Validate count ────────────────────────────────────────────────────────
    if len(photos) < 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="At least 1 photo is required.",
        )
    if len(photos) > 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Maximum 5 photos allowed per found item.",
        )

    # ── Generate item UUID & create subfolder ─────────────────────────────────
    item_uuid = uuid.uuid4()
    item_folder = os.path.join(_PHOTOS_BASE, str(item_uuid))
    os.makedirs(item_folder, exist_ok=True)

    # ── Read all photos, save to disk ─────────────────────────────────────────
    saved_paths = []
    images_bytes_list = []

    for idx, upload in enumerate(photos, start=1):
        image_bytes = await upload.read()
        if not image_bytes:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Photo {idx} is empty.",
            )

        filename = f"photo_{idx}.jpg"
        file_path = os.path.join(item_folder, filename)

        with open(file_path, "wb") as f:
            f.write(image_bytes)

        # Store a normalised relative path for portability
        saved_paths.append(f"ai_models/photos/{item_uuid}/{filename}")
        images_bytes_list.append(image_bytes)

    # ── Run YOLO on all images, pick best result ──────────────────────────────
    ai_result = analyze_photos(images_bytes_list)
    category = ai_result["category"]

    # ── Persist to database ───────────────────────────────────────────────────
    item = FoundItem(
        id=item_uuid,
        user_id=current_user.id,
        photo_url=saved_paths,          # JSONB list of paths
        category=category,
        features=extract_features(description, category),
        district=district,
    )
    db.add(item)
    db.commit()
    db.refresh(item)

    return {
        "id": str(item.id),
        "user_id": str(item.user_id),
        "photo_url": item.photo_url,
        "category": item.category,
        "features": item.features,
        "district": item.district,
        "created_at": item.created_at.isoformat(),
    }
