# app/schemas/expense.py
from datetime import datetime

from pydantic import BaseModel


class ExpenseBase(BaseModel):
    description: str
    points: int


class ExpenseCreate(ExpenseBase):
    pass


class ExpenseUpdate(ExpenseBase):
    description: str
    points: int
    created_at: datetime

    class Config:
        from_attributes = True


class Expense(ExpenseBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True
