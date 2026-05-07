from sqlalchemy import create_engine 
from sqlalchemy.orm import sessionmaker 
from .config import DATABASE_URL
 
 
engine = create_engine(DATABASE_URL) 
 
# Each session is like one conversation with the database 
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine) 
 
#function lkater used by fastapi to hand sessions to each route
def get_db(): 
    db = SessionLocal() 
    try: 
        yield db #hold until I sya so the connection
    finally: 
        db.close() 
