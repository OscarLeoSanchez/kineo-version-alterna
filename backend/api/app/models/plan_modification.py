from datetime import datetime
from typing import Optional

from sqlalchemy import Boolean, DateTime, ForeignKey, Index, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class PlanModification(Base):
    __tablename__ = "plan_modifications"
    __table_args__ = (
        Index("ix_plan_modifications_user_id", "user_id"),
        Index("ix_plan_modifications_is_active", "is_active"),
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
    modification_type: Mapped[str] = mapped_column(String(32), nullable=False)
    # exclude / swap / edit_params / add_note
    target_type: Mapped[str] = mapped_column(String(32), default="exercise", nullable=False)
    # exercise / meal
    target_day_label: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    target_block_title: Mapped[Optional[str]] = mapped_column(String(120), nullable=True)
    target_item_name: Mapped[Optional[str]] = mapped_column(String(240), nullable=True)
    replacement_item_name: Mapped[Optional[str]] = mapped_column(String(240), nullable=True)
    override_json: Mapped[str] = mapped_column(Text, default="{}", nullable=False)
    note_text: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )
