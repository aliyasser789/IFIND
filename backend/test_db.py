from sqlalchemy import text

from database import engine


def test_connection() -> None:
    with engine.connect() as connection:
        connection.execute(text("SELECT 1"))
    print("DB CONNECTED SUCCESSFULLY")


if __name__ == "__main__":
    test_connection()
