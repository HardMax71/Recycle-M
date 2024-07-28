# app/models/product.py
from sqlalchemy import Column, Integer, String, Float, ForeignKey
from sqlalchemy.orm import relationship

from backend.app.db.base import Base


class Product(Base):
    __tablename__ = 'products'
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(String)
    price = Column(Float)
    product_type_id = Column(Integer, ForeignKey("product_types.id"))
    image_url = Column(String, nullable=True)
    seller_id = Column(Integer, ForeignKey("users.id"))

    seller = relationship("User", back_populates="products")
    product_type = relationship("ProductType")
