from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class WeeklyGoal(Base):
    __tablename__ = "weekly_goals"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True, unique=True)
    workout_sessions_target: Mapped[int] = mapped_column(Integer, default=4)
    nutrition_adherence_target: Mapped[int] = mapped_column(Integer, default=85)
    weight_checkins_target: Mapped[int] = mapped_column(Integer, default=2)
    reminders_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    reminder_time: Mapped[str] = mapped_column(String(5), default="07:00")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )
