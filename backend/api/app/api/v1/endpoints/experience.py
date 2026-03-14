from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile, status
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
    NutritionPhotoAnalysisRead,
    NutritionSummaryRead,
    ProgressSummaryRead,
    WorkoutSummaryRead,
)
from app.services.experience_service import ExperienceService
from app.services.nutrition_photo_service import NutritionPhotoService
from app.services.plan_service import PlanService

router = APIRouter(prefix="/experience")


def _resolve_profile_and_plan(db: Session, user_id: int, plan_id: int | None = None):
    repository = PlanRepository(db)
    plan_service = PlanService(PlanRepository(db))
    if plan_id is not None:
        raw_plan = repository.get_by_id_for_user(user_id=user_id, plan_id=plan_id)
        if raw_plan is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Plan not found")
        profile = ProfileRepository(db).get_latest_for_user(user_id)
        if profile is None or profile.id != raw_plan.profile_id:
            profile = ProfileRepository(db).get_by_id(raw_plan.profile_id)
        if profile is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")
        plan = plan_service._to_read_model(raw_plan)
        return profile, plan

    profile = ProfileRepository(db).get_latest_for_user(user_id)
    if profile is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")

    plan = plan_service.get_current_plan_for_user(user_id)
    if plan is None:
        plan = plan_service.generate_for_profile(profile)
    return profile, plan


@router.get("/workout", response_model=WorkoutSummaryRead)
async def get_workout_summary(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
    plan_id: int | None = Query(default=None),
    personalization: PersonalizationContext = Depends(get_personalization_context),
) -> WorkoutSummaryRead:
    profile, plan = _resolve_profile_and_plan(db, current_user.id, plan_id)
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
    plan_id: int | None = Query(default=None),
    personalization: PersonalizationContext = Depends(get_personalization_context),
) -> NutritionSummaryRead:
    profile, plan = _resolve_profile_and_plan(db, current_user.id, plan_id)
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


@router.post("/nutrition/photo-analysis", response_model=NutritionPhotoAnalysisRead)
async def analyze_nutrition_photo(
    meal_label: str = Form(...),
    photo: UploadFile = File(...),
    _: object = Depends(get_current_user),
) -> NutritionPhotoAnalysisRead:
    return await NutritionPhotoService().analyze_photo(
        meal_label=meal_label,
        upload=photo,
    )


@router.get("/progress", response_model=ProgressSummaryRead)
async def get_progress_summary(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
    plan_id: int | None = Query(default=None),
    personalization: PersonalizationContext = Depends(get_personalization_context),
) -> ProgressSummaryRead:
    profile, plan = _resolve_profile_and_plan(db, current_user.id, plan_id)
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
