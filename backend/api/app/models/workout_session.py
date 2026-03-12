from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class WorkoutSession(Base):
    __tablename__ = "workout_sessions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    profile_id: Mapped[int | None] = mapped_column(ForeignKey("user_profiles.id"), index=True, nullable=True)
    session_minutes: Mapped[int] = mapped_column(Integer)
    focus: Mapped[str] = mapped_column(String(120))
    energy_level: Mapped[str] = mapped_column(String(40), default="Media")
    notes: Mapped[str] = mapped_column(Text, default="")
    completed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        index=True,
    )
