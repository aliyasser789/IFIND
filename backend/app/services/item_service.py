import uuid
from typing import List, Optional

from fastapi import HTTPException, status
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.models.lost_item import LostItem

PRESET_DISTRICTS = ["Heliopolis", "Maadi", "Nasr City", "New Cairo", "Zamalek"]

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


def binary_search(sorted_list: list[str], target: str) -> bool:
    target_lower = target.strip().lower()
    low, high = 0, len(sorted_list) - 1
    while low <= high:
        mid = (low + high) // 2
        mid_val = sorted_list[mid].lower()
        if mid_val == target_lower:
            return True
        elif mid_val < target_lower:
            low = mid + 1
        else:
            high = mid - 1
    return False


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
        if district not in PRESET_DISTRICTS:
            sorted_districts = sorted(CAIRO_DISTRICTS, key=str.lower)
            if not binary_search(sorted_districts, district):
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail=f"'{district}' is not a recognised district in Cairo, Egypt. Please enter a valid Cairo district.",
                )
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

    items = [dict(row) for row in rows]

    for item in items:
        item["classification"] = classify_item(
            category=item.get("category") or "",
            features=item.get("features") or {},
        )

    return items


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


def classify_item(category: str, features: dict) -> str:
    """
    Maps a YOLO category string (and optional feature hints) to a broader
    human-readable classification label.

    How it works:
    1. Normalise the category string to lowercase and strip whitespace so
       comparisons are case-insensitive.
    2. Check it against predefined sets with if/elif branches.
    3. If no set matches, fall back to a material-based hint from features.
    4. If nothing matches at all, return the catch-all "Other".
    """
    category_lower = (category or "").strip().lower()

    # Bags and travel items
    if category_lower in {"backpack", "handbag", "suitcase"}:
        return "Bag & Luggage"

    # Electronic devices
    if category_lower in {"cell phone", "laptop", "keyboard", "mouse", "remote"}:
        return "Electronics"

    # Small everyday personal belongings
    if category_lower in {"wallet", "book", "scissors", "pen"}:
        return "Personal Item"

    # Wearable accessories
    if category_lower in {"umbrella", "hat", "glasses"}:
        return "Accessory"

    # Material-based fallback when no category rule matched
    material = (features.get("material") or "").strip().lower()
    if material == "leather":
        return "Leather Item"

    # Nothing matched — generic fallback
    return "Other"
