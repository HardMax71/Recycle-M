# app/crud/crud_search.py
from typing import List

from sqlalchemy import or_
from sqlalchemy.orm import Session

from backend.app.models import Post, Product
from backend.app.schemas.search import SearchResult


def search(db: Session, query: str, skip: int = 0, limit: int = 100) -> List[SearchResult]:
    posts = db.query(Post).filter(
        or_(Post.title.ilike(f"%{query}%"), Post.content.ilike(f"%{query}%"))
    ).all()

    products = db.query(Product).filter(
        or_(Product.name.ilike(f"%{query}%"), Product.description.ilike(f"%{query}%"))
    ).all()

    results = []
    for post in posts:
        results.append(SearchResult(
            id=post.id,
            type=post.post_type.name,
            title=post.title,
            description=post.content[:100]
        ))

    for product in products:
        results.append(SearchResult(
            id=product.id,
            type="product",
            title=product.name,
            description=product.description[:100] if product.description else ""
        ))

    results.sort(key=lambda x: x.title.lower().count(query.lower()) + x.description.lower().count(query.lower()),
                 reverse=True)

    return results[skip: skip + limit]
