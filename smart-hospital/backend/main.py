import os
import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import ping_db
from routes import (
    auth_router,
    capacity_router,
    search_router,
    requests_router,
    analytics_router,
    admin_router,
)
from services.referral import start_expiry_background_task

expiry_task = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global expiry_task
    # Ping MongoDB on startup & create indexes
    await ping_db()
    # Start background reservation expiry task (runs every 30s)
    expiry_task = asyncio.create_task(start_expiry_background_task(30))
    yield
    # Shutdown background task
    if expiry_task:
        expiry_task.cancel()

app = FastAPI(
    title="Smart Hospital API",
    lifespan=lifespan
)

# Configurable CORS via ALLOWED_ORIGINS environment variable (default "*")
allowed_origins_env = os.getenv("ALLOWED_ORIGINS", "*")
allowed_origins = [o.strip() for o in allowed_origins_env.split(",") if o.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth_router)
app.include_router(capacity_router)
app.include_router(search_router)
app.include_router(requests_router)
app.include_router(analytics_router)
app.include_router(admin_router)

@app.get("/health")
async def health_check():
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
