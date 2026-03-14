from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, Float, ForeignKey, Index, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class ExerciseLog(Base):
    __tablename__ = "exercise_logs"
    __table_args__ = (
        Index("ix_exercise_logs_user_day", "user_id", "day_iso_date"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    plan_id: Mapped[Optional[int]] = mapped_column(
        Integer,
        ForeignKey("initial_plans.id", ondelete="SET NULL"),
        nullable=True,
    )
    day_iso_date: Mapped[str] = mapped_column(String(10), nullable=False)  # "2026-03-13"
    exercise_name: Mapped[str] = mapped_column(String(240), nullable=False)
    exercise_catalog_id: Mapped[Optional[int]] = mapped_column(
        Integer,
        ForeignKey("exercise_catalog.id", ondelete="SET NULL"),
        nullable=True,
    )
    block_title: Mapped[Optional[str]] = mapped_column(String(120), nullable=True)
    set_number: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    reps: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    weight_kg: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    duration_seconds: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    logged_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )
