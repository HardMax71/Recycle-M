# /app/core/config.py
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "Recycle-M"
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = "f4e7e7b1"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    SQLALCHEMY_DATABASE_URI: str = "sqlite:///./backend/recycle_m.db"
    ALLOWED_ORIGINS: List[str] = ["http://localhost", "http://localhost:8080",
                                  "http://127.0.0.1", "http://127.0.0.1:8080",]
    # For saving images
    IMGUR_CLIENT_ID: str = "xxx"

    # For map in step 4 of "scan"
    GOOGLE_MAPS_API_KEY: str = "xxx"

    # For password resets
    SMTP_HOST: str = "smtp.example.com"
    SMTP_PORT: int = 587
    SMTP_USER: str = "your_email@example.com"
    SMTP_PASSWORD: str = "your_email_password"
    EMAILS_FROM_EMAIL: str = "noreply@example.com"
    EMAILS_FROM_NAME: str = "Recycle-M Support"
    PASSWORD_RESET_TOKEN_EXPIRE_HOURS: int = 24

    model_config = SettingsConfigDict(env_file=".env")


settings = Settings()
