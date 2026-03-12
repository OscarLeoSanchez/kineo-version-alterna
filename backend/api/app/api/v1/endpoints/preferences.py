from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.db.session import get_db
from app.repositories.goal_repository import GoalRepository
from app.repositories.preferences_repository import PreferencesRepository
from app.schemas.preferences import UserPreferencesRead, UserPreferencesUpdate
from app.services.preferences_service import PreferencesService

router = APIRouter(prefix="/preferences")


def get_preferences_service(db: Session = Depends(get_db)) -> PreferencesService:
    return PreferencesService(PreferencesRepository(db), GoalRepository(db))


@router.get("/me", response_model=UserPreferencesRead)
async def get_my_preferences(
    service: PreferencesService = Depends(get_preferences_service),
    current_user=Depends(get_current_user),
) -> UserPreferencesRead:
    return service.get_for_user(current_user.id)


@router.patch("/me", response_model=UserPreferencesRead)
async def update_my_preferences(
    payload: UserPreferencesUpdate,
    service: PreferencesService = Depends(get_preferences_service),
    current_user=Depends(get_current_user),
) -> UserPreferencesRead:
    return service.update_for_user(user_id=current_user.id, payload=payload)
