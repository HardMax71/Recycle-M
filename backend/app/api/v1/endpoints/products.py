# app/api/v1/endpoints/products.py
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session

from backend.app.api import deps
from backend.app.crud import crud_product
from backend.app.schemas import Product, ProductCreate, ProductUpdate, User

router = APIRouter()


@router.get("/", response_model=list[Product])
def read_products(
        db: Session = Depends(deps.get_db),
        skip: int = 0,
        limit: int = 100,
        search: str = Query(None, min_length=0, max_length=50),
        product_type_id: int = Query(None)
):
    products = crud_product.get_products(db, skip=skip, limit=limit, search=search, product_type_id=product_type_id)
    return products


@router.post("/", response_model=Product)
def create_product(
        product: ProductCreate,
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_user)
):
    if product.product_type_id is None:
        raise HTTPException(status_code=400, detail="product_type_id is required")
    return crud_product.create_product(db, product=product, user_id=current_user.id)


@router.get("/{product_id}", response_model=Product)
def get_product(
        product_id: int,
        db: Session = Depends(deps.get_db)
):
    product = crud_product.get_product(db, product_id=product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product


@router.put("/{product_id}", response_model=Product)
def update_product(
        product_id: int,
        product_update: ProductUpdate,
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_user)
):
    current_product = crud_product.get_product(db, product_id=product_id)
    if not current_product:
        raise HTTPException(status_code=404, detail="Product not found")
    if current_product.seller_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this product")
    if "product_type_id" in product_update.dict(exclude_unset=True) and product_update.product_type_id is None:
        raise HTTPException(status_code=400, detail="product_type_id cannot be null")
    updated_product = crud_product.update_product(db, db_obj=current_product, obj_in=product_update)
    return updated_product


@router.delete("/{product_id}", response_model=Product)
def remove_product(
        product_id: int,
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_user)
):
    current_product = crud_product.get_product(db, product_id=product_id)
    if not current_product:
        raise HTTPException(status_code=404, detail="Product not found")
    if current_product.seller_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to remove this product")
    removed_product = crud_product.remove_product(db, id=product_id)
    return removed_product
