from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.db.session import get_db
from app.repositories.activity_repository import ActivityRepository
from app.repositories.profile_repository import ProfileRepository
from app.schemas.activity import (
    ActivityDeleteRead,
    ActivityFilterRead,
    ActivityHistoryRead,
    ActivityLogRead,
    BodyMetricCreate,
    BodyMetricHistoryItem,
    NutritionHistoryItem,
    NutritionLogCreate,
    WorkoutSessionCreate,
    WorkoutSessionHistoryItem,
)
from app.schemas.exercise_log import ExerciseLogCreate, ExerciseLogRead
from app.services.exercise_log_service import ExerciseLogService

router = APIRouter(prefix="/activity")


class WorkoutBlockUpdatePayload(BaseModel):
    plan_id: int | None = None
    day_iso_date: str = Field(min_length=10, max_length=10)
    block_title: str = Field(min_length=2, max_length=160)
    completed: bool = False
    selected_exercises: list[str] = Field(default_factory=list)


def _profile_id(db: Session, user_id: int) -> int:
    profile = ProfileRepository(db).get_latest_for_user(user_id)
    if profile is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")
    return profile.id


@router.post("/workouts", response_model=ActivityLogRead, status_code=status.HTTP_201_CREATED)
async def log_workout(
    payload: WorkoutSessionCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
) -> ActivityLogRead:
    record = ActivityRepository(db).log_workout(
        user_id=current_user.id,
        profile_id=_profile_id(db, current_user.id),
        payload=payload,
    )
    return ActivityLogRead(id=record.id, message="Sesion registrada", created_at=record.completed_at)


@router.post("/workout-blocks", response_model=ActivityDeleteRead)
async def save_workout_block_state(
    payload: WorkoutBlockUpdatePayload,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
) -> ActivityDeleteRead:
    ActivityRepository(db).save_block_state(
        user_id=current_user.id,
        plan_id=payload.plan_id,
        day_iso_date=payload.day_iso_date,
        block_title=payload.block_title,
        completed=payload.completed,
        selected_exercises=payload.selected_exercises,
    )
    return ActivityDeleteRead(message="Bloque actualizado")


@router.put("/workouts/{workout_id}", response_model=ActivityLogRead)
async def update_workout(
    workout_id: int,
    payload: WorkoutSessionCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
) -> ActivityLogRead:
    record = ActivityRepository(db).update_workout(
        user_id=current_user.id,
        workout_id=workout_id,
        payload=payload,
    )
    if record is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Workout not found")
    return ActivityLogRead(id=record.id, message="Sesion actualizada", created_at=record.completed_at)


@router.delete("/workouts/{workout_id}", response_model=ActivityDeleteRead)
async def delete_workout(
    workout_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
) -> ActivityDeleteRead:
    deleted = ActivityRepository(db).delete_workout(
        user_id=current_user.id,
        workout_id=workout_id,
    )
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Workout not found")
    return ActivityDeleteRead(message="Sesion eliminada")


@router.post("/nutrition", response_model=ActivityLogRead, status_code=status.HTTP_201_CREATED)
async def log_nutrition(
    payload: NutritionLogCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
) -> ActivityLogRead:
    record = ActivityRepository(db).log_nutrition(
        user_id=current_user.id,
        profile_id=_profile_id(db, current_user.id),
        payload=payload,
    )
    return ActivityLogRead(id=record.id, message="Registro nutricional guardado", created_at=record.logged_at)


@router.put("/nutrition/{nutrition_id}", response_model=ActivityLogRead)
async def update_nutrition(
    nutrition_id: int,
    payload: NutritionLogCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
) -> ActivityLogRead:
    record = ActivityRepository(db).update_nutrition(
        user_id=current_user.id,
        nutrition_id=nutrition_id,
        payload=payload,
    )
    if record is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Nutrition log not found")
    return ActivityLogRead(id=record.id, message="Registro nutricional actualizado", created_at=record.logged_at)


@router.delete("/nutrition/{nutrition_id}", response_model=ActivityDeleteRead)
async def delete_nutrition(
    nutrition_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
) -> ActivityDeleteRead:
    deleted = ActivityRepository(db).delete_nutrition(
        user_id=current_user.id,
        nutrition_id=nutrition_id,
    )
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Nutrition log not found")
    return ActivityDeleteRead(message="Registro nutricional eliminado")


