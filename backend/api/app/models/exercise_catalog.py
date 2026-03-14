from datetime import datetime
from typing import Optional

from sqlalchemy import Boolean, DateTime, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class ExerciseCatalog(Base):
    __tablename__ = "exercise_catalog"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(160), unique=True, index=True)
    muscle_group: Mapped[str | None] = mapped_column(String(120), nullable=True)
    location: Mapped[str | None] = mapped_column(String(80), nullable=True)
    default_notes: Mapped[str] = mapped_column(Text, default="")
    image_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    substitutions_json: Mapped[str] = mapped_column(Text, default="[]")

    # Multilingual
    name_es: Mapped[Optional[str]] = mapped_column(String(160), nullable=True)
    description_es: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    instructions_es: Mapped[Optional[str]] = mapped_column(Text, default="[]", nullable=True)

    # Muscle targeting
    primary_muscle: Mapped[Optional[str]] = mapped_column(String(120), nullable=True)
    secondary_muscles: Mapped[Optional[str]] = mapped_column(Text, default="[]", nullable=True)

    # Equipment
    equipment_required: Mapped[Optional[str]] = mapped_column(Text, default="[]", nullable=True)
    equipment_alternatives: Mapped[Optional[str]] = mapped_column(Text, default="[]", nullable=True)

    # Classification
    difficulty: Mapped[Optional[str]] = mapped_column(String(32), nullable=True)  # beginner/intermediate/advanced
    category: Mapped[Optional[str]] = mapped_column(String(32), nullable=True)  # strength/cardio/flexibility/balance
    tags: Mapped[Optional[str]] = mapped_column(Text, default="[]", nullable=True)

    # Attributes
    is_unilateral: Mapped[Optional[bool]] = mapped_column(Boolean, default=False, nullable=True)
    estimated_duration_seconds: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)

    # Media
    image_urls: Mapped[Optional[str]] = mapped_column(Text, default="[]", nullable=True)  # JSON array; image_url kept for backward compat
    video_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    thumbnail_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )
