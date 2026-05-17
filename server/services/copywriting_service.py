import json
import logging

import httpx

from config import settings

logger = logging.getLogger(__name__)


class CopywritingService:
    async def _chat(self, messages: list, temperature: float = 0.8, max_tokens: int = 2048) -> str:
        headers = {
            "Authorization": f"Bearer {settings.BAILIAN_API_KEY}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": settings.BAILIAN_LLM_MODEL,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
            "response_format": {"type": "json_object"},
        }
        async with httpx.AsyncClient(timeout=httpx.Timeout(60.0)) as client:
            resp = await client.post(
                f"{settings.BAILIAN_BASE_URL}/chat/completions",
                json=payload,
                headers=headers,
            )
            resp.raise_for_status()
            data = resp.json()
        choices = data.get("choices")
        if not choices or not isinstance(choices, list) or len(choices) == 0:
            raise ValueError(f"LLM API returned no choices: {list(data.keys())}")
        message = choices[0].get("message")
        if not message or "content" not in message:
            raise ValueError("LLM API returned invalid message structure")
        content = message["content"]
        return content

    def _parse_json(self, text: str) -> dict:
        text = text.strip()
        if text.startswith("```json"):
            text = text.removeprefix("```json").removesuffix("```").strip()
        elif text.startswith("```"):
            text = text.removeprefix("```").removesuffix("```").strip()
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            logger.warning(f"Failed to parse LLM JSON response: {text[:200]}")
            return {}

    async def generate_copywriting(self, description: str, tone: str, garment_info: str = "") -> dict:
        system_prompt = (
            "你是一位小红书爆款文案专家，擅长撰写种草笔记。"
            "你需要根据用户提供的服装描述和风格要求，生成小红书风格的帖子文案。"
            "要求：\n"
            "1. 标题要有吸引力，使用emoji装饰\n"
            "2. 正文要生动活泼，使用emoji，分段清晰\n"
            "3. 标签要包含热门话题标签，格式为#标签名\n"
            "4. 必须返回JSON格式：{\"title\": \"标题\", \"content\": \"正文\", \"tags\": [\"标签1\", \"标签2\"]}\n"
            "5. 只返回JSON，不要其他内容"
        )

        user_prompt = f"服装描述：{description}\n风格调性：{tone}\n"
        if garment_info:
            user_prompt += f"服装信息：{garment_info}\n"
        user_prompt += "\n请生成小红书种草文案，返回JSON格式。"

        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ]

        content = await self._chat(messages, temperature=0.8)
        result = self._parse_json(content)

        return {
            "title": result.get("title", ""),
            "content": result.get("content", ""),
            "tags": result.get("tags", []),
        }

    async def edit_copywriting(
        self,
        current_title: str,
        current_content: str,
        current_tags: list,
        instruction: str,
    ) -> dict:
        system_prompt = (
            "你是一位小红书爆款文案专家，擅长根据用户指令修改已有文案。"
            "你需要根据用户的修改指令，调整标题、正文和标签。"
            "要求：\n"
            "1. 保持小红书风格，使用emoji\n"
            "2. 严格按照用户的修改指令调整\n"
            "3. 必须返回JSON格式：{\"title\": \"标题\", \"content\": \"正文\", \"tags\": [\"标签1\", \"标签2\"]}\n"
            "4. 只返回JSON，不要其他内容"
        )

        current_text = f"当前标题：{current_title}\n当前正文：{current_content}\n当前标签：{', '.join(current_tags)}"
        user_prompt = f"{current_text}\n\n修改指令：{instruction}\n\n请返回修改后的完整文案，JSON格式。"

        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ]

        content = await self._chat(messages, temperature=0.7)
        result = self._parse_json(content)

        return {
            "title": result.get("title", current_title),
            "content": result.get("content", current_content),
            "tags": result.get("tags", current_tags),
        }
