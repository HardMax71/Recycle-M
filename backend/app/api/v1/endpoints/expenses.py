# app/api/v1/endpoints/expenses.py
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session

from backend.app.api import deps
from backend.app.crud import crud_expense
from backend.app.schemas import Expense, ExpenseCreate, ExpenseUpdate, User

router = APIRouter()


@router.get("/", response_model=list[Expense])
def read_expenses(
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_user),
        skip: int = 0,
        limit: int = 100
):
    expenses = crud_expense.get_user_expenses(db, user_id=current_user.id, skip=skip, limit=limit)
    return expenses


@router.post("/", response_model=Expense, status_code=201)
def create_expense(
        expense: ExpenseCreate,
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_user)
):
    return crud_expense.create_expense(db, expense=expense, user_id=current_user.id)


@router.put("/{expense_id}", response_model=Expense)
def update_expense(
        expense_id: int,
        expense_update: ExpenseUpdate,
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_user)
):
    current_expense = crud_expense.get_expense(db, expense_id=expense_id)
    if not current_expense:
        raise HTTPException(status_code=404, detail="Expense not found")
    if current_expense.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this expense")
    updated_expense = crud_expense.update_expense(db, db_obj=current_expense, obj_in=expense_update)
    return updated_expense


@router.get("/statistics")
def get_expense_statistics(
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_user),
        period: str = Query(..., enum=["month", "year"])
):
    return crud_expense.get_expense_statistics(db, user_id=current_user.id, period=period)
