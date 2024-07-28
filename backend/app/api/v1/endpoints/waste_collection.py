from typing import List

from fastapi import APIRouter, Depends, File, UploadFile, Query
from sqlalchemy.orm import Session

from backend.app.api import deps
from backend.app.crud import crud_waste_collection
from backend.app.schemas import WasteCollection, WasteCollectionCreate, User
from backend.app.services import detect_waste_type

router = APIRouter()


@router.get("/waste-types", response_model=List[str])
def get_waste_types(db: Session = Depends(deps.get_db)):
    return crud_waste_collection.get_waste_types(db)


@router.post("/detect-waste", response_model=str)
async def detect_waste(
        file: UploadFile = File(...)
):
    image_data = await file.read()
    waste_type = await detect_waste_type(image_data)
    return waste_type


@router.post("/", response_model=WasteCollection)
def create_waste_collection(
        waste_collection: WasteCollectionCreate,
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_user)
):
    return crud_waste_collection.create_waste_collection(db, waste_collection=waste_collection, user_id=current_user.id)


@router.get("/recycling-centers", response_model=List[dict])
def get_nearby_recycling_centers(
        latitude: float = Query(...),
        longitude: float = Query(...),
        db: Session = Depends(deps.get_db)
):
    return crud_waste_collection.get_nearby_recycling_centers(db, latitude=latitude, longitude=longitude)


@router.get("/reward", response_model=dict)
def get_reward(
        waste_type: str = Query(...),
        db: Session = Depends(deps.get_db)
):
    return {"reward": crud_waste_collection.get_reward_for_waste_type(db, waste_type)}
