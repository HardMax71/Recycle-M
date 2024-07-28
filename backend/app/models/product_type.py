# app/models/product_type.py
from sqlalchemy import Column, Integer, String

from backend.app.db.base import Base


class ProductType(Base):
    __tablename__ = "product_types"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
