from datetime import datetime

from pydantic import AliasChoices, BaseModel, Field


class UserPreferencesRead(BaseModel):
    coaching_style: str
    units: str
    reminders_enabled: bool
    experience_mode: str = Field(
        validation_alias=AliasChoices("experience_mode", "membership_plan"),
        serialization_alias="experience_mode",
    )
    daily_priority: str
    recommendation_depth: str
    proactive_adjustments: bool
    updated_at: datetime | None = None

    model_config = {"from_attributes": True}


class UserPreferencesUpdate(BaseModel):
    coaching_style: str = Field(min_length=3, max_length=32)
    units: str = Field(min_length=3, max_length=32)
    reminders_enabled: bool
    experience_mode: str = Field(
        min_length=3,
        max_length=32,
        validation_alias=AliasChoices("experience_mode", "membership_plan"),
        serialization_alias="experience_mode",
    )
    daily_priority: str = Field(min_length=3, max_length=32)
    recommendation_depth: str = Field(min_length=3, max_length=32)
    proactive_adjustments: bool
