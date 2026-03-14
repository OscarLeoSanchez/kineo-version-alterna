from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.initial_plan import InitialPlan


class PlanRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_profile_id(self, profile_id: int) -> InitialPlan | None:
        statement = select(InitialPlan).where(InitialPlan.profile_id == profile_id)
        return self.db.scalar(statement)

    def get_by_user_id(self, user_id: int) -> InitialPlan | None:
        statement = (
            select(InitialPlan)
            .where(InitialPlan.user_id == user_id)
            .order_by(InitialPlan.id.desc())
            .limit(1)
        )
        return self.db.scalar(statement)

    def get_by_id_for_user(self, *, user_id: int, plan_id: int) -> InitialPlan | None:
        statement = select(InitialPlan).where(
            InitialPlan.id == plan_id,
            InitialPlan.user_id == user_id,
        )
        return self.db.scalar(statement)

    def list_for_user(self, user_id: int) -> list[InitialPlan]:
        statement = (
            select(InitialPlan)
            .where(InitialPlan.user_id == user_id)
            .order_by(InitialPlan.created_at.desc(), InitialPlan.id.desc())
        )
        return list(self.db.scalars(statement).all())

    def upsert_plan(
        self,
        *,
        user_id: int,
        profile_id: int,
        workout_focus: str,
        workout_summary: str,
        nutrition_summary: str,
        habits_summary: str,
        plan_payload: str | None = None,
    ) -> InitialPlan:
        plan = self.get_by_profile_id(profile_id)
        if plan is None:
            plan = InitialPlan(
                user_id=user_id,
                profile_id=profile_id,
                workout_focus=workout_focus,
                workout_summary=workout_summary,
                nutrition_summary=nutrition_summary,
                habits_summary=habits_summary,
                plan_payload=plan_payload,
            )
            self.db.add(plan)
        else:
            plan.user_id = user_id
            plan.workout_focus = workout_focus
            plan.workout_summary = workout_summary
            plan.nutrition_summary = nutrition_summary
            plan.habits_summary = habits_summary
            plan.plan_payload = plan_payload

        self.db.commit()
        self.db.refresh(plan)
        return plan
