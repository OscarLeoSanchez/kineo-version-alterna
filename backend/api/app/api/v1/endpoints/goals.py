from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.db.session import get_db
from app.repositories.goal_repository import GoalRepository
from app.repositories.preferences_repository import PreferencesRepository
from app.schemas.goals import WeeklyGoalRead, WeeklyGoalUpsert
from app.services.goals_service import GoalsService

router = APIRouter(prefix="/goals")


def get_goals_service(db: Session = Depends(get_db)) -> GoalsService:
    return GoalsService(GoalRepository(db), PreferencesRepository(db))


@router.get("/current", response_model=WeeklyGoalRead)
async def get_current_goal(
    service: GoalsService = Depends(get_goals_service),
    current_user=Depends(get_current_user),
) -> WeeklyGoalRead:
    return service.get_current_goal(current_user.id)


@router.put("/current", response_model=WeeklyGoalRead, status_code=status.HTTP_200_OK)
async def update_current_goal(
    payload: WeeklyGoalUpsert,
    service: GoalsService = Depends(get_goals_service),
    current_user=Depends(get_current_user),
) -> WeeklyGoalRead:
    return service.update_current_goal(user_id=current_user.id, payload=payload)
