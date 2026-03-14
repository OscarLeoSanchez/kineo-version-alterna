from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.plan_modification import PlanModification


class PlanModificationRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def create(self, user_id: int, plan_id: int | None, data: dict) -> PlanModification:
        mod = PlanModification(
            user_id=user_id,
            plan_id=plan_id,
            **{k: v for k, v in data.items() if hasattr(PlanModification, k)},
        )
        self.db.add(mod)
        self.db.commit()
        self.db.refresh(mod)
        return mod

    def list_active(
        self,
        user_id: int,
        plan_id: int | None = None,
    ) -> list[PlanModification]:
        stmt = (
            select(PlanModification)
            .where(PlanModification.user_id == user_id)
            .where(PlanModification.is_active == True)  # noqa: E712
        )
        if plan_id is not None:
            stmt = stmt.where(PlanModification.plan_id == plan_id)
        return list(self.db.scalars(stmt).all())

    def delete(self, mod_id: int, user_id: int) -> bool:
        """Hard-delete a modification. Returns False if not found or user mismatch."""
        mod = self.db.get(PlanModification, mod_id)
        if mod is None or mod.user_id != user_id:
            return False
        self.db.delete(mod)
        self.db.commit()
        return True

    def deactivate_all(self, user_id: int, plan_id: int) -> None:
        """Soft-deactivate all modifications for a plan (e.g., when plan is regenerated)."""
        stmt = (
            select(PlanModification)
            .where(PlanModification.user_id == user_id)
            .where(PlanModification.plan_id == plan_id)
            .where(PlanModification.is_active == True)  # noqa: E712
        )
        mods = list(self.db.scalars(stmt).all())
        for mod in mods:
            mod.is_active = False
        self.db.commit()
