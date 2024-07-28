# app/crud/crud_insights.py

from typing import List

from sqlalchemy.orm import Session

from backend.app.models import User, Expense
from backend.app.schemas import UserInsights, ExpenseInsight


def get_user_insights(db: Session, user_id: int) -> UserInsights:
    user = db.query(User).filter(User.id == user_id).first()

    if not user:
        raise ValueError("User not found")

    # Get the user's balance
    balance = user.balance

    # Get the user's expenses
    expenses = db.query(Expense).filter(Expense.user_id == user_id).order_by(Expense.created_at.desc()).limit(5).all()

    expense_insights: List[ExpenseInsight] = []
    for expense in expenses:
        statistic = f"{expense.amount:.2f} pts"
        expense_insights.append(ExpenseInsight(
            item=expense.description,
            statistic=statistic
        ))

    return UserInsights(
        balance=balance,
        expenses=expense_insights
    )
