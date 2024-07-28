# app/models/post_type.py
from sqlalchemy import Column, Integer, String

from backend.app.db.base import Base


class PostType(Base):
    __tablename__ = "post_types"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
