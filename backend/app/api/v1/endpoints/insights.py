# app/api/v1/endpoints/insights.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from backend.app.api import deps
from backend.app.crud import crud_insights
from backend.app.schemas import UserInsights, User

router = APIRouter()


@router.get("/", response_model=UserInsights)
def get_user_insights(
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_user)
):
    try:
        return crud_insights.get_user_insights(db, user_id=current_user.id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
