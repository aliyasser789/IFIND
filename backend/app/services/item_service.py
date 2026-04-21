import uuid
from typing import List, Optional

from sqlalchemy import or_, text
from sqlalchemy.orm import Session

from app.models.lost_item import LostItem

CAIRO_DISTRICTS = [
    "Tagamoa", "Maadi", "Zamalek", "Heliopolis", "Nasr City",
    "New Cairo", "Dokki", "Mohandessin", "Downtown Cairo",
    "Ain Shams", "Shubra", "October City", "Sheikh Zayed",
]

YOLO_CATEGORIES = [
    "bicycle", "car", "motorcycle", "bus",
    "backpack", "umbrella", "handbag", "suitcase",
    "frisbee", "skis", "snowboard", "sports ball", "kite",
    "baseball bat", "baseball glove", "skateboard", "surfboard", "tennis racket",
    "bottle", "wine glass", "cup", "bowl",
    "fork", "knife", "spoon",
    "chair", "couch", "potted plant", "tv",
    "laptop", "mouse", "remote", "keyboard", "cell phone",
    "microwave", "toaster",
    "book", "clock", "vase", "scissors",
    "teddy bear", "hair drier",
    "cat", "dog",
    "tie",
    "Other"
]


def search_found_items(
    db: Session,
    keywords: str,
    user_id: uuid.UUID,
    district: Optional[str] = None,
    category: Optional[str] = None,
) -> List[dict]:
    keyword = keywords.strip()

    sql_filters = """
        category ILIKE :kw
        OR features->>'color' ILIKE :kw
        OR features->>'brand' ILIKE :kw
        OR features->>'material' ILIKE :kw
        OR features->>'description' ILIKE :kw
        OR features->>'distinguishing_feature' ILIKE :kw
    """

    extra_filters = " AND user_id != :user_id"
    params: dict = {"kw": f"%{keyword}%", "user_id": str(user_id)}

    if district:
        extra_filters += " AND district ILIKE :district"
        params["district"] = f"%{district}%"

    if category:
        extra_filters += " AND category ILIKE :category"
        params["category"] = f"%{category}%"

    query_text = f"""
        SELECT *
        FROM found_items
        WHERE ({sql_filters})
        {extra_filters}
        ORDER BY created_at DESC
    """
    result = db.execute(text(query_text), params)

    rows = result.mappings().all()

    log_entry = LostItem(
        user_id=user_id,
        keywords=keyword,
        district=district,
    )
    db.add(log_entry)
    db.commit()

    return [dict(row) for row in rows]


def get_recent_items(db: Session, user_id: uuid.UUID) -> List[dict]:
    district_list = ", ".join(f"'{d}'" for d in CAIRO_DISTRICTS)
    query_text = f"""
        SELECT *
        FROM found_items
        WHERE district IN ({district_list})
          AND user_id != :user_id
        ORDER BY created_at DESC
        LIMIT 20
    """
    result = db.execute(text(query_text), {"user_id": str(user_id)})
    return [dict(row) for row in result.mappings().all()]
