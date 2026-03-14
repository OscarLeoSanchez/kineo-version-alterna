from datetime import datetime
from typing import Any

from pydantic import BaseModel


class InitialPlanRead(BaseModel):
    id: int
    profile_id: int
    workout_focus: str
    workout_summary: str
    nutrition_summary: str
    habits_summary: str
    plan_payload: dict[str, Any] | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class PlanHistoryItemRead(BaseModel):
    id: int
    profile_id: int
    workout_focus: str
    created_at: datetime
    week_label: str
    is_current: bool = False
