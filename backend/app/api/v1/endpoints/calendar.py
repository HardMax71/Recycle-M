# app/api/v1/endpoints/calendar.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from backend.app.api import deps
from backend.app.crud import crud_calendar
from backend.app.schemas import CalendarEvent, CalendarEventCreate, CalendarEventUpdate, User

router = APIRouter()


@router.get("/", response_model=list[CalendarEvent])
def get_calendar_events(
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_user),
        skip: int = 0,
        limit: int = 100
):
    return crud_calendar.get_user_calendar_events(db, user_id=current_user.id, skip=skip, limit=limit)


@router.post("/", response_model=CalendarEvent)
def create_calendar_event(
        event: CalendarEventCreate,
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_user)
):
    return crud_calendar.create_calendar_event(db, event=event, user_id=current_user.id)


@router.put("/{event_id}", response_model=CalendarEvent)
def update_calendar_event(
        event_id: int,
        event: CalendarEventUpdate,
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_user)
):
    db_event = crud_calendar.get_calendar_event(db, event_id=event_id)
    if not db_event or db_event.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Event not found")
    return crud_calendar.update_calendar_event(db, db_obj=db_event, obj_in=event)


@router.delete("/{event_id}", response_model=CalendarEvent)
def delete_calendar_event(
        event_id: int,
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_user)
):
    db_event = crud_calendar.get_calendar_event(db, event_id=event_id)
    if not db_event or db_event.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Event not found")
    return crud_calendar.delete_calendar_event(db, id=event_id)
