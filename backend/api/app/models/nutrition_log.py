from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class NutritionLog(Base):
    __tablename__ = "nutrition_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    profile_id: Mapped[int | None] = mapped_column(ForeignKey("user_profiles.id"), index=True, nullable=True)
    meal_label: Mapped[str] = mapped_column(String(80))
    adherence_score: Mapped[int] = mapped_column(Integer)
    protein_grams: Mapped[int] = mapped_column(Integer, default=0)
    hydration_liters: Mapped[int] = mapped_column(Integer, default=0)
    notes: Mapped[str] = mapped_column(Text, default="")
    logged_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        index=True,
    )
