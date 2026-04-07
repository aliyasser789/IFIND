import sys
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
BACKEND_DIR = os.path.join(BASE_DIR, "backend")
sys.path.insert(0, BACKEND_DIR)

from dotenv import load_dotenv, find_dotenv

load_dotenv(find_dotenv())

from app.DB_handeling.base import Base
from app.DB_handeling.engine import engine

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers.auth import router as auth_router

app = FastAPI(title="IFind API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine)

app.include_router(auth_router)

@app.get("/ping")
def ping():
    return {"status": "ok", "message": "IFind backend is running"}

print("IFind Backend Started")