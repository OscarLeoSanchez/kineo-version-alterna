from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user_preferences import UserPreferences


class PreferencesRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_user_id(self, user_id: int) -> UserPreferences | None:
        statement = select(UserPreferences).where(UserPreferences.user_id == user_id)
        return self.db.scalar(statement)

    def get_or_create(self, user_id: int) -> UserPreferences:
        preferences = self.get_by_user_id(user_id)
        if preferences is not None:
            if preferences.experience_mode in {"Free", "Pro Trial"}:
                preferences.experience_mode = "Full"
                self.db.add(preferences)
                self.db.commit()
                self.db.refresh(preferences)
            return preferences

        preferences = UserPreferences(user_id=user_id, experience_mode="Full")
        self.db.add(preferences)
        self.db.commit()
        self.db.refresh(preferences)
        return preferences

    def update(
        self,
        *,
        user_id: int,
        coaching_style: str,
        units: str,
        reminders_enabled: bool,
        experience_mode: str,
        daily_priority: str,
        recommendation_depth: str,
        proactive_adjustments: bool,
    ) -> UserPreferences:
        preferences = self.get_or_create(user_id)
        preferences.coaching_style = coaching_style
        preferences.units = units
        preferences.reminders_enabled = reminders_enabled
        preferences.experience_mode = experience_mode
        preferences.daily_priority = daily_priority
        preferences.recommendation_depth = recommendation_depth
        preferences.proactive_adjustments = proactive_adjustments
        self.db.add(preferences)
        self.db.commit()
        self.db.refresh(preferences)
        return preferences
