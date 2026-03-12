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
    weekly_calendar: list[dict[str, int | str | bool]]


class NutritionSummaryRead(BaseModel):
    title: str
    calorie_target: str
    macro_focus: list[str]
    meals: list[dict[str, Any]]
    swap_tip: str
    adherence_score: int


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
