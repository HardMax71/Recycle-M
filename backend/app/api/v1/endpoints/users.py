# app/api/v1/endpoints/users.py
from http.client import HTTPException
from typing import List, Dict

from fastapi import APIRouter, Depends, UploadFile, File, Body
from sqlalchemy.orm import Session

from backend.app.api import deps
from backend.app.crud import crud_user
from backend.app.schemas import User, UserPhoto, UserBalance, Reward, RewardCreate, UserUpdate

router = APIRouter()


@router.get("/me", response_model=User)
def read_user_me(current_user: User = Depends(deps.get_current_user)):
    return current_user


@router.patch("/me", response_model=User)
async def update_user_profile(
        *,
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_active_user),
        user_update: UserUpdate = Body(...)
):
    updated_user = await crud_user.update_user_profile(db, current_user.id, user_update)
    if updated_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return updated_user


@router.get("/me/photos", response_model=List[UserPhoto])
async def get_user_photos(
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_user),
        skip: int = 0,
        limit: int = 30
):
    return await crud_user.get_user_photos(db, user_id=current_user.id, skip=skip, limit=limit)


@router.patch("/me/profile-photo", response_model=User)
async def update_profile_photo(
        *,
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_active_user),
        profile_photo: UploadFile = File(...)
):
    updated_user = await crud_user.update_user_profile_photo(db, current_user.id, profile_photo)
    if updated_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return updated_user


@router.post("/me/photos", response_model=UserPhoto, status_code=201)
async def upload_photo(
        file: UploadFile = File(...),
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_user)
):
    return await crud_user.upload_user_photo(db, user_id=current_user.id, file=file)


@router.get("/options", response_model=dict)
def get_user_options(
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_user)
):
    return crud_user.get_user_options(db, user_id=current_user.id)


@router.put("/options", response_model=dict)
def update_user_options(
        options: dict,
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_user)
):
    return crud_user.update_user_options(db, user_id=current_user.id, options=options)


@router.get("/balance", response_model=UserBalance)
async def get_user_balance(current_user: User = Depends(deps.get_current_user),
                           db: Session = Depends(deps.get_db)):
    rewards, total_rewards = crud_user.get_user_rewards(db, user_id=current_user.id, limit=5)
    expenses, total_expenses = crud_user.get_user_expenses(db, user_id=current_user.id, limit=5)
    balance = total_rewards - total_expenses
    return {"balance": balance, "rewards": rewards, "expenses": expenses}


@router.post("/rewards", response_model=Reward)
async def add_user_reward(reward: RewardCreate, current_user: User = Depends(deps.get_current_user),
                          db: Session = Depends(deps.get_db)):
    return crud_user.create_user_reward(db, reward=reward, user_id=current_user.id)


@router.get("/weekly-data", response_model=List[Dict])
async def get_weekly_data(
        current_user: User = Depends(deps.get_current_user),
        db: Session = Depends(deps.get_db)
):
    return crud_user.get_weekly_data(db, user_id=current_user.id)


@router.get("/monthly-transactions/{year}/{month}", response_model=List[Dict])
async def get_monthly_transactions(
        year: int,
        month: int,
        current_user: User = Depends(deps.get_current_user),
        db: Session = Depends(deps.get_db)
):
    return crud_user.get_monthly_transactions(db, user_id=current_user.id, year=year, month=month)
