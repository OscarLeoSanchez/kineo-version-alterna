from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, ForeignKey, Index, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from app.db.base import Base


class ExerciseSubstitution(Base):
    __tablename__ = "exercise_substitutions"
    __table_args__ = (
        UniqueConstraint("exercise_id", "substitute_id"),
        Index("ix_exercise_substitutions_exercise_id", "exercise_id"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    exercise_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("exercise_catalog.id", ondelete="CASCADE"),
        nullable=False,
    )
    substitute_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("exercise_catalog.id", ondelete="CASCADE"),
        nullable=False,
    )
    reason: Mapped[Optional[str]] = mapped_column(String(60), nullable=True)
    # reason values: same_muscle / equipment_alt / difficulty_regression / difficulty_progression
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )
