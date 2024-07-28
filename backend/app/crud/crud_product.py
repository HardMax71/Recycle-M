from fastapi import HTTPException
from sqlalchemy import or_
from sqlalchemy.orm import Session, joinedload

from backend.app.models import Product
from backend.app.schemas import ProductCreate, ProductUpdate


def get_products(db: Session, skip: int = 0, limit: int = 100, search: str = None, product_type_id: int = None):
    query = db.query(Product).options(joinedload(Product.product_type))
    if search:
        query = query.filter(
            or_(
                Product.name.ilike(f"%{search}%"),
                Product.description.ilike(f"%{search}%")
            )
        )
    if product_type_id:
        query = query.filter(Product.product_type_id == product_type_id)
    return query.offset(skip).limit(limit).all()


def create_product(db: Session, product: ProductCreate, user_id: int):
    if product.product_type_id is None:
        raise HTTPException(status_code=400, detail="product_type_id is required")
    db_product = Product(**product.dict(), seller_id=user_id)
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    return db_product


def get_product(db: Session, product_id: int):
    return db.query(Product).filter(Product.id == product_id).first()


def update_product(db: Session, db_obj: Product, obj_in: ProductUpdate):
    update_data = obj_in.dict(exclude_unset=True)
    if "product_type_id" in update_data and update_data["product_type_id"] is None:
        raise HTTPException(status_code=400, detail="product_type_id cannot be null")
    for field, value in update_data.items():
        setattr(db_obj, field, value)
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def remove_product(db: Session, id: int):
    product = db.query(Product).get(id)
    db.delete(product)
    db.commit()
    return product
