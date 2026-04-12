from typing import List, Optional

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.DB_handeling.engine import get_db
from app.models.user import User
from app.services.auth_service import get_current_user
from app.services.item_service import CAIRO_DISTRICTS, YOLO_CATEGORIES, get_recent_items, search_found_items

router = APIRouter(prefix="/items", tags=["items"])


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
