import json
import logging

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from database import get_db
from models import Post, PostStatus, User
from routers.auth import get_current_user
from schemas import TryOnRequest, TryOnResponse, CopywritingRequest, CopywritingResponse, EditRequest, EditResponse
from services.tryon_service import TryOnService
from services.copywriting_service import CopywritingService
from services.image_service import ImageService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/ai", tags=["ai"])


@router.post("/tryon", response_model=TryOnResponse)
async def tryon(
    request: TryOnRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    post = db.query(Post).filter(Post.id == request.post_id, Post.user_id == current_user.id).first()
    if not post:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Post not found")
    if not post.garment_image_path or not post.street_photo_path:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Post must have both garment image and street photo",
        )
    original_status = post.status
    post.status = PostStatus.generating
    db.commit()
    try:
        service = TryOnService()
        tryon_image_url = await service.run_tryon(
            human_image_path=post.street_photo_path,
            garment_image_path=post.garment_image_path,
            garment_type=request.garment_type,
        )
        post.tryon_image_path = tryon_image_url
        post.status = PostStatus.completed
        images = json.loads(post.images) if post.images else []
        if tryon_image_url not in images:
            images.append(tryon_image_url)
        post.images = json.dumps(images, ensure_ascii=False)
        db.commit()
        db.refresh(post)
    except Exception as e:
        logger.error("Try-on generation failed", exc_info=True)
        post.status = original_status
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Try-on generation failed",
        )
    return TryOnResponse(
        post_id=post.id,
        tryon_image_url=tryon_image_url,
        status=post.status,
    )


@router.post("/copywriting", response_model=CopywritingResponse)
async def copywriting(
    request: CopywritingRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    post = db.query(Post).filter(Post.id == request.post_id, Post.user_id == current_user.id).first()
    if not post:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Post not found")
    try:
        service = CopywritingService()
        result = await service.generate_copywriting(
            description=post.description or "",
            tone=post.tone or "活泼",
            garment_info=post.garment_image_path or "",
        )
        post.title = result["title"]
        post.content = result["content"]
        post.tags = json.dumps(result["tags"], ensure_ascii=False)
        if post.status == PostStatus.draft:
            post.status = PostStatus.completed
        db.commit()
        db.refresh(post)
    except Exception as e:
        logger.error("Copywriting generation failed", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Copywriting generation failed",
        )
    return CopywritingResponse(
        post_id=post.id,
        title=result["title"],
        content=result["content"],
        tags=result["tags"],
    )


@router.post("/edit", response_model=EditResponse)
async def edit(
    request: EditRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    post = db.query(Post).filter(Post.id == request.post_id, Post.user_id == current_user.id).first()
    if not post:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Post not found")

    updated_title = None
    updated_content = None
    updated_tags = None
    updated_tryon_image_path = None

    if request.edit_type in ("text", "both"):
        if not post.title and not post.content:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Post has no copywriting to edit",
            )
        try:
            service = CopywritingService()
            current_tags = json.loads(post.tags) if post.tags else []
            result = await service.edit_copywriting(
                current_title=post.title or "",
                current_content=post.content or "",
                current_tags=current_tags,
                instruction=request.instruction,
            )
            post.title = result["title"]
            post.content = result["content"]
            post.tags = json.dumps(result["tags"], ensure_ascii=False)
            updated_title = result["title"]
            updated_content = result["content"]
            updated_tags = result["tags"]
            db.commit()
        except Exception as e:
            logger.error("Text edit failed", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Text edit failed",
            )

    if request.edit_type in ("image", "both"):
        if not post.tryon_image_path:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Post has no try-on image to edit",
            )
        try:
            service = ImageService()
            new_image_url = await service.edit_image(
                image_path=post.tryon_image_path,
                instruction=request.instruction,
            )
            post.tryon_image_path = new_image_url
            updated_tryon_image_path = new_image_url
            images = json.loads(post.images) if post.images else []
            if new_image_url not in images:
                images.append(new_image_url)
            post.images = json.dumps(images, ensure_ascii=False)
        except Exception as e:
            logger.error("Image edit failed", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Image edit failed",
            )

    db.commit()
    db.refresh(post)

    return EditResponse(
        post_id=post.id,
        title=updated_title,
        content=updated_content,
        tags=updated_tags,
        tryon_image_path=updated_tryon_image_path,
        edit_type=request.edit_type,
    )
