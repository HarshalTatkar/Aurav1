"""
AURA Backend — FastAPI Application
AI-Powered Personal Health Companion API Server
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from database import engine, Base
from auth import router as auth_router
from routes import router as api_router
from websocket_hub import router as ws_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: create tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    # Shutdown
    await engine.dispose()

app = FastAPI(
    title="AURA API",
    description="AI-Powered Personal Health Companion Backend",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routes
app.include_router(auth_router, prefix="/auth", tags=["Authentication"])
app.include_router(api_router, tags=["API"])
app.include_router(ws_router, tags=["WebSocket"])

@app.get("/")
async def root():
    return {"service": "AURA API", "version": "1.0.0", "status": "running"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
