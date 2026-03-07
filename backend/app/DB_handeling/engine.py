from sqlalchemy import create_engine 
from sqlalchemy.orm import sessionmaker 
from .config import DATABASE_URL
 
# Create the engine - this is the actual connection to PostgreSQL 
engine = create_engine(DATABASE_URL) 
 
# Each session is like one conversation with the database 
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine) 
 
# Dependency - used in FastAPI routes to get a database session 
def get_db(): 
    db = SessionLocal() 
    try: 
        yield db 
    finally: 
        db.close() 
