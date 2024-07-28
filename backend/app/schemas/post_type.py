# app/schemas/post_type.py
from pydantic import BaseModel


class PostTypeBase(BaseModel):
    name: str


class PostTypeCreate(PostTypeBase):
    pass


class PostType(PostTypeBase):
    id: int

    class Config:
        from_attributes = True
