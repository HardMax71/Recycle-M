# app/schemas/common.py
from typing import List

from pydantic import BaseModel

from .expense import Expense
from .reward import Reward


class UserBalance(BaseModel):
    balance: int
    rewards: List[Reward]
    expenses: List[Expense]
