from sqlalchemy import func
from sqlalchemy.orm import Session

from backend.app.models import WasteCollection, RecyclingCenter, WasteType
from backend.app.schemas import WasteCollectionCreate


def get_waste_types(db: Session):
    return [waste_type.name for waste_type in db.query(WasteType).all()]


def create_waste_collection(db: Session, waste_collection: WasteCollectionCreate, user_id: int):
    db_waste_collection = WasteCollection(**waste_collection.dict(), user_id=user_id)
    db.add(db_waste_collection)
    db.commit()
    db.refresh(db_waste_collection)
    return db_waste_collection


def get_nearby_recycling_centers(db: Session, latitude: float, longitude: float, radius: float = 10.0):
    # Increase the radius to 10.0 km to find more centers
    distance = func.sqrt(
        func.pow(111.045 * (RecyclingCenter.latitude - latitude), 2) +
        func.pow(111.045 * func.cos(func.radians(latitude)) * (RecyclingCenter.longitude - longitude), 2)
    )

    query = db.query(
        RecyclingCenter.id,
        RecyclingCenter.name,
        RecyclingCenter.address,
        RecyclingCenter.latitude,
        RecyclingCenter.longitude,
        distance.label('distance')
    ).filter(distance <= radius).order_by(distance).limit(10)

    results = [
        {
            "id": row.id,
            "name": row.name,
            "address": row.address,
            "latitude": float(row.latitude),
            "longitude": float(row.longitude),
            "distance": float(row.distance)
        }
        for row in query
    ]

    return results


def get_reward_for_waste_type(db: Session, waste_type: str):
    waste_type_obj = db.query(WasteType).filter(WasteType.name == waste_type).first()
    if waste_type_obj:
        return waste_type_obj.reward_points
    return 0
