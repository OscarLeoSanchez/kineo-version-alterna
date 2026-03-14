from pydantic import BaseModel, ConfigDict
from typing import Optional, Literal
from datetime import datetime


class PlanModificationCreate(BaseModel):
    modification_type: Literal["exclude", "swap", "edit_params", "add_note"]
    target_type: Literal["exercise", "meal"] = "exercise"
    target_day_label: Optional[str] = None
    target_block_title: Optional[str] = None
    target_item_name: str
    replacement_item_name: Optional[str] = None
    override_json: str = "{}"
    note_text: Optional[str] = None


class PlanModificationRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    plan_id: Optional[int] = None
    modification_type: str
    target_type: str
    target_day_label: Optional[str] = None
    target_block_title: Optional[str] = None
    target_item_name: Optional[str] = None
    replacement_item_name: Optional[str] = None
    override_json: str = "{}"
    note_text: Optional[str] = None
    is_active: bool = True
    created_at: datetime
