from pydantic import BaseModel, EmailStr, Field


class AuthRegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=4, max_length=128)
    full_name: str = Field(min_length=2, max_length=120)


class AuthLoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=4, max_length=128)


class AuthProfileUpdateRequest(BaseModel):
    full_name: str = Field(min_length=2, max_length=120)


class UserRead(BaseModel):
    id: int
    email: EmailStr
    full_name: str
    is_active: bool

    model_config = {"from_attributes": True}


class AuthTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserRead
