import json
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field

from models import PostStatus


class DeviceAuthRequest(BaseModel):
    device_id: str


class LoginRequest(BaseModel):
    username: str
    password: str


class RegisterRequest(BaseModel):
    username: str
    password: str
    nickname: Optional[str] = None


class UserResponse(BaseModel):
    id: str
    username: str
    nickname: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


class PostCreate(BaseModel):
    description: Optional[str] = None
    tone: Optional[str] = None


class PostUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    tags: Optional[list[str]] = None


class PostResponse(BaseModel):
    id: str
    user_id: str
    garment_image_path: Optional[str] = None
    street_photo_path: Optional[str] = None
    tryon_image_path: Optional[str] = None
    description: Optional[str] = None
    tone: Optional[str] = None
    title: Optional[str] = None
    content: Optional[str] = None
    tags: Optional[list[str]] = None
    images: Optional[list[str]] = None
    status: PostStatus = PostStatus.draft
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}

    @classmethod
    def from_orm_with_json(cls, post):
        tags = json.loads(post.tags) if post.tags else []
        images = json.loads(post.images) if post.images else []
        return cls(
            id=post.id,
            user_id=post.user_id,
            garment_image_path=post.garment_image_path,
            street_photo_path=post.street_photo_path,
            tryon_image_path=post.tryon_image_path,
            description=post.description,
            tone=post.tone,
            title=post.title,
            content=post.content,
            tags=tags,
            images=images,
            status=post.status,
            created_at=post.created_at,
            updated_at=post.updated_at,
        )


class PostListResponse(BaseModel):
    posts: list[PostResponse]
    total: int
    page: int
    page_size: int


class TryOnRequest(BaseModel):
    post_id: str
    garment_type: str = Field(default="tops", pattern="^(tops|bottoms|dresses)$")


class TryOnResponse(BaseModel):
    post_id: str
    tryon_image_url: Optional[str] = None
    status: PostStatus


class CopywritingRequest(BaseModel):
    post_id: str


class CopywritingResponse(BaseModel):
    post_id: str
    title: str
    content: str
    tags: list[str]


class EditRequest(BaseModel):
    post_id: str
    instruction: str
    edit_type: str = Field(default="text", pattern="^(image|text|both)$")


class EditResponse(BaseModel):
    post_id: str
    title: Optional[str] = None
    content: Optional[str] = None
    tags: Optional[list[str]] = None
    tryon_image_path: Optional[str] = None
    edit_type: str
