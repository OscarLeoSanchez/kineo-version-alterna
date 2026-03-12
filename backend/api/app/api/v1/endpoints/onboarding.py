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
from app.schemas.onboarding import DashboardSummary, UserProfileCreate, UserProfileRead
from app.services.onboarding_service import OnboardingService
from app.services.plan_service import PlanService

router = APIRouter(prefix="/onboarding")


def get_service(db: Session = Depends(get_db)) -> OnboardingService:
    repository = ProfileRepository(db)
    plan_service = PlanService(PlanRepository(db))
    activity_repository = ActivityRepository(db)
    return OnboardingService(repository, plan_service, activity_repository)


@router.post("/profile", response_model=UserProfileRead, status_code=status.HTTP_200_OK)
async def create_profile(
    payload: UserProfileCreate,
    service: OnboardingService = Depends(get_service),
    current_user=Depends(get_current_user),
) -> UserProfileRead:
    return service.create_profile(user_id=current_user.id, payload=payload)


@router.get("/profile/latest", response_model=UserProfileRead)
async def get_latest_profile(
    service: OnboardingService = Depends(get_service),
    current_user=Depends(get_current_user),
) -> UserProfileRead:
    profile = service.get_latest_profile(current_user.id)
    if profile is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")
    return profile


@router.get("/dashboard-summary", response_model=DashboardSummary)
async def get_dashboard_summary(
    service: OnboardingService = Depends(get_service),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
    personalization: PersonalizationContext = Depends(get_personalization_context),
) -> DashboardSummary:
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
    return service.get_dashboard_summary(current_user.id, effective_personalization)
