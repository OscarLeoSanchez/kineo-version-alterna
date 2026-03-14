from typing import Any

from pydantic import BaseModel


class WorkoutSummaryRead(BaseModel):
    title: str
    duration_minutes: int
    focus: str
    energy_level: str
    blocks: list[dict[str, Any]]
    sos_hint: str
    completed_sessions: int
    completed_today: bool
    selected_day_index: int
    plan_id: int | None = None
    weekly_calendar: list[dict[str, int | str | bool]]
    weekly_days: list[dict[str, Any]]


class NutritionSummaryRead(BaseModel):
    title: str
    calorie_target: str
    macro_focus: list[str]
    meals: list[dict[str, Any]]
    swap_tip: str
    adherence_score: int
    selected_day_index: int
    plan_id: int | None = None
    weekly_days: list[dict[str, Any]]


class NutritionPhotoAnalysisRead(BaseModel):
    meal_label: str
    detected_dish_name: str
    estimated_calories_kcal: int
    estimated_protein_g: float
    estimated_carbs_g: float
    estimated_fat_g: float
    estimated_fiber_g: float = 0.0
    confidence_note: str
    detected_items: list[str]
    ingredients: list[str] = []
    serving_hint: str
    coach_note: str


class ProgressSummaryRead(BaseModel):
    streak_days: int
    weekly_adherence: int
    weight_trend: str
    completed_sessions: int
    latest_weight_kg: float | None = None
    weekly_workout_target: int
    workout_completion_rate: int
    weight_series: list[dict[str, float | str]]
    adherence_series: list[dict[str, int | str]]
    insights: list[dict[str, Any]]
