from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import Optional

from app.db.session import get_db
from app.core.security import get_current_user
from app.services.exercise_service import ExerciseService
from app.schemas.exercise import ExerciseCatalogRead, ExerciseCatalogSummary

router = APIRouter(prefix="/exercises", tags=["exercises"])


@router.get("/", response_model=list[ExerciseCatalogSummary])
def list_exercises(
    muscle_group: Optional[str] = Query(None),
    equipment: Optional[str] = Query(None),
    difficulty: Optional[str] = Query(None),
    limit: int = Query(50, le=200),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    svc = ExerciseService(db)
    exercises = svc.list_exercises(
        muscle_group=muscle_group,
        equipment=equipment,
        difficulty=difficulty,
        limit=limit,
    )
    return [ExerciseCatalogSummary.from_orm_safe(e) for e in exercises]


@router.get("/{exercise_id}", response_model=ExerciseCatalogRead)
def get_exercise(
    exercise_id: int,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    svc = ExerciseService(db)
    ex = svc.get_exercise(exercise_id)
    return ExerciseCatalogRead.from_orm_safe(ex)


@router.get("/{exercise_id}/substitutes", response_model=list[ExerciseCatalogSummary])
def get_substitutes(
    exercise_id: int,
    equipment: Optional[list[str]] = Query(None),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    svc = ExerciseService(db)
    subs = svc.get_substitutes(exercise_id, equipment)
    return [ExerciseCatalogSummary.from_orm_safe(s) for s in subs]
