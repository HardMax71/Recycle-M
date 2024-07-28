# app/api/v1/api.py
from fastapi import APIRouter

from backend.app.api.v1.endpoints import feed, waste_collection, users, auth, insights, products, expenses, calendar, \
    search

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(feed.router, prefix="/feed", tags=["feed"])
api_router.include_router(calendar.router, prefix="/calendar", tags=["calendar"])
api_router.include_router(expenses.router, prefix="/expenses", tags=["expenses"])
api_router.include_router(insights.router, prefix="/insights", tags=["insights"])
api_router.include_router(products.router, prefix="/products", tags=["products"])
api_router.include_router(search.router, prefix="/search", tags=["search"])
api_router.include_router(waste_collection.router, prefix="/waste-collection", tags=["waste-collection"])
