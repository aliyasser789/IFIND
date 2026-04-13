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
    "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train",
    "truck", "boat", "bench", "bird", "cat", "dog", "horse", "sheep", "cow",
    "elephant", "bear", "zebra", "giraffe", "backpack", "umbrella", "handbag",
    "tie", "suitcase", "frisbee", "skis", "snowboard", "sports ball", "kite",
    "baseball bat", "baseball glove", "skateboard", "surfboard", "tennis racket",
    "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl", "banana",
    "apple", "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza",
    "donut", "cake", "chair", "couch", "potted plant", "bed", "dining table",
    "toilet", "tv", "laptop", "mouse", "remote", "keyboard", "cell phone",
    "microwave", "oven", "toaster", "sink", "refrigerator", "book", "clock",
    "vase", "scissors", "teddy bear", "hair drier", "toothbrush"
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

    extra_filters = ""
    params: dict = {"kw": f"%{keyword}%"}

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


def get_recent_items(db: Session) -> List[dict]:
    district_list = ", ".join(f"'{d}'" for d in CAIRO_DISTRICTS)
    query_text = f"""
        SELECT *
        FROM found_items
        WHERE district IN ({district_list})
        ORDER BY created_at DESC
        LIMIT 20
    """
    result = db.execute(text(query_text))
    return [dict(row) for row in result.mappings().all()]
