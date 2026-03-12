from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.db.session import get_db
from app.repositories.user_repository import UserRepository
from app.schemas.auth import (
    AuthLoginRequest,
    AuthProfileUpdateRequest,
    AuthRegisterRequest,
    AuthTokenResponse,
    UserRead,
)
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth")


def get_auth_service(db: Session = Depends(get_db)) -> AuthService:
    return AuthService(UserRepository(db))


@router.post("/register", response_model=AuthTokenResponse)
async def register(
    payload: AuthRegisterRequest,
    service: AuthService = Depends(get_auth_service),
) -> AuthTokenResponse:
    return service.register(payload)


@router.post("/login", response_model=AuthTokenResponse)
async def login(
    payload: AuthLoginRequest,
    service: AuthService = Depends(get_auth_service),
) -> AuthTokenResponse:
    return service.login(payload)


@router.get("/me", response_model=UserRead)
async def me(current_user=Depends(get_current_user)) -> UserRead:
    return AuthService.to_user_read(current_user)


@router.patch("/me", response_model=UserRead)
async def update_me(
    payload: AuthProfileUpdateRequest,
    current_user=Depends(get_current_user),
    service: AuthService = Depends(get_auth_service),
) -> UserRead:
    return service.update_profile(current_user=current_user, payload=payload)
