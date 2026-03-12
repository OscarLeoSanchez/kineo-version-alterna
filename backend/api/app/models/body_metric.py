from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, Integer, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class BodyMetric(Base):
    __tablename__ = "body_metrics"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    profile_id: Mapped[int | None] = mapped_column(ForeignKey("user_profiles.id"), index=True, nullable=True)
    weight_kg: Mapped[float] = mapped_column(Float)
    waist_cm: Mapped[float | None] = mapped_column(Float, nullable=True)
    body_fat_percentage: Mapped[float | None] = mapped_column(Float, nullable=True)
    hip_cm: Mapped[float | None] = mapped_column(Float, nullable=True)
    chest_cm: Mapped[float | None] = mapped_column(Float, nullable=True)
    arm_cm: Mapped[float | None] = mapped_column(Float, nullable=True)
    thigh_cm: Mapped[float | None] = mapped_column(Float, nullable=True)
    sleep_hours: Mapped[float | None] = mapped_column(Float, nullable=True)
    steps: Mapped[int | None] = mapped_column(Integer, nullable=True)
    resting_heart_rate: Mapped[int | None] = mapped_column(Integer, nullable=True)
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        index=True,
    )
