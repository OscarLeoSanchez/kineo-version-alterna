from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.core.security import get_current_user
from app.services.plan_modification_service import PlanModificationService
from app.repositories.plan_repository import PlanRepository
from app.repositories.profile_repository import ProfileRepository
from app.schemas.plan_modification import PlanModificationCreate, PlanModificationRead

router = APIRouter(prefix="/plans/modifications", tags=["plan-modifications"])


def _get_current_plan_id(db: Session, user_id: int) -> int:
    """Resolve the latest plan_id for the user, raising 404 if none exists."""
    profile = ProfileRepository(db).get_latest_for_user(user_id)
    if profile is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")
    plan = PlanRepository(db).get_by_profile_id(profile.id)
    if plan is None:
        # Fall back to latest plan by user_id (profile may have no linked plan yet)
        plan = PlanRepository(db).get_by_user_id(user_id)
    if plan is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No active plan found")
    return plan.id


@router.post("/", response_model=PlanModificationRead, status_code=status.HTTP_201_CREATED)
def create_modification(
    payload: PlanModificationCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    plan_id = _get_current_plan_id(db, current_user.id)
    svc = PlanModificationService(db)
    mod = svc.apply_modification(current_user.id, plan_id, payload.model_dump())
    return mod


@router.get("/", response_model=list[PlanModificationRead])
def list_modifications(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    svc = PlanModificationService(db)
    return svc.get_modifications(current_user.id)


@router.delete("/{mod_id}")
def delete_modification(
    mod_id: int,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    svc = PlanModificationService(db)
    return svc.remove_modification(mod_id, current_user.id)
