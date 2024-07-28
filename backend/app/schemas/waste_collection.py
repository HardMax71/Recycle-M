from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class WasteCollectionBase(BaseModel):
    waste_type: str
    quantity: float
    collection_date: datetime
    location_latitude: float
    location_longitude: float


class WasteCollectionCreate(WasteCollectionBase):
    pass


class WasteCollection(WasteCollectionBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True


class RecyclingCenter(BaseModel):
    id: int
    name: str
    address: str
    latitude: float
    longitude: float
    distance: Optional[float]

    class Config:
        from_attributes = True


class WasteType(BaseModel):
    id: int
    name: str
    reward_points: int

    class Config:
        from_attributes = True
