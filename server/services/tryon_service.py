import asyncio
import base64
import logging
import os
import uuid

import httpx

from config import settings

logger = logging.getLogger(__name__)


class TryOnService:
    def _file_to_data_uri(self, file_path: str) -> str:
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"Image file not found: {file_path}")
        with open(file_path, "rb") as f:
            data = base64.b64encode(f.read()).decode()
        ext = file_path.rsplit(".", 1)[-1].lower()
        mime = {"jpg": "image/jpeg", "jpeg": "image/jpeg", "png": "image/png"}.get(ext, "image/jpeg")
        return f"data:{mime};base64,{data}"

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
        dir_path = os.path.join(settings.UPLOAD_DIR, "tryon")
        os.makedirs(dir_path, exist_ok=True)
        file_path = os.path.join(dir_path, filename)
        with open(file_path, "wb") as f:
            f.write(image_data)
        return os.path.join("tryon", filename)

    async def run_tryon(self, human_image_path: str, garment_image_path: str, garment_type: str = "tops") -> str:
        full_garment_path = garment_image_path if os.path.isabs(garment_image_path) else os.path.join(settings.UPLOAD_DIR, garment_image_path)
        full_human_path = human_image_path if os.path.isabs(human_image_path) else os.path.join(settings.UPLOAD_DIR, human_image_path)

        person_image_uri = self._file_to_data_uri(full_human_path)
        garment_image_uri = self._file_to_data_uri(full_garment_path)

        headers = {
            "Authorization": f"Bearer {settings.BAILIAN_API_KEY}",
            "Content-Type": "application/json",
            "X-DashScope-Async": "enable",
        }

        input_data = {
            "person_image_url": person_image_uri,
        }

        if garment_type == "bottoms":
            input_data["bottom_garment_url"] = garment_image_uri
        elif garment_type == "dresses":
            input_data["dress_garment_url"] = garment_image_uri
        else:
            input_data["top_garment_url"] = garment_image_uri

        payload = {
            "model": settings.BAILIAN_TRYON_MODEL,
            "input": input_data,
            "parameters": {
                "restore_face": True,
            },
        }

        submit_url = f"{settings.BAILIAN_DASHSCOPE_ENDPOINT}/services/aigc/image2image/image-synthesis"

        logger.info("Submitting try-on task")
        async with httpx.AsyncClient(timeout=httpx.Timeout(60.0)) as client:
            resp = await client.post(submit_url, json=payload, headers=headers)
            try:
                resp.raise_for_status()
            except httpx.HTTPStatusError:
                raise Exception(f"Bailian try-on submit failed: {resp.status_code} - {resp.text}")
            result = resp.json()

        output = result.get("output", {})
        task_id = output.get("task_id")
        if not task_id:
            raise Exception(f"Bailian try-on submit failed: no task_id in response - {result}")

        logger.info(f"Try-on task submitted, task_id={task_id}, polling for result")

        poll_url = f"{settings.BAILIAN_DASHSCOPE_ENDPOINT}/tasks/{task_id}"
        poll_headers = {
            "Authorization": f"Bearer {settings.BAILIAN_API_KEY}",
        }

        max_retries = 60
        async with httpx.AsyncClient(timeout=httpx.Timeout(30.0)) as client:
            for _ in range(max_retries):
                await asyncio.sleep(5)
                poll_resp = await client.get(poll_url, headers=poll_headers)
                poll_resp.raise_for_status()
                poll_result = poll_resp.json()

                output = poll_result.get("output", {})
                task_status = output.get("task_status", "")

                if task_status == "SUCCEEDED":
                    image_url = output.get("image_url", "")
                    if image_url:
                        logger.info(f"Try-on task succeeded, downloading result")
                        return await self._save_image_from_url(image_url)
                    raise Exception("Bailian try-on succeeded but no image_url found")

                elif task_status == "FAILED":
                    raise Exception(f"Bailian try-on task failed: {output}")

        raise Exception("Bailian try-on task timed out")
