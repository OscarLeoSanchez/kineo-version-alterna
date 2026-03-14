import json
from datetime import UTC, date, datetime, timedelta

from sqlalchemy import delete, func, select
from sqlalchemy.orm import Session

from app.ai.planning_models import GeneratedProgram
from app.models.body_metric import BodyMetric
from app.models.exercise_catalog import ExerciseCatalog
from app.models.nutrition_log import NutritionLog
from app.models.workout_block_completion import WorkoutBlockCompletion
from app.models.workout_exercise_selection import WorkoutExerciseSelection
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
        target_day = payload.day_iso_date or self._today_iso()
        record = self.latest_workout_for_day(user_id=user_id, day_iso_date=target_day)
        if record is None:
            record = WorkoutSession(
                user_id=user_id,
                profile_id=profile_id,
                plan_id=payload.plan_id,
                day_iso_date=target_day,
                session_minutes=payload.session_minutes,
                focus=payload.focus,
                energy_level=payload.energy_level,
                notes=payload.notes,
            )
            self.db.add(record)
        else:
            record.profile_id = profile_id
            record.plan_id = payload.plan_id
            record.day_iso_date = target_day
            record.session_minutes = payload.session_minutes
            record.focus = payload.focus
            record.energy_level = payload.energy_level
            record.notes = payload.notes

        self._upsert_block_states(
            user_id=user_id,
            plan_id=payload.plan_id,
            day_iso_date=target_day,
            block_states=payload.block_states,
        )
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
        record.plan_id = payload.plan_id
        record.day_iso_date = payload.day_iso_date or record.day_iso_date or self._today_iso()
        record.session_minutes = payload.session_minutes
        record.focus = payload.focus
        record.energy_level = payload.energy_level
        record.notes = payload.notes
        self._upsert_block_states(
            user_id=user_id,
            plan_id=payload.plan_id,
            day_iso_date=record.day_iso_date or self._today_iso(),
            block_states=payload.block_states,
        )
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

    def save_block_state(
        self,
        *,
        user_id: int,
        plan_id: int | None,
        day_iso_date: str,
        block_title: str,
        completed: bool,
        selected_exercises: list[str],
    ) -> None:
        statement = select(WorkoutBlockCompletion).where(
            WorkoutBlockCompletion.user_id == user_id,
            WorkoutBlockCompletion.plan_id == plan_id,
            WorkoutBlockCompletion.day_iso_date == day_iso_date,
            WorkoutBlockCompletion.block_title == block_title,
        )
        record = self.db.scalar(statement)
        if record is None:
            record = WorkoutBlockCompletion(
                user_id=user_id,
                plan_id=plan_id,
                day_iso_date=day_iso_date,
                block_title=block_title,
                completed=completed,
            )
            self.db.add(record)
        else:
            record.completed = completed

        self.db.execute(
            delete(WorkoutExerciseSelection).where(
                WorkoutExerciseSelection.user_id == user_id,
                WorkoutExerciseSelection.plan_id == plan_id,
                WorkoutExerciseSelection.day_iso_date == day_iso_date,
                WorkoutExerciseSelection.block_title == block_title,
            )
        )
        for exercise_name in selected_exercises:
            self.db.add(
                WorkoutExerciseSelection(
                    user_id=user_id,
                    plan_id=plan_id,
                    day_iso_date=day_iso_date,
                    block_title=block_title,
                    exercise_name=exercise_name,
                    source_type="selected",
                    selected=True,
                )
            )
        self.db.commit()

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

    def sync_exercise_catalog(self, *, program: GeneratedProgram | None) -> None:
        if program is None:
            return
        known = {item.name: item for item in self.db.scalars(select(ExerciseCatalog)).all()}
        for workout in program.weekly_workouts:
            for block in workout.blocks:
                for exercise in block.exercises:
                    substitutions = [item for item in exercise.substitutions if item]
                    record = known.get(exercise.name)
                    if record is None:
                        record = ExerciseCatalog(name=exercise.name)
                        self.db.add(record)
                        known[exercise.name] = record
                    record.muscle_group = exercise.muscle_group
                    record.location = exercise.location
                    record.default_notes = exercise.notes
                    record.image_url = exercise.image_url
                    record.substitutions_json = json.dumps(substitutions)
                    for replacement in substitutions:
                        replacement_record = known.get(replacement)
                        if replacement_record is None:
                            replacement_record = ExerciseCatalog(
                                name=replacement,
                                muscle_group=exercise.muscle_group,
                                location=exercise.location,
                                default_notes=f"Alternativa sugerida para {exercise.name}",
                                image_url=exercise.image_url,
                                substitutions_json="[]",
                            )
                            self.db.add(replacement_record)
                            known[replacement] = replacement_record
        self.db.commit()

    def block_state_map(
        self,
        *,
        user_id: int,
        plan_id: int | None,
        day_iso_date: str,
    ) -> dict[str, dict[str, object]]:
        completions = self.db.scalars(
            select(WorkoutBlockCompletion).where(
                WorkoutBlockCompletion.user_id == user_id,
                WorkoutBlockCompletion.plan_id == plan_id,
                WorkoutBlockCompletion.day_iso_date == day_iso_date,
            )
        ).all()
        selections = self.db.scalars(
            select(WorkoutExerciseSelection).where(
                WorkoutExerciseSelection.user_id == user_id,
                WorkoutExerciseSelection.plan_id == plan_id,
                WorkoutExerciseSelection.day_iso_date == day_iso_date,
                WorkoutExerciseSelection.selected.is_(True),
            )
        ).all()
        selected_by_block: dict[str, list[str]] = {}
        for item in selections:
            selected_by_block.setdefault(item.block_title, []).append(item.exercise_name)
        return {
            item.block_title: {
                "completed": item.completed,
                "selected_exercises": selected_by_block.get(item.block_title, []),
            }
            for item in completions
        }

    def exercise_catalog_map(self) -> dict[str, ExerciseCatalog]:
        return {item.name: item for item in self.db.scalars(select(ExerciseCatalog)).all()}

    def workout_count(self, *, user_id: int, days: int | None = None) -> int:
        statement = select(func.count(WorkoutSession.id)).where(WorkoutSession.user_id == user_id)
        if days is not None:
            statement = statement.where(WorkoutSession.completed_at >= self._window_start(days))
        return int(self.db.scalar(statement) or 0)

    def workout_completed_today(self, *, user_id: int) -> bool:
        return self.workout_count(user_id=user_id, days=1) > 0

    def latest_workout_today(self, *, user_id: int) -> WorkoutSession | None:
        return self.latest_workout_for_day(user_id=user_id, day_iso_date=self._today_iso())

    def latest_workout_for_day(self, *, user_id: int, day_iso_date: str) -> WorkoutSession | None:
        statement = (
            select(WorkoutSession)
            .where(
                WorkoutSession.user_id == user_id,
                WorkoutSession.day_iso_date == day_iso_date,
            )
            .order_by(WorkoutSession.completed_at.desc(), WorkoutSession.id.desc())
            .limit(1)
        )
        record = self.db.scalar(statement)
        if record is not None:
            return record
        day_start = datetime.fromisoformat(day_iso_date).replace(tzinfo=UTC)
        statement = (
            select(WorkoutSession)
            .where(
                WorkoutSession.user_id == user_id,
                WorkoutSession.completed_at >= day_start,
                WorkoutSession.completed_at < day_start + timedelta(days=1),
            )
            .order_by(WorkoutSession.completed_at.desc(), WorkoutSession.id.desc())
            .limit(1)
        )
        return self.db.scalar(statement)

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

    def filter_body_metrics(self, *, user_id: int, limit: int = 20) -> list[BodyMetric]:
        return self.recent_body_metrics(user_id=user_id, limit=limit)

    def daily_workout_counts_for_range(self, *, user_id: int, start_date: date, end_date: date) -> dict[str, int]:
        statement = select(WorkoutSession).where(WorkoutSession.user_id == user_id)
        records = self.db.scalars(statement).all()
        counts: dict[str, int] = {}
        for record in records:
            iso_key = record.day_iso_date or self._date_key(record.completed_at)
            record_date = date.fromisoformat(iso_key)
            if record_date < start_date or record_date > end_date:
                continue
            counts[iso_key] = counts.get(iso_key, 0) + 1
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

    def weekly_workout_calendar(
        self,
        *,
        user_id: int,
        target_per_week: int,
        start_date: date | None = None,
    ) -> list[dict[str, int | str | bool]]:
        anchor = start_date or datetime.now(UTC).date() - timedelta(days=6)
        end_date = anchor + timedelta(days=6)
        counts = self.daily_workout_counts_for_range(
            user_id=user_id,
            start_date=anchor,
            end_date=end_date,
        )
        today = datetime.now(UTC).date()
        calendar: list[dict[str, int | str | bool]] = []
        for offset in range(7):
            date_value = anchor + timedelta(days=offset)
            key = date_value.isoformat()
            completed = counts.get(key, 0)
            calendar.append(
                {
                    "label": date_value.strftime("%a"),
                    "date": date_value.strftime("%d/%m"),
                    "iso_date": key,
                    "weekday_index": offset,
                    "completed_sessions": completed,
                    "goal_hit": completed > 0,
                    "is_today": date_value == today,
                    "is_past": date_value < today,
                    "is_available": date_value <= today,
                    "target_hint": target_per_week,
                }
            )
        return calendar

    def _upsert_block_states(
        self,
        *,
        user_id: int,
        plan_id: int | None,
        day_iso_date: str,
        block_states: list,
    ) -> None:
        for item in block_states:
            self.save_block_state(
                user_id=user_id,
                plan_id=plan_id,
                day_iso_date=day_iso_date,
                block_title=item.block_title,
                completed=item.completed,
                selected_exercises=item.selected_exercises,
            )

    @staticmethod
    def _window_start(days: int) -> datetime:
        return datetime.now(UTC) - timedelta(days=days)

    @staticmethod
    def _date_key(value: datetime) -> str:
        return ActivityRepository._coerce_utc(value).date().isoformat()

    @staticmethod
    def _coerce_utc(value: datetime) -> datetime:
        return value.astimezone(UTC) if value.tzinfo else value.replace(tzinfo=UTC)

    @staticmethod
    def _today_iso() -> str:
        return datetime.now(UTC).date().isoformat()
