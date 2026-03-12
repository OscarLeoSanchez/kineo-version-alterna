from app.repositories.goal_repository import GoalRepository
from app.repositories.preferences_repository import PreferencesRepository
from app.schemas.goals import WeeklyGoalRead, WeeklyGoalUpsert


class GoalsService:
    def __init__(
        self,
        goal_repository: GoalRepository,
        preferences_repository: PreferencesRepository,
    ) -> None:
        self.goal_repository = goal_repository
        self.preferences_repository = preferences_repository

    def get_current_goal(self, user_id: int) -> WeeklyGoalRead:
        preferences = self.preferences_repository.get_or_create(user_id)
        goal = self.goal_repository.get_for_user(user_id)
        if goal is None:
            goal = self.goal_repository.upsert_for_user(
                user_id=user_id,
                payload=WeeklyGoalUpsert(
                    workout_sessions_target=4,
                    nutrition_adherence_target=85,
                    weight_checkins_target=2,
                    reminders_enabled=preferences.reminders_enabled,
                    reminder_time="07:00",
                ),
            )
        return WeeklyGoalRead.model_validate(goal)

    def update_current_goal(
        self,
        *,
        user_id: int,
        payload: WeeklyGoalUpsert,
    ) -> WeeklyGoalRead:
        goal = self.goal_repository.upsert_for_user(user_id=user_id, payload=payload)
        preferences = self.preferences_repository.get_or_create(user_id)
        self.preferences_repository.update(
            user_id=user_id,
            coaching_style=preferences.coaching_style,
            units=preferences.units,
            reminders_enabled=payload.reminders_enabled,
            experience_mode=preferences.experience_mode,
            daily_priority=preferences.daily_priority,
            recommendation_depth=preferences.recommendation_depth,
            proactive_adjustments=preferences.proactive_adjustments,
        )
        return WeeklyGoalRead.model_validate(goal)
