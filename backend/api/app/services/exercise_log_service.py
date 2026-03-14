from sqlalchemy.orm import Session

from app.repositories.exercise_log_repository import ExerciseLogRepository


class ExerciseLogService:
    def __init__(self, db: Session) -> None:
        self.repo = ExerciseLogRepository(db)

    def log_set(self, user_id: int, data: dict):
        return self.repo.create(user_id, data)

    def get_day_logs(self, user_id: int, day_iso_date: str, exercise_name: str | None = None):
        return self.repo.list_by_day(user_id, day_iso_date, exercise_name)
