import json
import uuid
import os
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Query, status
from sqlalchemy.orm import Session

from config import settings
from database import get_db
from models import Post, PostStatus, User
from routers.auth import get_current_user
from schemas import PostResponse, PostListResponse, PostUpdate

router = APIRouter(prefix="/api/posts", tags=["posts"])

ALLOWED_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.webp'}
MAX_FILE_SIZE = 10 * 1024 * 1024


def save_upload_file(file: UploadFile, subdir: str = "") -> str:
    ext = os.path.splitext(file.filename or "image.jpg")[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File type not allowed. Allowed types: {', '.join(ALLOWED_EXTENSIONS)}",
        )
    content = file.file.read()
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File size exceeds 10MB limit",
        )
    file.file.seek(0)
    filename = f"{uuid.uuid4().hex}{ext}"
    dir_path = os.path.join(settings.UPLOAD_DIR, subdir)
    os.makedirs(dir_path, exist_ok=True)
    file_path = os.path.join(dir_path, filename)
    with open(file_path, "wb") as f:
        f.write(content)
    return (os.path.join(subdir, filename) if subdir else filename).replace("\\", "/")


def _delete_file_if_exists(relative_path: str):
    if not relative_path:
        return
    full_path = os.path.join(settings.UPLOAD_DIR, relative_path)
    if os.path.exists(full_path):
        os.remove(full_path)


@router.get("", response_model=PostListResponse)
def list_posts(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = db.query(Post).filter(Post.user_id == current_user.id)
    total = query.count()
    posts = query.order_by(Post.created_at.desc()).offset((page - 1) * page_size).limit(page_size).all()
    return PostListResponse(
        posts=[PostResponse.from_orm_with_json(p) for p in posts],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.post("", response_model=PostResponse, status_code=status.HTTP_201_CREATED)
def create_post(
    garment_image: UploadFile = File(...),
    street_photo: UploadFile = File(...),
    description: Optional[str] = Form(None),
    tone: Optional[str] = Form(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    garment_path = save_upload_file(garment_image, "garments")
    street_path = save_upload_file(street_photo, "streets")
    post = Post(
        user_id=current_user.id,
        garment_image_path=garment_path,
        street_photo_path=street_path,
        description=description,
        tone=tone,
        status=PostStatus.draft,
    )
    db.add(post)
    db.commit()
    db.refresh(post)
    return PostResponse.from_orm_with_json(post)


@router.get("/{post_id}", response_model=PostResponse)
def get_post(
    post_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    post = db.query(Post).filter(Post.id == post_id, Post.user_id == current_user.id).first()
    if not post:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Post not found")
    return PostResponse.from_orm_with_json(post)


@router.put("/{post_id}", response_model=PostResponse)
def update_post(
    post_id: str,
    post_update: PostUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    post = db.query(Post).filter(Post.id == post_id, Post.user_id == current_user.id).first()
    if not post:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Post not found")
    if post_update.title is not None:
        post.title = post_update.title
    if post_update.content is not None:
        post.content = post_update.content
    if post_update.tags is not None:
        post.tags = json.dumps(post_update.tags, ensure_ascii=False)
    db.commit()
    db.refresh(post)
    return PostResponse.from_orm_with_json(post)


@router.delete("/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_post(
    post_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    post = db.query(Post).filter(Post.id == post_id, Post.user_id == current_user.id).first()
    if not post:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Post not found")
    _delete_file_if_exists(post.garment_image_path)
    _delete_file_if_exists(post.street_photo_path)
    _delete_file_if_exists(post.tryon_image_path)
    if post.images:
        try:
            for img_path in json.loads(post.images):
                _delete_file_if_exists(img_path)
        except (json.JSONDecodeError, TypeError):
            pass
    db.delete(post)
    db.commit()
