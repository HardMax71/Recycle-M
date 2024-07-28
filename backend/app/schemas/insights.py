# app/schemas/insights.py

from typing import List

from pydantic import BaseModel


class ExpenseInsight(BaseModel):
    item: str
    statistic: str


class UserInsights(BaseModel):
    balance: float
    expenses: List[ExpenseInsight]

    class Config:
        from_attributes = True
