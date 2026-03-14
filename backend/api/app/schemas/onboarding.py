from datetime import date, datetime

from pydantic import BaseModel, Field


class UserProfileBase(BaseModel):
    full_name: str = Field(min_length=2, max_length=120)
    age: int = Field(ge=16, le=80)
    birth_date: date | None = None
    sex: str | None = Field(default=None, min_length=2, max_length=32)
    gender_identity: str | None = Field(default=None, min_length=2, max_length=32)
    height_cm: int = Field(ge=120, le=230)
    weight_kg: int = Field(ge=35, le=250)
    goal: str = Field(min_length=3, max_length=80)
    activity_level: str = Field(min_length=3, max_length=80)
    workout_days_per_week: int = Field(ge=1, le=7)
    session_minutes: int = Field(ge=10, le=180)
    training_location: str = Field(default="Mixto", min_length=2, max_length=80)
    cooking_style: str = Field(default="Simple", min_length=2, max_length=80)
    meals_per_day: int = Field(default=4, ge=2, le=7)
    equipment: list[str] = Field(default_factory=list)
    dietary_preferences: list[str] = Field(default_factory=list)
    allergies: list[str] = Field(default_factory=list)
    food_dislikes: list[str] = Field(default_factory=list)
    restrictions: list[str] = Field(default_factory=list)
    body_measurements: dict[str, float] = Field(default_factory=dict)
    additional_notes: str = Field(default="", max_length=2000)


class UserProfileCreate(UserProfileBase):
    pass


class UserProfileRead(UserProfileBase):
    id: int
    user_id: int | None = None
    created_at: datetime
    updated_at: datetime | None = None

    model_config = {"from_attributes": True}


class DashboardSummary(BaseModel):
    headline: str
    workout_focus: str
    nutrition_focus: str
    adherence_message: str
    current_plan_summary: str
    streak_days: int = 0
    weekly_adherence: int = 0
