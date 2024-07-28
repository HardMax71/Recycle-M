from typing import Optional

from pydantic import BaseModel, EmailStr, Field


class UserBase(BaseModel):
    email: EmailStr
    full_name: str


class UserCreate(UserBase):
    password: str
    bio: Optional[str] = "No bio :("


class UserUpdate(BaseModel):
    bio: Optional[str] = None


class UserPhotoUpdate(BaseModel):
    profile_image: Optional[str] = None


class User(UserBase):
    id: int
    bio: str = "No bio :("
    is_active: bool = True
    balance: float = Field(default=0.0, ge=0)
    opt_out_newspaper: bool = False
    profile_image: Optional[str] = None

    class Config:
        from_attributes = True


class UserInDB(User):
    hashed_password: str


class UserPhotoSchema(BaseModel):
    url: str
    user_id: int

    class Config:
        from_attributes = True
