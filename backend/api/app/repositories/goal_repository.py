from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.weekly_goal import WeeklyGoal
from app.schemas.goals import WeeklyGoalUpsert


class GoalRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_for_user(self, user_id: int) -> WeeklyGoal | None:
        statement = select(WeeklyGoal).where(WeeklyGoal.user_id == user_id)
        return self.db.scalar(statement)

    def upsert_for_user(self, *, user_id: int, payload: WeeklyGoalUpsert) -> WeeklyGoal:
        goal = self.get_for_user(user_id)
        if goal is None:
            goal = WeeklyGoal(
                user_id=user_id,
                workout_sessions_target=payload.workout_sessions_target,
                nutrition_adherence_target=payload.nutrition_adherence_target,
                weight_checkins_target=payload.weight_checkins_target,
                reminders_enabled=payload.reminders_enabled,
                reminder_time=payload.reminder_time,
            )
            self.db.add(goal)
        else:
            goal.workout_sessions_target = payload.workout_sessions_target
            goal.nutrition_adherence_target = payload.nutrition_adherence_target
            goal.weight_checkins_target = payload.weight_checkins_target
            goal.reminders_enabled = payload.reminders_enabled
            goal.reminder_time = payload.reminder_time

        self.db.commit()
        self.db.refresh(goal)
        return goal
