from typing import List, Optional

from fastapi import UploadFile
from sqlalchemy.orm import Session, joinedload

from backend.app.crud.crud_user import upload_to_imgur
from backend.app.models import Post
from backend.app.schemas import PostCreate, PostUpdate, PostImage


def get_posts(
        db: Session,
        skip: int = 0,
        limit: int = 100,
        search: Optional[str] = None,
        post_type_id: Optional[int] = None
) -> List[Post]:
    query = db.query(Post).options(joinedload(Post.author), joinedload(Post.post_type))
    if search:
        query = query.filter(Post.title.ilike(f"%{search}%") | Post.content.ilike(f"%{search}%"))
    if post_type_id:
        query = query.filter(Post.post_type_id == post_type_id)
    return query.offset(skip).limit(limit).all()


def create_post(db: Session, post: PostCreate, user_id: int, files: List[UploadFile] = None):
    db_post = Post(**post.dict(exclude={'images'}), author_id=user_id)
    db.add(db_post)
    db.commit()
    db.refresh(db_post)

    if files:
        for file in files:
            file_url = upload_to_imgur(file)
            db_image = PostImage(url=file_url, post_id=db_post.id)
            db.add(db_image)
        db.commit()

    return db_post


def get_post(db: Session, id: int) -> Optional[Post]:
    return db.query(Post).options(joinedload(Post.author), joinedload(Post.post_type), joinedload(Post.images)).filter(
        Post.id == id).first()


def get_user_posts(db: Session, user_id: int, skip: int = 0, limit: int = 100) -> List[Post]:
    return db.query(Post).filter(Post.author_id == user_id).offset(skip).limit(limit).all()


def update_post(db: Session, db_obj: Post, obj_in: PostUpdate, files: List[UploadFile] = None):
    update_data = obj_in.dict(exclude_unset=True, exclude={'images'})
    for field, value in update_data.items():
        setattr(db_obj, field, value)

    if files:
        # Remove existing images
        for image in db_obj.images:
            db.delete(image)

        # Add new images
        for file in files:
            file_url = upload_to_imgur(file)
            db_image = PostImage(url=file_url, post_id=db_obj.id)
            db.add(db_image)

    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj


def delete_post(db: Session, id: int) -> Post:
    post = db.query(Post).get(id)
    db.delete(post)
    db.commit()
    return post
