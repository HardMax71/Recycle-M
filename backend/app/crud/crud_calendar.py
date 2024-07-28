# app/crud/crud_calendar.py
from typing import List, Union

from sqlalchemy.orm import Session

from backend.app.models import CalendarEvent
from backend.app.schemas import CalendarEventCreate, CalendarEventUpdate


def get_user_calendar_events(db: Session, user_id: int, skip: int = 0, limit: int = 100) -> List[CalendarEvent]:
    return db.query(CalendarEvent).filter(CalendarEvent.user_id == user_id).offset(skip).limit(limit).all()


def create_calendar_event(db: Session, event: CalendarEventCreate, user_id: int) -> CalendarEvent:
    db_event = CalendarEvent(**event.dict(), user_id=user_id)
    db.add(db_event)
    db.commit()
    db.refresh(db_event)
    return db_event


def get_calendar_event(db: Session, event_id: int) -> CalendarEvent:
    return db.query(CalendarEvent).filter(CalendarEvent.id == event_id).first()


def update_calendar_event(db: Session, db_obj: CalendarEvent,
                          obj_in: Union[CalendarEventUpdate, dict]) -> CalendarEvent:
    if isinstance(obj_in, dict):
        update_data = obj_in
    else:
        update_data = obj_in.dict(exclude_unset=True)
    for field in update_data:
        if hasattr(db_obj, field):
            setattr(db_obj, field, update_data[field])
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def delete_calendar_event(db: Session, id: int) -> CalendarEvent:
    event = db.query(CalendarEvent).get(id)
    db.delete(event)
    db.commit()
    return event
