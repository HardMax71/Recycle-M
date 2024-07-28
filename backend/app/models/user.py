# /app/models/user.py
from sqlalchemy import Boolean, Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship

from backend.app.db.base import Base


class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String)
    bio = Column(String, default="No bio :(")
    is_active = Column(Boolean, default=True)
    balance = Column(Integer, default=0)
    opt_out_newspaper = Column(Boolean, default=False)
    receive_notifications = Column(Boolean, default=True)
    receive_newsletter = Column(Boolean, default=True)
    receive_product_updates = Column(Boolean, default=True)
    receive_feedback_requests = Column(Boolean, default=True)
    appear_in_search_results = Column(Boolean, default=True)
    allow_data_collection = Column(Boolean, default=True)
    profile_image = Column(String)

    posts = relationship("Post", back_populates="author")
    expenses = relationship("Expense", back_populates="user")
    products = relationship("Product", back_populates="seller")
    calendar_events = relationship("CalendarEvent", back_populates="user")
    waste_collections = relationship("WasteCollection", back_populates="user")
    photos = relationship("UserPhoto", back_populates="user")
    rewards = relationship("Reward", back_populates="user")


class UserPhoto(Base):
    __tablename__ = 'photos'
    id = Column(Integer, primary_key=True, index=True)
    url = Column(String)
    user_id = Column(Integer, ForeignKey("users.id"))

    user = relationship("User", back_populates="photos")
