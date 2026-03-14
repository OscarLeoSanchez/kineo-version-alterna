from pydantic import BaseModel, ConfigDict
from typing import Optional
import json


class ExerciseCatalogRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    name_es: Optional[str] = None
    description_es: Optional[str] = None
    muscle_group: Optional[str] = None
    primary_muscle: Optional[str] = None
    location: Optional[str] = None
    difficulty: Optional[str] = None
    category: Optional[str] = None
    is_unilateral: Optional[bool] = False
    estimated_duration_seconds: Optional[int] = None
    image_url: Optional[str] = None  # backward compat
    thumbnail_url: Optional[str] = None
    video_url: Optional[str] = None
    # JSON array fields — returned as parsed lists
    secondary_muscles: list[str] = []
    equipment_required: list[str] = []
    equipment_alternatives: list[str] = []
    instructions_es: list[str] = []
    image_urls: list[str] = []
    tags: list[str] = []

    @classmethod
    def from_orm_safe(cls, obj):
        """Parse JSON string fields into lists."""
        data = {}
        for field in [
            "secondary_muscles",
            "equipment_required",
            "equipment_alternatives",
            "instructions_es",
            "image_urls",
            "tags",
        ]:
            raw = getattr(obj, field, None)
            try:
                data[field] = json.loads(raw) if raw else []
            except Exception:
                data[field] = []
        # Copy scalar fields
        for field in [
            "id",
            "name",
            "name_es",
            "description_es",
            "muscle_group",
            "primary_muscle",
            "location",
            "difficulty",
            "category",
            "is_unilateral",
            "estimated_duration_seconds",
            "image_url",
            "thumbnail_url",
            "video_url",
        ]:
            data[field] = getattr(obj, field, None)
        return cls(**data)


class ExerciseCatalogSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    name_es: Optional[str] = None
    muscle_group: Optional[str] = None
    difficulty: Optional[str] = None
    thumbnail_url: Optional[str] = None
    equipment_required: list[str] = []

    @classmethod
    def from_orm_safe(cls, obj):
        """Parse JSON string fields into lists."""
        data = {}
        raw = getattr(obj, "equipment_required", None)
        try:
            data["equipment_required"] = json.loads(raw) if raw else []
        except Exception:
            data["equipment_required"] = []
        for field in ["id", "name", "name_es", "muscle_group", "difficulty", "thumbnail_url"]:
            data[field] = getattr(obj, field, None)
        return cls(**data)


class ExerciseSubstituteRead(ExerciseCatalogSummary):
    reason: Optional[str] = None  # added by substitution query
