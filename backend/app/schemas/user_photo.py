# app/schemas/user_photo.py
from pydantic import BaseModel


class UserPhotoBase(BaseModel):
    url: str


class UserPhotoCreate(UserPhotoBase):
    pass


class UserPhoto(BaseModel):
    id: int
    url: str
    user_id: int

    class Config:
        from_attributes = True
