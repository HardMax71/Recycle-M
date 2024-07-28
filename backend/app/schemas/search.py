# app/schemas/search.py
from pydantic import BaseModel


class SearchResult(BaseModel):
    id: int
    type: str
    title: str
    description: str

    class Config:
        from_attributes = True
