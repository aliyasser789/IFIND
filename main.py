import sys
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
BACKEND_DIR = os.path.join(BASE_DIR, "backend")
sys.path.insert(0, BACKEND_DIR)




# Explicitly load .env from backend/ so JWT_SECRET and email vars are available
from dotenv import load_dotenv
from pathlib import Path

load_dotenv(dotenv_path=Path(BACKEND_DIR) / ".env")

from app.DB_handeling.base import Base
from app.DB_handeling.engine import engine

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers.auth import router as auth_router, user_router
from app.routers.ai import router as ai_router
from app.routers.items import router as items_router
from app.routers.chat import router as chat_router
from app.routers.reports import router as reports_router

# Import models so SQLAlchemy registers them before create_all is called
import app.models.found_item  # noqa: F401
import app.models.report  # noqa: F401

app = FastAPI(title="IFind API")

from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request, exc):
    print(f"422 DETAIL: {exc.errors()}")
    return JSONResponse(status_code=422, content={"detail": exc.errors()})

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine)

app.include_router(auth_router)
app.include_router(user_router)
app.include_router(ai_router)
app.include_router(items_router)
app.include_router(chat_router)
app.include_router(reports_router)

@app.get("/ping")
def ping():
    return {"status": "ok", "message": "IFind backend is running"}

print("IFind Backend Started")