from typing import List, Tuple, Dict

import requests
from fastapi import UploadFile, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from backend.app.core.config import settings
from backend.app.core.security import get_password_hash, verify_password
from backend.app.models import User, UserPhoto, Reward, Expense
from backend.app.schemas import UserCreate, UserUpdate, UserPhotoCreate, RewardCreate, ExpenseCreate


def get_user(db: Session, user_id: int):
    return db.query(User).filter(User.id == user_id).first()


def get_user_by_email(db: Session, email: str):
    return db.query(User).filter(User.email == email).first()


def create_user(db: Session, user: UserCreate):
    db_user = User(email=user.email, hashed_password=get_password_hash(user.password), full_name=user.full_name)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


def update_user(db: Session, db_obj: User, obj_in: UserUpdate):
    update_data = obj_in.dict(exclude_unset=True)
    if "password" in update_data:
        update_data["hashed_password"] = get_password_hash(update_data["password"])
        del update_data["password"]
    for field, value in update_data.items():
        setattr(db_obj, field, value)
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def authenticate_user(db: Session, email: str, password: str):
    user = get_user_by_email(db, email)
    if not user or not verify_password(password, user.hashed_password):
        return None
    return user


def is_active(user: User) -> bool:
    return user.is_active


async def get_user_photos(db: Session, user_id: int, skip: int = 0, limit: int = 30) -> List[UserPhoto]:
    return db.query(UserPhoto).filter(UserPhoto.user_id == user_id).offset(skip).limit(limit).all()


def upload_to_imgur(file: UploadFile):
    headers = {'Authorization': f'Client-ID {settings.IMGUR_CLIENT_ID}'}
    response = requests.post(
        url="https://api.imgur.com/3/upload",
        headers=headers,
        files={'image': file.file.read()}
    )
    if response.status_code == 200:
        json_response = response.json()
        return json_response['data']['link']
    else:
        raise HTTPException(status_code=response.status_code, detail="Failed to upload image to Imgur")


async def upload_user_photo(db: Session, user_id: int, file: UploadFile):
    file_url = upload_to_imgur(file)
    photo_create = UserPhotoCreate(url=file_url)
    db_photo = UserPhoto(**photo_create.dict(), user_id=user_id)
    db.add(db_photo)
    db.commit()
    db.refresh(db_photo)
    return db_photo


async def create_user_photo(db: Session, user_id: int, photo_url: str):
    photo_create = UserPhotoCreate(url=photo_url)
    db_photo = UserPhoto(**photo_create.dict(), user_id=user_id)
    db.add(db_photo)
    db.commit()
    db.refresh(db_photo)
    return db_photo


def get_user_options(db: Session, user_id: int):
    user = get_user(db, user_id)
    if not user:
        return None
    return {
        "receive_notifications": user.receive_notifications,
        "receive_newsletter": user.receive_newsletter,
        "receive_product_updates": user.receive_product_updates,
        "receive_feedback_requests": user.receive_feedback_requests,
        "appear_in_search_results": user.appear_in_search_results,
        "allow_data_collection": user.allow_data_collection,
    }


def update_user_options(db: Session, user_id: int, options: dict):
    user = get_user(db, user_id)
    if not user:
        return None
    for key, value in options.items():
        setattr(user, key, value)
    db.add(user)
    db.commit()
    db.refresh(user)
    return get_user_options(db, user_id)


def create_user_reward(db: Session, reward: RewardCreate, user_id: int) -> Reward:
    db_reward = Reward(**reward.dict(), user_id=user_id)
    db.add(db_reward)
    db.commit()
    db.refresh(db_reward)

    # Update user balance
    user = db.query(User).filter(User.id == user_id).first()
    user.balance += reward.points
    db.commit()

    return db_reward


