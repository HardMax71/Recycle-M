# app/api/v1/endpoints/search.py
from typing import List

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from backend.app.api import deps
from backend.app.crud import crud_search
from backend.app.schemas.search import SearchResult

router = APIRouter()


@router.get("/", response_model=List[SearchResult])
def search(
        query: str = Query(..., min_length=3),
        db: Session = Depends(deps.get_db),
        skip: int = Query(0, ge=0),
        limit: int = Query(20, ge=1, le=100)
):
    return crud_search.search(db, query, skip=skip, limit=limit)
