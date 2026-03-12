from app.repositories.goal_repository import GoalRepository
from app.repositories.preferences_repository import PreferencesRepository
from app.schemas.preferences import UserPreferencesRead, UserPreferencesUpdate


class PreferencesService:
    def __init__(
        self,
        repository: PreferencesRepository,
        goal_repository: GoalRepository,
    ) -> None:
        self.repository = repository
        self.goal_repository = goal_repository

    def get_for_user(self, user_id: int) -> UserPreferencesRead:
        return UserPreferencesRead.model_validate(self.repository.get_or_create(user_id))

    def update_for_user(
        self,
        *,
        user_id: int,
        payload: UserPreferencesUpdate,
    ) -> UserPreferencesRead:
        experience_mode = (
            "Full"
            if payload.experience_mode in {"Free", "Pro Trial"}
            else payload.experience_mode
        )
        preferences = self.repository.update(
            user_id=user_id,
            coaching_style=payload.coaching_style,
            units=payload.units,
            reminders_enabled=payload.reminders_enabled,
            experience_mode=experience_mode,
            daily_priority=payload.daily_priority,
            recommendation_depth=payload.recommendation_depth,
            proactive_adjustments=payload.proactive_adjustments,
        )
        goal = self.goal_repository.get_for_user(user_id)
        if goal is not None and goal.reminders_enabled != payload.reminders_enabled:
            goal.reminders_enabled = payload.reminders_enabled
            self.goal_repository.db.add(goal)
            self.goal_repository.db.commit()
            self.goal_repository.db.refresh(goal)
        return UserPreferencesRead.model_validate(preferences)
