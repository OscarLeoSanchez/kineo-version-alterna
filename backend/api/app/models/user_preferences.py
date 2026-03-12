from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class UserPreferences(Base):
    __tablename__ = "user_preferences"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        index=True,
    )
    coaching_style: Mapped[str] = mapped_column(String(32), default="Equilibrado")
    units: Mapped[str] = mapped_column(String(32), default="Metricas")
    reminders_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    experience_mode: Mapped[str] = mapped_column(
        "membership_plan",
        String(32),
        default="Full",
    )
    daily_priority: Mapped[str] = mapped_column(String(32), default="Adherencia")
    recommendation_depth: Mapped[str] = mapped_column(String(32), default="Profunda")
    proactive_adjustments: Mapped[bool] = mapped_column(Boolean, default=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )
