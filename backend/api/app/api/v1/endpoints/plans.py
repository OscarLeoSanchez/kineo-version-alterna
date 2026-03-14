from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.personalization import (
    PersonalizationContext,
    get_personalization_context,
    merge_personalization_context,
)
from app.core.security import get_current_user
from app.db.session import get_db
from app.repositories.plan_repository import PlanRepository
from app.repositories.preferences_repository import PreferencesRepository
from app.repositories.profile_repository import ProfileRepository
from app.schemas.plan import InitialPlanRead, PlanHistoryItemRead
from app.services.plan_service import PlanService

router = APIRouter(prefix="/plans")


@router.get("/generate-stream")
async def generate_plan_stream(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """SSE endpoint for streaming plan generation progress."""
    from fastapi.responses import StreamingResponse

    plan_service = PlanService(PlanRepository(db))

    async def event_stream():
        async for event in plan_service.generate_stream(db, current_user.id):
            yield event

    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )


@router.get("/current", response_model=InitialPlanRead)
async def get_current_plan(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
    personalization: PersonalizationContext = Depends(get_personalization_context),
) -> InitialPlanRead:
    profile = ProfileRepository(db).get_latest_for_user(current_user.id)
    if profile is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")

    service = PlanService(PlanRepository(db))
    plan = service.get_current_plan_for_user(current_user.id)
    if plan is None:
        plan = service.generate_for_profile(profile)
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
    return service.personalize_plan(
        plan=plan,
        profile=profile,
        context=effective_personalization,
    )


@router.get("/history", response_model=list[PlanHistoryItemRead])
async def get_plan_history(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
) -> list[PlanHistoryItemRead]:
    plans = PlanRepository(db).list_for_user(current_user.id)
    current_plan = PlanRepository(db).get_by_user_id(current_user.id)
    items: list[PlanHistoryItemRead] = []
    for plan in plans:
        created = plan.created_at
        week_label = f"Semana del {created.strftime('%d/%m/%Y')}"
        items.append(
            PlanHistoryItemRead(
                id=plan.id,
                profile_id=plan.profile_id,
                workout_focus=plan.workout_focus,
                created_at=created,
                week_label=week_label,
                is_current=current_plan is not None and current_plan.id == plan.id,
            )
        )
    return items
