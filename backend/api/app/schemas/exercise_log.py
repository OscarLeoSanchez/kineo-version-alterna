from pydantic import BaseModel, ConfigDict, Field
from typing import Optional
from datetime import datetime


class ExerciseLogCreate(BaseModel):
    day_iso_date: str = Field(min_length=10, max_length=10)  # "2026-03-13"
    exercise_name: str
    block_title: Optional[str] = None
    set_number: int = Field(default=1, ge=1, le=20)
    reps: Optional[int] = Field(default=None, ge=0, le=999)
    weight_kg: Optional[float] = Field(default=None, ge=0, le=500)
    duration_seconds: Optional[int] = Field(default=None, ge=0)
    notes: Optional[str] = None


class ExerciseLogRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    day_iso_date: str
    exercise_name: str
    set_number: int
    reps: Optional[int] = None
    weight_kg: Optional[float] = None
    duration_seconds: Optional[int] = None
    notes: Optional[str] = None
    logged_at: datetime
