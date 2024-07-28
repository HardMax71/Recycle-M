# app/models/post.py
from datetime import datetime

from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship

from backend.app.db.base import Base


class Post(Base):
    __tablename__ = "posts"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    content = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    author_id = Column(Integer, ForeignKey("users.id"))
    post_type_id = Column(Integer, ForeignKey("post_types.id"))

    author = relationship("User", back_populates="posts")

    post_type = relationship("PostType")
    images = relationship("PostImage", back_populates="post")


class PostImage(Base):
    __tablename__ = "post_images"
    id = Column(Integer, primary_key=True, index=True)
    url = Column(String)
    post_id = Column(Integer, ForeignKey("posts.id"))

    post = relationship("Post", back_populates="images")
