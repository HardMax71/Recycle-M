# app/schemas/product.py
from typing import Optional

from pydantic import BaseModel

from .product_type import ProductType


class ProductBase(BaseModel):
    name: str
    description: str
    price: float
    product_type_id: int
    image_url: Optional[str] = None


class ProductCreate(ProductBase):
    pass


class ProductUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    product_type_id: Optional[int] = None
    image_url: Optional[str] = None


class Product(ProductBase):
    id: int
    seller_id: int
    product_type: Optional[ProductType] = None

    class Config:
        from_attributes = True
