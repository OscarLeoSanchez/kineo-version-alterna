from datetime import datetime

from pydantic import BaseModel, Field


class WeeklyGoalUpsert(BaseModel):
    workout_sessions_target: int = Field(ge=1, le=14)
    nutrition_adherence_target: int = Field(ge=0, le=100)
    weight_checkins_target: int = Field(ge=0, le=7)
    reminders_enabled: bool = True
    reminder_time: str = Field(pattern=r"^\d{2}:\d{2}$")


class WeeklyGoalRead(WeeklyGoalUpsert):
    id: int
    created_at: datetime
    updated_at: datetime | None = None

    model_config = {"from_attributes": True}
