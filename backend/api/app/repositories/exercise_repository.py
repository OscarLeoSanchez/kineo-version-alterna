from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.exercise_catalog import ExerciseCatalog
from app.models.exercise_substitution import ExerciseSubstitution


class ExerciseRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def find_by_id(self, exercise_id: int) -> ExerciseCatalog | None:
        return self.db.get(ExerciseCatalog, exercise_id)

    def find_all_filtered(
        self,
        muscle_group: str | None = None,
        equipment: str | None = None,
        difficulty: str | None = None,
        limit: int = 50,
    ) -> list[ExerciseCatalog]:
        stmt = select(ExerciseCatalog)
        if muscle_group:
            stmt = stmt.where(ExerciseCatalog.muscle_group == muscle_group)
        if difficulty:
            stmt = stmt.where(ExerciseCatalog.difficulty == difficulty)
        if equipment:
            # Match exercises that require this equipment OR have no requirements
            stmt = stmt.where(
                (ExerciseCatalog.equipment_required.like(f"%{equipment}%"))
                | (ExerciseCatalog.equipment_required == "[]")
                | (ExerciseCatalog.equipment_required.is_(None))
            )
        stmt = stmt.limit(limit)
        return list(self.db.scalars(stmt).all())

    def upsert(self, data: dict) -> ExerciseCatalog:
        """Insert a new exercise or update an existing one matched by name."""
        name = data.get("name")
        if not name:
            raise ValueError("Exercise data must include 'name'")

        stmt = select(ExerciseCatalog).where(ExerciseCatalog.name == name)
        exercise = self.db.scalar(stmt)

        if exercise is None:
            exercise = ExerciseCatalog(name=name)
            self.db.add(exercise)

        for key, value in data.items():
            if key != "name" and hasattr(exercise, key):
                setattr(exercise, key, value)

        self.db.flush()
        return exercise

    def find_substitutes(
        self,
        exercise_id: int,
        available_equipment: list[str] | None = None,
    ) -> list[ExerciseCatalog]:
        """Return substitute exercises for a given exercise_id.

        If available_equipment is provided, only returns substitutes whose
        equipment_required is satisfied by the available equipment list or is empty.
        """
        stmt = (
            select(ExerciseCatalog)
            .join(
                ExerciseSubstitution,
                ExerciseSubstitution.substitute_id == ExerciseCatalog.id,
            )
            .where(ExerciseSubstitution.exercise_id == exercise_id)
        )

        if available_equipment:
            # Keep exercises that require no equipment OR whose required equipment
            # overlaps with what's available.
            equipment_filters = [
                ExerciseCatalog.equipment_required.is_(None),
                ExerciseCatalog.equipment_required == "[]",
            ]
            for eq in available_equipment:
                equipment_filters.append(
                    ExerciseCatalog.equipment_required.like(f"%{eq}%")
                )
            from sqlalchemy import or_
            stmt = stmt.where(or_(*equipment_filters))

        return list(self.db.scalars(stmt).all())
