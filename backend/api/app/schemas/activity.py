from datetime import datetime

from pydantic import BaseModel, Field


class WorkoutSessionCreate(BaseModel):
    session_minutes: int = Field(ge=10, le=240)
    focus: str = Field(min_length=3, max_length=120)
    energy_level: str = Field(default="Media", min_length=3, max_length=40)
    notes: str = Field(default="", max_length=280)


class NutritionLogCreate(BaseModel):
    meal_label: str = Field(min_length=2, max_length=80)
    adherence_score: int = Field(ge=0, le=100)
    protein_grams: int = Field(default=0, ge=0, le=300)
    hydration_liters: int = Field(default=0, ge=0, le=12)
    notes: str = Field(default="", max_length=280)


class BodyMetricCreate(BaseModel):
    weight_kg: float = Field(ge=30, le=300)
    waist_cm: float | None = Field(default=None, ge=40, le=250)
    body_fat_percentage: float | None = Field(default=None, ge=3, le=70)
    hip_cm: float | None = Field(default=None, ge=40, le=250)
    chest_cm: float | None = Field(default=None, ge=40, le=250)
    arm_cm: float | None = Field(default=None, ge=15, le=80)
    thigh_cm: float | None = Field(default=None, ge=20, le=120)
    sleep_hours: float | None = Field(default=None, ge=0, le=24)
    steps: int | None = Field(default=None, ge=0, le=100000)
    resting_heart_rate: int | None = Field(default=None, ge=30, le=220)


class ActivityLogRead(BaseModel):
    id: int
    message: str
    created_at: datetime


class ActivityDeleteRead(BaseModel):
    message: str


class WorkoutSessionHistoryItem(BaseModel):
    id: int
    focus: str
    session_minutes: int
    energy_level: str
    notes: str
    completed_at: datetime

    model_config = {"from_attributes": True}


class NutritionHistoryItem(BaseModel):
    id: int
    meal_label: str
    adherence_score: int
    protein_grams: int
    hydration_liters: int
    notes: str
    logged_at: datetime

    model_config = {"from_attributes": True}


class BodyMetricHistoryItem(BaseModel):
    id: int
    weight_kg: float
    waist_cm: float | None = None
    body_fat_percentage: float | None = None
    hip_cm: float | None = None
    chest_cm: float | None = None
    arm_cm: float | None = None
    thigh_cm: float | None = None
    sleep_hours: float | None = None
    steps: int | None = None
    resting_heart_rate: int | None = None
    recorded_at: datetime

    model_config = {"from_attributes": True}


class ActivityHistoryRead(BaseModel):
    workouts: list[WorkoutSessionHistoryItem]
    nutrition_logs: list[NutritionHistoryItem]
    body_metrics: list[BodyMetricHistoryItem]


class ActivityFilterRead(ActivityHistoryRead):
    filter_type: str = "all"
    limit: int = 8