@router.post("/body-metrics", response_model=ActivityLogRead, status_code=status.HTTP_201_CREATED)
async def log_body_metric(
    payload: BodyMetricCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
) -> ActivityLogRead:
    record = ActivityRepository(db).log_body_metric(
        user_id=current_user.id,
        profile_id=_profile_id(db, current_user.id),
        payload=payload,
    )
    return ActivityLogRead(id=record.id, message="Metrica corporal registrada", created_at=record.recorded_at)


@router.put("/body-metrics/{metric_id}", response_model=ActivityLogRead)
async def update_body_metric(
    metric_id: int,
    payload: BodyMetricCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
) -> ActivityLogRead:
    record = ActivityRepository(db).update_body_metric(
        user_id=current_user.id,
        metric_id=metric_id,
        payload=payload,
    )
    if record is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Body metric not found")
    return ActivityLogRead(id=record.id, message="Metrica corporal actualizada", created_at=record.recorded_at)


@router.delete("/body-metrics/{metric_id}", response_model=ActivityDeleteRead)
async def delete_body_metric(
    metric_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
) -> ActivityDeleteRead:
    deleted = ActivityRepository(db).delete_body_metric(
        user_id=current_user.id,
        metric_id=metric_id,
    )
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Body metric not found")
    return ActivityDeleteRead(message="Metrica corporal eliminada")


@router.get("/history", response_model=ActivityHistoryRead)
async def get_activity_history(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
) -> ActivityHistoryRead:
    repository = ActivityRepository(db)
    return ActivityHistoryRead(
        workouts=[
            WorkoutSessionHistoryItem.model_validate(item)
            for item in repository.recent_workouts(user_id=current_user.id)
        ],
        nutrition_logs=[
            NutritionHistoryItem.model_validate(item)
            for item in repository.recent_nutrition_logs(user_id=current_user.id)
        ],
        body_metrics=[
            BodyMetricHistoryItem.model_validate(item)
            for item in repository.recent_body_metrics(user_id=current_user.id)
        ],
    )


@router.get("/history/filter", response_model=ActivityFilterRead)
async def filter_activity_history(
    filter_type: str = Query(default="all", pattern="^(all|workout|nutrition|body)$"),
    limit: int = Query(default=12, ge=1, le=50),
    energy_level: str | None = Query(default=None),
    minimum_score: int | None = Query(default=None, ge=0, le=100),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
) -> ActivityFilterRead:
    repository = ActivityRepository(db)
    workouts = repository.filter_workouts(
        user_id=current_user.id,
        limit=limit,
        energy_level=energy_level,
    ) if filter_type in {"all", "workout"} else []
    nutrition_logs = repository.filter_nutrition_logs(
        user_id=current_user.id,
        limit=limit,
        minimum_score=minimum_score,
    ) if filter_type in {"all", "nutrition"} else []
    body_metrics = repository.filter_body_metrics(
        user_id=current_user.id,
        limit=limit,
    ) if filter_type in {"all", "body"} else []
    return ActivityFilterRead(
        filter_type=filter_type,
        limit=limit,
        workouts=[WorkoutSessionHistoryItem.model_validate(item) for item in workouts],
        nutrition_logs=[NutritionHistoryItem.model_validate(item) for item in nutrition_logs],
        body_metrics=[BodyMetricHistoryItem.model_validate(item) for item in body_metrics],
    )


@router.post("/exercise-logs", response_model=ExerciseLogRead, status_code=status.HTTP_201_CREATED)
def log_exercise_set(
    payload: ExerciseLogCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ExerciseLogRead:
    svc = ExerciseLogService(db)
    return svc.log_set(current_user.id, payload.model_dump())


@router.get("/exercise-logs", response_model=list[ExerciseLogRead])
def get_exercise_logs(
    day: str = Query(..., description="ISO date e.g. 2026-03-13"),
    exercise_name: Optional[str] = Query(None),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[ExerciseLogRead]:
    svc = ExerciseLogService(db)
    return svc.get_day_logs(current_user.id, day, exercise_name)
