# /app/api/v1/endpoints/auth.py
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from backend.app.api import deps
from backend.app.core.security import create_access_token, get_password_hash, create_password_reset_token, \
    verify_password_reset_token
from backend.app.crud import crud_user
from backend.app.schemas import Token, UserCreate, PasswordResetRequest, SetNewPasswordRequest
from backend.app.services import send_reset_password_email

router = APIRouter()


@router.post("/signup", response_model=Token, status_code=201)
def signup(user: UserCreate, db: Session = Depends(deps.get_db)):
    db_user = crud_user.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    user = crud_user.create_user(db, user=user)
    access_token = create_access_token(subject=user.id)
    return {"access_token": access_token, "token_type": "bearer"}


@router.post("/login", response_model=Token, status_code=200)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(deps.get_db)):
    user = crud_user.authenticate_user(db, email=form_data.username, password=form_data.password)
    if not user:
        raise HTTPException(status_code=400, detail="Incorrect email or password")
    access_token = create_access_token(subject=user.id)
    return {"access_token": access_token, "token_type": "bearer"}


@router.post("/request-password-reset", status_code=200)
async def request_password_reset(
        request: PasswordResetRequest,
        db: Session = Depends(deps.get_db)
):
    user = crud_user.get_user_by_email(db, email=request.email)
    if not user:
        # We don't want to reveal whether a user exists or not, so we'll return the same message
        return {"message": "If an account with that email exists, we have sent a password reset link"}

    token = create_password_reset_token(email=request.email)

    try:
        await send_reset_password_email(request.email, token)
    except Exception:
        raise HTTPException(status_code=500, detail="Failed to send password reset email. Please try again later.")

    return {"message": "If an account with that email exists, we have sent a password reset link"}


@router.post("/reset-password", status_code=200)
def reset_password(request: SetNewPasswordRequest, db: Session = Depends(deps.get_db)):
    email = verify_password_reset_token(request.token)
    if not email:
        raise HTTPException(status_code=400, detail="Invalid or expired token")

    user = crud_user.get_user_by_email(db, email=email)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    hashed_password = get_password_hash(request.new_password)
    user.hashed_password = hashed_password
    db.commit()

    return {"message": "Password has been reset successfully"}
