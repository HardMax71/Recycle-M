# /app/schemas/reward.py
from datetime import datetime

from pydantic import BaseModel


class RewardBase(BaseModel):
    points: int


class RewardCreate(RewardBase):
    waste_type_id: int


class Reward(RewardBase):
    id: int
    user_id: int
    waste_type: str
    created_at: datetime

    class Config:
        from_attributes = True
