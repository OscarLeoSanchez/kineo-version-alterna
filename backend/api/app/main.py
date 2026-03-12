from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app import models  # noqa: F401
from app.api.v1.router import router as v1_router
from app.core.config import settings
from app.db.bootstrap import bootstrap_database
from app.db.session import engine


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    bootstrap_database(engine)
    yield


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        debug=settings.debug,
        version="0.1.0",
        lifespan=lifespan,
    )
    app.include_router(v1_router, prefix=settings.api_prefix)

    @app.get("/")
    async def root() -> dict[str, str]:
        return {
            "name": settings.app_name,
            "environment": settings.app_env,
        }

    @app.get("/health")
    async def root_health() -> dict[str, str]:
        return {"status": "ok"}

    return app


app = create_app()
