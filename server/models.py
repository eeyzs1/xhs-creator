import uuid
import enum
from datetime import datetime

from sqlalchemy import Column, String, DateTime, ForeignKey, Text, Enum as SAEnum
from sqlalchemy.orm import relationship

from database import Base


class PostStatus(str, enum.Enum):
    draft = "draft"
    generating = "generating"
    completed = "completed"


class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    username = Column(String(100), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    nickname = Column(String(100), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    posts = relationship("Post", back_populates="user", cascade="all, delete-orphan")


class Post(Base):
    __tablename__ = "posts"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    garment_image_path = Column(String(500), nullable=True)
    street_photo_path = Column(String(500), nullable=True)
    tryon_image_path = Column(String(500), nullable=True)
    description = Column(Text, nullable=True)
    tone = Column(String(50), nullable=True)
    title = Column(String(200), nullable=True)
    content = Column(Text, nullable=True)
    tags = Column(Text, nullable=True)
    images = Column(Text, nullable=True)
    status = Column(SAEnum(PostStatus), default=PostStatus.draft)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="posts")
