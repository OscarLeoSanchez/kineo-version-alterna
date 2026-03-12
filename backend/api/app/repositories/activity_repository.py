from datetime import UTC, datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.body_metric import BodyMetric
from app.models.nutrition_log import NutritionLog
from app.models.workout_session import WorkoutSession
from app.schemas.activity import BodyMetricCreate, NutritionLogCreate, WorkoutSessionCreate


class ActivityRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def log_workout(
        self,
        *,
        user_id: int,
        profile_id: int | None,
        payload: WorkoutSessionCreate,
    ) -> WorkoutSession:
        record = WorkoutSession(
            user_id=user_id,
            profile_id=profile_id,
            session_minutes=payload.session_minutes,
            focus=payload.focus,
            energy_level=payload.energy_level,
            notes=payload.notes,
        )
        self.db.add(record)
        self.db.commit()
        self.db.refresh(record)
        return record

    def update_workout(
        self,
        *,
        user_id: int,
        workout_id: int,
        payload: WorkoutSessionCreate,
    ) -> WorkoutSession | None:
        record = self.db.get(WorkoutSession, workout_id)
        if record is None or record.user_id != user_id:
            return None
        record.session_minutes = payload.session_minutes
        record.focus = payload.focus
        record.energy_level = payload.energy_level
        record.notes = payload.notes
        self.db.commit()
        self.db.refresh(record)
        return record

    def delete_workout(self, *, user_id: int, workout_id: int) -> bool:
        record = self.db.get(WorkoutSession, workout_id)
        if record is None or record.user_id != user_id:
            return False
        self.db.delete(record)
        self.db.commit()
        return True

    def log_nutrition(
        self,
        *,
        user_id: int,
        profile_id: int | None,
        payload: NutritionLogCreate,
    ) -> NutritionLog:
        record = NutritionLog(
            user_id=user_id,
            profile_id=profile_id,
            meal_label=payload.meal_label,
            adherence_score=payload.adherence_score,
            protein_grams=payload.protein_grams,
            hydration_liters=payload.hydration_liters,
            notes=payload.notes,
        )
        self.db.add(record)
        self.db.commit()
        self.db.refresh(record)
        return record

    def update_nutrition(
        self,
        *,
        user_id: int,
        nutrition_id: int,
        payload: NutritionLogCreate,
    ) -> NutritionLog | None:
        record = self.db.get(NutritionLog, nutrition_id)
        if record is None or record.user_id != user_id:
            return None
        record.meal_label = payload.meal_label
        record.adherence_score = payload.adherence_score
        record.protein_grams = payload.protein_grams
        record.hydration_liters = payload.hydration_liters
        record.notes = payload.notes
        self.db.commit()
        self.db.refresh(record)
        return record

    def delete_nutrition(self, *, user_id: int, nutrition_id: int) -> bool:
        record = self.db.get(NutritionLog, nutrition_id)
        if record is None or record.user_id != user_id:
            return False
        self.db.delete(record)
        self.db.commit()
        return True

    def log_body_metric(
        self,
        *,
        user_id: int,
        profile_id: int | None,
        payload: BodyMetricCreate,
    ) -> BodyMetric:
        record = BodyMetric(
            user_id=user_id,
            profile_id=profile_id,
            weight_kg=payload.weight_kg,
            waist_cm=payload.waist_cm,
            body_fat_percentage=payload.body_fat_percentage,
            hip_cm=payload.hip_cm,
            chest_cm=payload.chest_cm,
            arm_cm=payload.arm_cm,
            thigh_cm=payload.thigh_cm,
            sleep_hours=payload.sleep_hours,
            steps=payload.steps,
            resting_heart_rate=payload.resting_heart_rate,
        )
        self.db.add(record)
        self.db.commit()
        self.db.refresh(record)
        return record

    def update_body_metric(
        self,
        *,
        user_id: int,
        metric_id: int,
        payload: BodyMetricCreate,
    ) -> BodyMetric | None:
        record = self.db.get(BodyMetric, metric_id)
        if record is None or record.user_id != user_id:
            return None
        record.weight_kg = payload.weight_kg
        record.waist_cm = payload.waist_cm
        record.body_fat_percentage = payload.body_fat_percentage
        record.hip_cm = payload.hip_cm
        record.chest_cm = payload.chest_cm
        record.arm_cm = payload.arm_cm
        record.thigh_cm = payload.thigh_cm
        record.sleep_hours = payload.sleep_hours
        record.steps = payload.steps
        record.resting_heart_rate = payload.resting_heart_rate
        self.db.commit()
        self.db.refresh(record)
        return record

    def delete_body_metric(self, *, user_id: int, metric_id: int) -> bool:
        record = self.db.get(BodyMetric, metric_id)
        if record is None or record.user_id != user_id:
            return False
        self.db.delete(record)
        self.db.commit()
        return True

    def workout_count(self, *, user_id: int, days: int | None = None) -> int:
        statement = select(func.count(WorkoutSession.id)).where(WorkoutSession.user_id == user_id)
        if days is not None:
            statement = statement.where(WorkoutSession.completed_at >= self._window_start(days))
        return int(self.db.scalar(statement) or 0)

    def workout_completed_today(self, *, user_id: int) -> bool:
        return self.workout_count(user_id=user_id, days=1) > 0

    def nutrition_average(self, *, user_id: int, days: int = 7) -> int:
        statement = select(func.avg(NutritionLog.adherence_score)).where(
            NutritionLog.user_id == user_id,
            NutritionLog.logged_at >= self._window_start(days),
        )
        average = self.db.scalar(statement)
        return int(round(float(average))) if average is not None else 0

    def latest_body_metric(self, *, user_id: int) -> BodyMetric | None:
        statement = (
            select(BodyMetric)
            .where(BodyMetric.user_id == user_id)
            .order_by(BodyMetric.recorded_at.desc(), BodyMetric.id.desc())
            .limit(1)
        )
        return self.db.scalar(statement)

    def first_body_metric(self, *, user_id: int) -> BodyMetric | None:
        statement = (
            select(BodyMetric)
            .where(BodyMetric.user_id == user_id)
            .order_by(BodyMetric.recorded_at.asc(), BodyMetric.id.asc())
            .limit(1)
        )
        return self.db.scalar(statement)

    def workout_streak_days(self, *, user_id: int) -> int:
        statement = (
            select(WorkoutSession.completed_at)
            .where(WorkoutSession.user_id == user_id)
            .order_by(WorkoutSession.completed_at.desc())
        )
        timestamps = self.db.scalars(statement).all()
        if not timestamps:
            return 0

        completed_days = {
            timestamp.astimezone(UTC).date() if timestamp.tzinfo else timestamp.date()
            for timestamp in timestamps
        }
        streak = 0
        cursor = datetime.now(UTC).date()
        while cursor in completed_days:
            streak += 1
            cursor -= timedelta(days=1)
        return streak

    def recent_workouts(self, *, user_id: int, limit: int = 8) -> list[WorkoutSession]:
        statement = (
            select(WorkoutSession)
            .where(WorkoutSession.user_id == user_id)
            .order_by(WorkoutSession.completed_at.desc(), WorkoutSession.id.desc())
            .limit(limit)
        )
        return list(self.db.scalars(statement).all())

    def filter_workouts(
        self,
        *,
        user_id: int,
        limit: int = 20,
        energy_level: str | None = None,
    ) -> list[WorkoutSession]:
        statement = (
            select(WorkoutSession)
            .where(WorkoutSession.user_id == user_id)
            .order_by(WorkoutSession.completed_at.desc(), WorkoutSession.id.desc())
            .limit(limit)
        )
        if energy_level:
            statement = statement.where(WorkoutSession.energy_level == energy_level)
        return list(self.db.scalars(statement).all())

    def recent_nutrition_logs(self, *, user_id: int, limit: int = 8) -> list[NutritionLog]:
        statement = (
            select(NutritionLog)
            .where(NutritionLog.user_id == user_id)
            .order_by(NutritionLog.logged_at.desc(), NutritionLog.id.desc())
            .limit(limit)
        )
        return list(self.db.scalars(statement).all())

    def filter_nutrition_logs(
        self,
        *,
        user_id: int,
        limit: int = 20,
        minimum_score: int | None = None,
    ) -> list[NutritionLog]:
        statement = (
            select(NutritionLog)
            .where(NutritionLog.user_id == user_id)
            .order_by(NutritionLog.logged_at.desc(), NutritionLog.id.desc())
            .limit(limit)
        )
        if minimum_score is not None:
            statement = statement.where(NutritionLog.adherence_score >= minimum_score)
        return list(self.db.scalars(statement).all())

    def recent_body_metrics(self, *, user_id: int, limit: int = 8) -> list[BodyMetric]:
        statement = (
            select(BodyMetric)
            .where(BodyMetric.user_id == user_id)
            .order_by(BodyMetric.recorded_at.desc(), BodyMetric.id.desc())
            .limit(limit)
        )
        return list(self.db.scalars(statement).all())

    def filter_body_metrics(
        self,
        *,
        user_id: int,
        limit: int = 20,
    ) -> list[BodyMetric]:
        return self.recent_body_metrics(user_id=user_id, limit=limit)

    def daily_workout_counts(self, *, user_id: int, days: int = 7) -> dict[str, int]:
        records = self.recent_workouts(user_id=user_id, limit=days * 4)
        counts: dict[str, int] = {}
        cutoff = self._window_start(days)
        for record in records:
            if self._coerce_utc(record.completed_at) < cutoff:
                continue
            key = self._date_key(record.completed_at)
            counts[key] = counts.get(key, 0) + 1
        return counts

    def daily_nutrition_average(self, *, user_id: int, days: int = 7) -> dict[str, int]:
        records = self.recent_nutrition_logs(user_id=user_id, limit=days * 4)
        cutoff = self._window_start(days)
        bucket: dict[str, list[int]] = {}
        for record in records:
            if self._coerce_utc(record.logged_at) < cutoff:
                continue
            key = self._date_key(record.logged_at)
            bucket.setdefault(key, []).append(record.adherence_score)
        return {
            key: int(round(sum(values) / len(values)))
            for key, values in bucket.items()
        }

    def weight_series(self, *, user_id: int, limit: int = 6) -> list[BodyMetric]:
        statement = (
            select(BodyMetric)
            .where(BodyMetric.user_id == user_id)
            .order_by(BodyMetric.recorded_at.asc(), BodyMetric.id.asc())
        )
        records = list(self.db.scalars(statement).all())
        return records[-limit:]

    def weekly_workout_calendar(self, *, user_id: int, target_per_week: int) -> list[dict[str, int | str | bool]]:
        counts = self.daily_workout_counts(user_id=user_id, days=7)
        today = datetime.now(UTC).date()
        calendar: list[dict[str, int | str | bool]] = []
        for offset in range(6, -1, -1):
            date_value = today - timedelta(days=offset)
            key = date_value.isoformat()
            completed = counts.get(key, 0)
            calendar.append(
                {
                    "label": date_value.strftime("%a"),
                    "date": date_value.strftime("%d/%m"),
                    "completed_sessions": completed,
                    "goal_hit": completed > 0,
                    "target_hint": target_per_week,
                }
            )
        return calendar

    @staticmethod
    def _window_start(days: int) -> datetime:
        return datetime.now(UTC) - timedelta(days=days)

    @staticmethod
    def _date_key(value: datetime) -> str:
        return ActivityRepository._coerce_utc(value).date().isoformat()

    @staticmethod
    def _coerce_utc(value: datetime) -> datetime:
        return value.astimezone(UTC) if value.tzinfo else value.replace(tzinfo=UTC)
