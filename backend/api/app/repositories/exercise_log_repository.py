from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.exercise_log import ExerciseLog


class ExerciseLogRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def create(self, user_id: int, data: dict) -> ExerciseLog:
        log = ExerciseLog(
            user_id=user_id,
            **{k: v for k, v in data.items() if hasattr(ExerciseLog, k)},
        )
        self.db.add(log)
        self.db.commit()
        self.db.refresh(log)
        return log

    def list_by_day(
        self,
        user_id: int,
        day_iso_date: str,
        exercise_name: str | None = None,
    ) -> list[ExerciseLog]:
        stmt = (
            select(ExerciseLog)
            .where(ExerciseLog.user_id == user_id)
            .where(ExerciseLog.day_iso_date == day_iso_date)
            .order_by(ExerciseLog.logged_at)
        )
        if exercise_name is not None:
            stmt = stmt.where(ExerciseLog.exercise_name == exercise_name)
        return list(self.db.scalars(stmt).all())
