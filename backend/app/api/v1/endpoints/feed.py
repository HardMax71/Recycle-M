# app/api/v1/endpoints/feed.py
from typing import List, Optional

from fastapi import APIRouter, Depends, Query, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session

from backend.app.api import deps
from backend.app.crud import crud_post
from backend.app.schemas import Post, PostCreate, PostUpdate, User

router = APIRouter()


@router.get("/", response_model=List[Post])
def read_feed(
        db: Session = Depends(deps.get_db),
        skip: int = Query(0, ge=0),
        limit: int = Query(20, ge=1, le=100),
        search: Optional[str] = Query(None, min_length=3, max_length=50),
        post_type_id: Optional[int] = Query(None)
):
    posts = crud_post.get_posts(db, skip=skip, limit=limit, search=search, post_type_id=post_type_id)
    return posts


@router.get("/{post_id}", response_model=Post)
def read_post(
        post_id: int,
        db: Session = Depends(deps.get_db)
):
    post = crud_post.get_post(db, id=post_id)
    if post is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Post with id {post_id} not found")
    return post


@router.post("/", response_model=Post)
def create_post(
        post: PostCreate = Depends(),
        files: List[UploadFile] = File(None),
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_user)
):
    return crud_post.create_post(db, post, current_user.id, files)


@router.get("/user/{user_id}", response_model=List[Post])
def read_user_posts(
        user_id: int,
        db: Session = Depends(deps.get_db),
        skip: int = Query(0, ge=0),
        limit: int = Query(20, ge=1, le=100)
):
    posts = crud_post.get_user_posts(db, user_id=user_id, skip=skip, limit=limit)
    return posts


@router.put("/{post_id}", response_model=Post)
def update_post(
        post_id: int,
        post: PostUpdate,
        files: List[UploadFile] = File(None),
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_user)
):
    db_post = crud_post.get_post(db, post_id)
    if not db_post:
        raise HTTPException(status_code=404, detail="Post not found")
    if db_post.author_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    return crud_post.update_post(db, db_post, post, files)


@router.delete("/{post_id}", response_model=Post)
def delete_post(
        post_id: int,
        db: Session = Depends(deps.get_db),
        current_user: User = Depends(deps.get_current_user)
):
    post = crud_post.get_post(db, id=post_id)
    if post is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Post with id {post_id} not found")
    if post.author_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to delete this post")
    return crud_post.delete_post(db, id=post_id)
