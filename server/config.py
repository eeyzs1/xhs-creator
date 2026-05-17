import logging
import os
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "sqlite:///./xhs_creator.db"

    BAILIAN_API_KEY: str = ""
    BAILIAN_BASE_URL: str = "https://dashscope.aliyuncs.com/compatible-mode/v1"
    BAILIAN_DASHSCOPE_ENDPOINT: str = "https://dashscope.aliyuncs.com/api/v1"
    BAILIAN_LLM_MODEL: str = "qwen-plus"
    BAILIAN_IMAGE_MODEL: str = "qwen-image-2.0-pro"
    BAILIAN_TRYON_MODEL: str = "aitryon"

    UPLOAD_DIR: str = "./uploads"
    SECRET_KEY: str = "xhs-creator-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 30
    CORS_ORIGINS: list[str] = ["*"]
    SERVER_HOST: str = "http://localhost:8000"

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "extra": "ignore",
    }


settings = Settings()

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')

if settings.SECRET_KEY == "xhs-creator-secret-key-change-in-production":
    logging.warning("⚠️ SECRET_KEY is using default value! Please change it in .env for production.")

os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
