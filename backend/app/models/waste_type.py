from backend.app.db.base import Base
from sqlalchemy import Column, Integer, String


class WasteType(Base):
    __tablename__ = "waste_types"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    reward_points = Column(Integer)
