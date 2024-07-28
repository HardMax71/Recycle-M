# app/crud/crud_product_type.py
from sqlalchemy.orm import Session

from backend.app.models import ProductType
from backend.app.schemas import ProductTypeCreate


def create_product_type(db: Session, product_type: ProductTypeCreate):
    db_product_type = ProductType(name=product_type.name)
    db.add(db_product_type)
    db.commit()
    db.refresh(db_product_type)
    return db_product_type


def get_product_type_by_name(db: Session, name: str):
    return db.query(ProductType).filter(ProductType.name == name).first()


def get_all_product_types(db: Session):
    return db.query(ProductType).all()
