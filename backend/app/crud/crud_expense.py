from datetime import datetime, timedelta

from sqlalchemy import func
from sqlalchemy.orm import Session

from backend.app.models import Expense
from backend.app.schemas import ExpenseCreate, ExpenseUpdate


def get_user_expenses(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return db.query(Expense).filter(Expense.user_id == user_id).offset(skip).limit(limit).all()


def create_expense(db: Session, expense: ExpenseCreate, user_id: int):
    db_expense = Expense(**expense.dict(), user_id=user_id)
    db.add(db_expense)
    db.commit()
    db.refresh(db_expense)
    return db_expense


def get_expense_statistics(db: Session, user_id: int, period: str):
    if period == "month":
        start_date = datetime.utcnow() - timedelta(days=30)
    elif period == "year":
        start_date = datetime.utcnow() - timedelta(days=365)
    else:
        raise ValueError("Invalid period. Choose 'month' or 'year'.")

    result = db.query(
        func.sum(Expense.points).label("total"),
        func.avg(Expense.points).label("average")
    ).filter(
        Expense.user_id == user_id,
        Expense.created_at >= start_date
    ).first()

    return {
        "total": result.total or 0,
        "average": result.average or 0
    }


def get_user_expense_summary(db: Session, user_id: int):
    result = db.query(
        func.sum(Expense.points).label("total"),
        func.avg(Expense.points).label("average")
    ).filter(Expense.user_id == user_id).first()

    return {
        "total": result.total or 0,
        "average": result.average or 0
    }


def get_expense(db: Session, expense_id: int):
    return db.query(Expense).filter(Expense.id == expense_id).first()


def update_expense(db: Session, db_obj: Expense, obj_in: ExpenseUpdate):
    update_data = obj_in.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_obj, field, value)
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj
