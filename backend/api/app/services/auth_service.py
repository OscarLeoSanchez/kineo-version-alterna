from fastapi import HTTPException, status

from app.core.security import create_access_token, hash_password, verify_password
from app.repositories.user_repository import UserRepository
from app.schemas.auth import (
    AuthLoginRequest,
    AuthProfileUpdateRequest,
    AuthRegisterRequest,
    AuthTokenResponse,
    UserRead,
)


class AuthService:
    def __init__(self, repository: UserRepository) -> None:
        self.repository = repository

    def register(self, payload: AuthRegisterRequest) -> AuthTokenResponse:
        existing = self.repository.get_by_email(payload.email)
        if existing is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already registered",
            )

        user = self.repository.create_user(
            email=payload.email,
            password_hash=hash_password(payload.password),
            full_name=payload.full_name,
        )
        return self._build_auth_response(user)

    def login(self, payload: AuthLoginRequest) -> AuthTokenResponse:
        user = self.repository.get_by_email(payload.email)
        if user is None or not verify_password(payload.password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials",
            )
        return self._build_auth_response(user)

    def update_profile(self, *, current_user, payload: AuthProfileUpdateRequest) -> UserRead:
        user = self.repository.update_full_name(
            user_id=current_user.id,
            full_name=payload.full_name.strip(),
        )
        return self.to_user_read(user)

    @staticmethod
    def to_user_read(user) -> UserRead:
        return UserRead.model_validate(user)

    def _build_auth_response(self, user) -> AuthTokenResponse:
        return AuthTokenResponse(
            access_token=create_access_token(user.email),
            user=self.to_user_read(user),
        )
