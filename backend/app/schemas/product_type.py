# app/schemas/product_type.py
from pydantic import BaseModel


class ProductTypeBase(BaseModel):
    name: str


class ProductTypeCreate(ProductTypeBase):
    pass


class ProductType(ProductTypeBase):
    id: int

    class Config:
        from_attributes = True
