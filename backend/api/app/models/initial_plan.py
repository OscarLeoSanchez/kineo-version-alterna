from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class InitialPlan(Base):
    __tablename__ = "initial_plans"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), index=True, nullable=True)
    profile_id: Mapped[int] = mapped_column(Integer, unique=True, index=True)
    workout_focus: Mapped[str] = mapped_column(String(120))
    workout_summary: Mapped[str] = mapped_column(Text)
    nutrition_summary: Mapped[str] = mapped_column(Text)
    habits_summary: Mapped[str] = mapped_column(Text)
    plan_payload: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )
