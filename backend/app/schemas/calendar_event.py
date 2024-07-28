# app/schemas/calendar_event.py
from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class CalendarEventBase(BaseModel):
    title: str
    description: str
    start_time: datetime
    end_time: datetime


class CalendarEventCreate(CalendarEventBase):
    pass


class CalendarEventUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None

    class Config:
        from_attributes = True


class CalendarEvent(CalendarEventBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True
