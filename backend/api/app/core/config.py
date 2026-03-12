from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Kineo Coach API"
    app_env: str = "local"
    debug: bool = True
    api_prefix: str = "/api/v1"
    database_url: str = "sqlite:///./kineo_coach.db"
    jwt_secret: str = "change-me-please-use-at-least-32-characters"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 1440
    ai_provider: str = "openai"
    ai_model: str = "gpt-4.1-mini"
    ai_api_key: str = ""
    ai_base_url: str | None = None
    ai_enable_live_generation: bool = False

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )


settings = Settings()
