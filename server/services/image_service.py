import base64
import logging
import os
import uuid

import httpx

from config import settings

logger = logging.getLogger(__name__)


class ImageService:
    def _image_to_base64(self, file_path: str) -> str:
        full_path = file_path if os.path.isabs(file_path) else os.path.join(settings.UPLOAD_DIR, file_path)
        if not os.path.exists(full_path):
            raise FileNotFoundError(f"Image not found: {full_path}")
        with open(full_path, "rb") as f:
            encoded = base64.b64encode(f.read()).decode("utf-8")
        ext = os.path.splitext(full_path)[1].lower()
        mime_map = {
            ".jpg": "image/jpeg",
            ".jpeg": "image/jpeg",
            ".png": "image/png",
            ".webp": "image/webp",
        }
        mime_type = mime_map.get(ext, "image/jpeg")
        return f"data:{mime_type};base64,{encoded}"

    async def _save_image_from_url(self, url: str) -> str:
        async with httpx.AsyncClient(timeout=httpx.Timeout(120.0)) as client:
            resp = await client.get(url)
            resp.raise_for_status()
        image_data = resp.content
        content_type = resp.headers.get("content-type", "")
        ext = ".png"
        if "jpeg" in content_type or "jpg" in content_type:
            ext = ".jpg"
        elif "webp" in content_type:
            ext = ".webp"

        filename = f"{uuid.uuid4().hex}{ext}"
        dir_path = os.path.join(settings.UPLOAD_DIR, "edited")
        os.makedirs(dir_path, exist_ok=True)
        file_path = os.path.join(dir_path, filename)
        with open(file_path, "wb") as f:
            f.write(image_data)
        return os.path.join("edited", filename).replace("\\", "/")

    async def edit_image(self, image_path: str, instruction: str) -> str:
        logger.info("Starting image edit")
        image_base64 = self._image_to_base64(image_path)

        headers = {
            "Authorization": f"Bearer {settings.BAILIAN_API_KEY}",
            "Content-Type": "application/json",
        }

        payload = {
            "model": settings.BAILIAN_IMAGE_MODEL,
            "input": {
                "messages": [
                    {
                        "role": "user",
                        "content": [
                            {"image": image_base64},
                            {"text": instruction},
                        ],
                    }
                ]
            },
            "parameters": {
                "n": 1,
                "size": "768*1024",
            },
        }

        url = f"{settings.BAILIAN_DASHSCOPE_ENDPOINT}/services/aigc/multimodal-generation/generation"

        async with httpx.AsyncClient(timeout=httpx.Timeout(120.0)) as client:
            resp = await client.post(url, json=payload, headers=headers)
            try:
                resp.raise_for_status()
            except httpx.HTTPStatusError:
                raise Exception(f"Bailian image edit failed: {resp.status_code} - {resp.text}")
            data = resp.json()

        choices = data.get("output", {}).get("choices", [])
        if not choices:
            raise Exception(f"Bailian image edit failed: no choices in response - {data}")

        contents = choices[0].get("message", {}).get("content", [])
        if not contents:
            raise Exception(f"Bailian image edit failed: no content in response - {data}")

        image_url = contents[0].get("image", "")
        if not image_url:
            raise Exception(f"Bailian image edit failed: no image URL in response - {data}")

        logger.info("Image edit API succeeded, downloading result")
        return await self._save_image_from_url(image_url)
