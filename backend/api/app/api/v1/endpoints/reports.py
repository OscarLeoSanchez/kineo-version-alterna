from datetime import UTC, datetime

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.db.session import get_db
from app.repositories.activity_repository import ActivityRepository
from app.repositories.goal_repository import GoalRepository
from app.schemas.goals import WeeklyGoalUpsert
from app.schemas.reports import WeeklyReportRead

router = APIRouter(prefix="/reports")


@router.get("/weekly", response_model=WeeklyReportRead)
async def get_weekly_report(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
) -> WeeklyReportRead:
    activity_repository = ActivityRepository(db)
    goal_repository = GoalRepository(db)

    goal = goal_repository.get_for_user(current_user.id)
    if goal is None:
        goal = goal_repository.upsert_for_user(
            user_id=current_user.id,
            payload=WeeklyGoalUpsert(
                workout_sessions_target=4,
                nutrition_adherence_target=85,
                weight_checkins_target=2,
                reminders_enabled=True,
                reminder_time="07:00",
            ),
        )

    workouts = activity_repository.workout_count(user_id=current_user.id, days=7)
    adherence = activity_repository.nutrition_average(user_id=current_user.id, days=7)
    weight_checkins = len(activity_repository.weight_series(user_id=current_user.id, limit=10))

    goal_status = [
        {
            "label": "Sesiones",
            "current": workouts,
            "target": goal.workout_sessions_target,
            "completed": workouts >= goal.workout_sessions_target,
        },
        {
            "label": "Adherencia",
            "current": adherence,
            "target": goal.nutrition_adherence_target,
            "completed": adherence >= goal.nutrition_adherence_target,
        },
        {
            "label": "Chequeos",
            "current": weight_checkins,
            "target": goal.weight_checkins_target,
            "completed": weight_checkins >= goal.weight_checkins_target,
        },
    ]
    highlights = [
        f"Completaste {workouts} sesiones en los ultimos 7 dias.",
        f"Tu adherencia nutricional reciente fue de {adherence}%.",
        f"Registraste {weight_checkins} chequeos corporales recientes.",
    ]
    markdown_report = "\n".join(
        [
            "# Reporte semanal Kineo",
            "",
            *[f"- {item}" for item in highlights],
            "",
            "## Estado de objetivos",
            *[
                f"- {item['label']}: {item['current']}/{item['target']} ({'cumplido' if item['completed'] else 'en progreso'})"
                for item in goal_status
            ],
        ]
    )

    return WeeklyReportRead(
        generated_at=datetime.now(UTC),
        title="Reporte semanal Kineo",
        goal_status=goal_status,
        highlights=highlights,
        markdown_report=markdown_report,
    )
