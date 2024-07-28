from datetime import datetime

from sqlalchemy import Column, Integer, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship

from backend.app.db.base import Base


class WasteCollection(Base):
    __tablename__ = 'waste_collections'
    id = Column(Integer, primary_key=True, index=True)
    waste_type_id = Column(Integer, ForeignKey("waste_types.id"))
    quantity = Column(Float)
    collection_date = Column(DateTime, default=datetime.utcnow)
    location_latitude = Column(Float)
    location_longitude = Column(Float)
    user_id = Column(Integer, ForeignKey("users.id"))

    user = relationship("User", back_populates="waste_collections")
    waste_type = relationship("WasteType")
