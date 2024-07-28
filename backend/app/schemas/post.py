from datetime import datetime
from typing import Optional, List

from pydantic import BaseModel

from .post_type import PostType
from .user import User


class PostImageBase(BaseModel):
    url: str


class PostImageCreate(PostImageBase):
    pass


class PostImage(PostImageBase):
    id: int
    post_id: int

    class Config:
        from_attributes = True


class PostBase(BaseModel):
    title: str
    content: str
    post_type_id: Optional[int] = None


class PostCreate(PostBase):
    images: Optional[List[PostImageCreate]] = []


class PostUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    post_type_id: Optional[int] = None
    images: Optional[List[PostImageCreate]] = []


class Post(PostBase):
    id: int
    created_at: datetime
    author_id: int
    author: Optional[User] = None
    post_type: Optional[PostType] = None
    images: List[PostImage] = []

    class Config:
        from_attributes = True
