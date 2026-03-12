from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.personalization import (
    PersonalizationContext,
    get_personalization_context,
    merge_personalization_context,
)
from app.core.security import get_current_user
from app.db.session import get_db
from app.repositories.activity_repository import ActivityRepository
from app.repositories.plan_repository import PlanRepository
from app.repositories.preferences_repository import PreferencesRepository
from app.repositories.profile_repository import ProfileRepository
from app.schemas.experience import (
    NutritionSummaryRead,
    ProgressSummaryRead,
    WorkoutSummaryRead,
)
from app.services.experience_service import ExperienceService
from app.services.plan_service import PlanService

router = APIRouter(prefix="/experience")


def _resolve_profile_and_plan(db: Session, user_id: int):
    profile = ProfileRepository(db).get_latest_for_user(user_id)
    if profile is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")

    plan_service = PlanService(PlanRepository(db))
    plan = plan_service.get_current_plan_for_user(user_id)
    if plan is None:
        plan = plan_service.generate_for_profile(profile)
    return profile, plan


@router.get("/workout", response_model=WorkoutSummaryRead)
async def get_workout_summary(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
    personalization: PersonalizationContext = Depends(get_personalization_context),
) -> WorkoutSummaryRead:
    profile, plan = _resolve_profile_and_plan(db, current_user.id)
    stored_preferences = PreferencesRepository(db).get_or_create(current_user.id)
    effective_personalization = merge_personalization_context(
        stored=PersonalizationContext(
            coach_style=stored_preferences.coaching_style,
            experience_mode=stored_preferences.experience_mode,
            units=stored_preferences.units,
            daily_priority=stored_preferences.daily_priority,
            recommendation_depth=stored_preferences.recommendation_depth,
            proactive_adjustments=stored_preferences.proactive_adjustments,
        ),
        incoming=personalization,
    )
    personalized_plan = PlanService(PlanRepository(db)).personalize_plan(
        plan=plan,
        profile=profile,
        context=effective_personalization,
    )
    return ExperienceService(ActivityRepository(db)).build_workout(
        profile,
        personalized_plan,
        effective_personalization,
    )


@router.get("/nutrition", response_model=NutritionSummaryRead)
async def get_nutrition_summary(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
    personalization: PersonalizationContext = Depends(get_personalization_context),
) -> NutritionSummaryRead:
    profile, plan = _resolve_profile_and_plan(db, current_user.id)
    stored_preferences = PreferencesRepository(db).get_or_create(current_user.id)
    effective_personalization = merge_personalization_context(
        stored=PersonalizationContext(
            coach_style=stored_preferences.coaching_style,
            experience_mode=stored_preferences.experience_mode,
            units=stored_preferences.units,
            daily_priority=stored_preferences.daily_priority,
            recommendation_depth=stored_preferences.recommendation_depth,
            proactive_adjustments=stored_preferences.proactive_adjustments,
        ),
        incoming=personalization,
    )
    personalized_plan = PlanService(PlanRepository(db)).personalize_plan(
        plan=plan,
        profile=profile,
        context=effective_personalization,
    )
    return ExperienceService(ActivityRepository(db)).build_nutrition(
        profile,
        personalized_plan,
        effective_personalization,
    )


@router.get("/progress", response_model=ProgressSummaryRead)
async def get_progress_summary(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
    personalization: PersonalizationContext = Depends(get_personalization_context),
) -> ProgressSummaryRead:
    profile, plan = _resolve_profile_and_plan(db, current_user.id)
    stored_preferences = PreferencesRepository(db).get_or_create(current_user.id)
    effective_personalization = merge_personalization_context(
        stored=PersonalizationContext(
            coach_style=stored_preferences.coaching_style,
            experience_mode=stored_preferences.experience_mode,
            units=stored_preferences.units,
            daily_priority=stored_preferences.daily_priority,
            recommendation_depth=stored_preferences.recommendation_depth,
            proactive_adjustments=stored_preferences.proactive_adjustments,
        ),
        incoming=personalization,
    )
    personalized_plan = PlanService(PlanRepository(db)).personalize_plan(
        plan=plan,
        profile=profile,
        context=effective_personalization,
    )
    return ExperienceService(ActivityRepository(db)).build_progress(
        profile,
        personalized_plan,
        effective_personalization,
    )
