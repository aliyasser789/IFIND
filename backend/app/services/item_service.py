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

    # Convert rows to plain dicts as before
    items = [dict(row) for row in rows]

    # --- Algorithm demonstrations (do not affect existing logic) ---

    # 1. Linear Search — run our own search algorithm on the SQL results
    # This demonstrates linear search working on real database data
    linear_search_results = linear_search(items, keyword)

    # 2. Bubble Sort — run our own sort algorithm on the linear search results
    # Sorts by created_at newest first, same order as SQL ORDER BY created_at DESC
    sorted_results = sort_by_date(linear_search_results, ascending=False)

    # 3. Classification — add a broader classification label to each item
    # classify_item uses the YOLO category and features dict to assign a group
    for item in sorted_results:
        item["classification"] = classify_item(
            category=item.get("category") or "",
            features=item.get("features") or {},
        )

    return sorted_results


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


def linear_search(items: list[dict], keyword: str) -> list[dict]:
    """
    Searches a list of found-item dicts for a keyword.

    How it works:
    1. Normalise the keyword to lowercase once, before the loop.
    2. Iterate every item in the list one by one.
    3. For each item, pull the flat field 'category' and the nested fields
       inside 'features' (color, brand, material, description,
       distinguishing_feature).
    4. Check whether the lowercase keyword appears anywhere inside each
       field value (substring match).
    5. If any field matches, add the item to the results list and move on
       to the next item (no need to keep checking the remaining fields).
    6. Return the collected results list.
    """
    keyword_lower = keyword.lower()
    results = []

    for item in items:
        # Flat field to search
        category = item.get("category") or ""

        # Nested feature fields (features may be None or missing)
        features = item.get("features") or {}
        color = features.get("color") or ""
        brand = features.get("brand") or ""
        material = features.get("material") or ""
        description = features.get("description") or ""
        distinguishing_feature = features.get("distinguishing_feature") or ""

        # Check each field for a case-insensitive substring match
        if (
            keyword_lower in category.lower()
            or keyword_lower in color.lower()
            or keyword_lower in brand.lower()
            or keyword_lower in material.lower()
            or keyword_lower in description.lower()
            or keyword_lower in distinguishing_feature.lower()
        ):
            results.append(item)

    return results


def sort_by_date(items: list[dict], ascending: bool = False) -> list[dict]:
    """
    Sorts a list of found-item dicts by their 'created_at' field using
    bubble sort — no built-in sort() or sorted() is used.

    How bubble sort works:
    1. Make a shallow copy of the input list so the original is not mutated.
    2. Outer loop: repeat (n - 1) times, where n is the number of items.
       Each full pass 'bubbles' the extreme value to its final position.
    3. Inner loop: walk through adjacent pairs (index i and i+1).
    4. Compare the two 'created_at' strings.
       - ISO-8601 date strings sort correctly as plain strings because the
         format is year-month-day hour:minute:second, left to right.
       - For ascending=True  → swap when left > right  (push larger values right)
       - For ascending=False → swap when left < right  (push smaller values right,
         i.e. newest ends up at the front)
    5. After all passes the list is sorted; return it.
    """
    result = list(items)  # shallow copy — do not mutate the caller's list
    n = len(result)

    for pass_index in range(n - 1):
        # After each pass the last (pass_index + 1) elements are already sorted
        for i in range(n - 1 - pass_index):
            left_date = result[i].get("created_at") or ""
            right_date = result[i + 1].get("created_at") or ""

            if ascending:
                # Oldest first: swap when left is newer than right
                should_swap = left_date > right_date
            else:
                # Newest first (default): swap when left is older than right
                should_swap = left_date < right_date

            if should_swap:
                result[i], result[i + 1] = result[i + 1], result[i]

    return result


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
