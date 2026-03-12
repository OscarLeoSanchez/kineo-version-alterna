from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class UserProfile(Base):
    __tablename__ = "user_profiles"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), index=True, nullable=True)
    full_name: Mapped[str] = mapped_column(String(120))
    age: Mapped[int] = mapped_column(Integer)
    height_cm: Mapped[int] = mapped_column(Integer)
    weight_kg: Mapped[int] = mapped_column(Integer)
    goal: Mapped[str] = mapped_column(String(80))
    activity_level: Mapped[str] = mapped_column(String(80))
    workout_days_per_week: Mapped[int] = mapped_column(Integer)
    session_minutes: Mapped[int] = mapped_column(Integer)
    training_location: Mapped[str] = mapped_column(String(80), default="Mixto")
    cooking_style: Mapped[str] = mapped_column(String(80), default="Simple")
    meals_per_day: Mapped[int] = mapped_column(Integer, default=4)
    equipment: Mapped[str] = mapped_column(Text)
    dietary_preferences: Mapped[str] = mapped_column(Text)
    allergies: Mapped[str] = mapped_column(Text, default="[]")
    food_dislikes: Mapped[str] = mapped_column(Text, default="[]")
    restrictions: Mapped[str] = mapped_column(Text)
    body_measurements: Mapped[str] = mapped_column(Text, default="{}")
    additional_notes: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )
