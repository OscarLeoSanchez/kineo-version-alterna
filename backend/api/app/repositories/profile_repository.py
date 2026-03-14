import json
from datetime import date

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user_profile import UserProfile
from app.schemas.onboarding import UserProfileCreate


class ProfileRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_latest_for_user(self, user_id: int) -> UserProfile | None:
        statement = (
            select(UserProfile)
            .where(UserProfile.user_id == user_id)
            .order_by(UserProfile.id.desc())
            .limit(1)
        )
        return self.db.scalar(statement)

    def get_by_id(self, profile_id: int) -> UserProfile | None:
        statement = select(UserProfile).where(UserProfile.id == profile_id)
        return self.db.scalar(statement)

    def create_profile(self, *, user_id: int, payload: UserProfileCreate) -> UserProfile:
        return self.upsert_latest_profile(user_id=user_id, payload=payload)

    def upsert_latest_profile(self, *, user_id: int, payload: UserProfileCreate) -> UserProfile:
        profile = self.get_latest_for_user(user_id)
        if profile is None:
            profile = UserProfile(user_id=user_id)

        profile.full_name = payload.full_name
        profile.age = payload.age
        profile.birth_date = payload.birth_date
        profile.sex = payload.sex
        profile.gender_identity = payload.gender_identity
        profile.height_cm = payload.height_cm
        profile.weight_kg = payload.weight_kg
        profile.goal = payload.goal
        profile.activity_level = payload.activity_level
        profile.workout_days_per_week = payload.workout_days_per_week
        profile.session_minutes = payload.session_minutes
        profile.training_location = payload.training_location
        profile.cooking_style = payload.cooking_style
        profile.meals_per_day = payload.meals_per_day
        profile.equipment = json.dumps(payload.equipment)
        profile.dietary_preferences = json.dumps(payload.dietary_preferences)
        profile.allergies = json.dumps(payload.allergies)
        profile.food_dislikes = json.dumps(payload.food_dislikes)
        profile.restrictions = json.dumps(payload.restrictions)
        profile.body_measurements = json.dumps(payload.body_measurements)
        profile.additional_notes = payload.additional_notes

        self.db.add(profile)
        self.db.commit()
        self.db.refresh(profile)
        return profile