async def update_user_profile(db: Session, user_id: int, user_update: UserUpdate):
    user = get_user(db, user_id)
    if not user:
        return None

    if user_update.bio is not None:
        user.bio = user_update.bio

    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def get_user_rewards(db: Session, user_id: int, limit: int = 10) -> Tuple[List[Reward], int]:
    rewards = db.query(Reward).options(joinedload(Reward.waste_type)).filter(Reward.user_id == user_id).order_by(
        Reward.created_at.desc()).limit(limit).all()
    total_rewards = db.query(func.sum(Reward.points)).filter(Reward.user_id == user_id).scalar() or 0
    rewards_with_waste_type = [
        Reward(
            id=reward.id,
            user_id=reward.user_id,
            points=reward.points,
            waste_type=reward.waste_type.name if reward.waste_type else "Unknown",
            created_at=reward.created_at
        ) for reward in rewards
    ]
    return rewards_with_waste_type, total_rewards


def get_user_expenses(db: Session, user_id: int, limit: int = 10) -> Tuple[List[Expense], float]:
    expenses = db.query(Expense).filter(Expense.user_id == user_id).order_by(
        Expense.created_at.desc()).limit(limit).all()
    total_expenses = db.query(func.sum(Expense.points)).filter(Expense.user_id == user_id).scalar() or 0.0
    return expenses, total_expenses


def create_user_expense(db: Session, expense: ExpenseCreate, user_id: int):
    db_expense = Expense(**expense.dict(), user_id=user_id)
    db.add(db_expense)
    db.commit()
    db.refresh(db_expense)

    # Update user balance
    user = db.query(User).filter(User.id == user_id).first()
    user.balance -= expense.points
    db.commit()

    return db_expense


async def update_user_profile_photo(db: Session, user_id: int, profile_photo: UploadFile):
    user = get_user(db, user_id)
    if not user:
        return None

    photo_url = upload_to_imgur(profile_photo)
    user.profile_image = photo_url

    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def get_weekly_data(db: Session, user_id: int) -> List[Dict]:
    from datetime import datetime, timedelta

    today = datetime.today()
    week_ago = today - timedelta(days=7)

    rewards = db.query(
        func.date(Reward.created_at).label('date'),
        func.sum(Reward.points).label('points')
    ).filter(
        Reward.user_id == user_id,
        Reward.created_at >= week_ago
    ).group_by(func.date(Reward.created_at)).all()

    expenses = db.query(
        func.date(Expense.created_at).label('date'),
        func.sum(Expense.points).label('points')
    ).filter(
        Expense.user_id == user_id,
        Expense.created_at >= week_ago
    ).group_by(func.date(Expense.created_at)).all()

    def process_data(data):
        processed = {}
        for entry in data:
            processed[entry.date] = entry.points
        return processed

    rewards_data = process_data(rewards)
    expenses_data = process_data(expenses)

    weekly_data = []
    for i in range(7):
        date = (week_ago + timedelta(days=i)).strftime('%Y-%m-%d')
        weekly_data.append({
            "date": date,
            "rewards": rewards_data.get(date, 0),
            "expenses": expenses_data.get(date, 0)
        })

    return weekly_data


def get_monthly_transactions(db: Session, user_id: int, year: int, month: int) -> List[Dict]:
    rewards = db.query(Reward).options(joinedload(Reward.waste_type)).filter(
        Reward.user_id == user_id,
        func.strftime('%Y', Reward.created_at) == str(year),
        func.strftime('%m', Reward.created_at) == f'{month:02d}'
    ).all()

    expenses = db.query(Expense).filter(
        Expense.user_id == user_id,
        func.strftime('%Y', Expense.created_at) == str(year),
        func.strftime('%m', Expense.created_at) == f'{month:02d}'
    ).all()

    transactions = [  # noqa: E126
                       {  # noqa: E126
                           "type": "reward",
                           "description": reward.waste_type.name,
                           "points": reward.points,
                           "created_at": reward.created_at
                       }
                       for reward in rewards
                   ] + [  # noqa: E126
                       {  # noqa: E126
                           "type": "expense",
                           "description": expense.description,
                           "points": expense.points,
                           "created_at": expense.created_at
                       }
                       for expense in expenses
                   ]  # noqa: E126

    transactions.sort(key=lambda x: x["created_at"], reverse=True)

    return transactions
