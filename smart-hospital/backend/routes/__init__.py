from routes.auth import router as auth_router
from routes.capacity import router as capacity_router
from routes.search import router as search_router
from routes.requests import router as requests_router
from routes.analytics import router as analytics_router
from routes.admin import router as admin_router

__all__ = [
    "auth_router",
    "capacity_router",
    "search_router",
    "requests_router",
    "analytics_router",
    "admin_router",
]
