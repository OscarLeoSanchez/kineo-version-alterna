from fastapi import APIRouter

router = APIRouter()


@router.get("/health")
async def healthcheck() -> dict[str, str]:
    return {"status": "ok"}


@router.get("/meta")
async def metadata() -> dict[str, str]:
    return {
        "service": "kineo-coach-api",
        "module": "core",
    }
