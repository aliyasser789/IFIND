"""
Migration: convert found_items.photo_url from TEXT to JSONB.

Existing single-text values are wrapped into a one-element JSON array:
  "ai_models/photos/abc.jpg"  →  ["ai_models/photos/abc.jpg"]

Safe to re-run: skips if the column is already JSONB.

Run from the IFIND/ root:
    python backend/migrate_photo_url.py
"""

import os
import sys
from pathlib import Path

# ── Make sure backend/ is on the import path so config.py is found ────────────
BACKEND_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BACKEND_DIR))

from dotenv import load_dotenv
load_dotenv(dotenv_path=BACKEND_DIR / ".env")

from app.DB_handeling.config import DATABASE_URL  # noqa: E402

import psycopg2
from psycopg2 import sql


def run_migration():
    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = False
    cur = conn.cursor()

    try:
        # ── Check current column type ─────────────────────────────────────────
        cur.execute(
            """
            SELECT data_type
            FROM information_schema.columns
            WHERE table_name = 'found_items'
              AND column_name = 'photo_url'
            """
        )
        row = cur.fetchone()

        if row is None:
            print("Column 'photo_url' not found in 'found_items'. Nothing to migrate.")
            return

        current_type = row[0].lower()
        print(f"Current photo_url type: {current_type}")

        if current_type == "jsonb":
            print("photo_url is already JSONB — migration not needed.")
            return

        # ── Alter column: TEXT → JSONB, wrap existing value in an array ───────
        print("Migrating photo_url from TEXT to JSONB …")
        cur.execute(
            """
            ALTER TABLE found_items
            ALTER COLUMN photo_url TYPE JSONB
            USING CASE
                WHEN photo_url IS NULL THEN NULL
                ELSE to_jsonb(ARRAY[photo_url])
            END
            """
        )
        conn.commit()
        print("Migration complete. All existing TEXT values wrapped into JSON arrays.")

    except Exception as exc:
        conn.rollback()
        print(f"Migration FAILED — rolled back. Error: {exc}")
        raise

    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    run_migration()
