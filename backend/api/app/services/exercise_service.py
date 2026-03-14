import json

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.repositories.exercise_repository import ExerciseRepository


class ExerciseService:
    def __init__(self, db: Session) -> None:
        self.repo = ExerciseRepository(db)

    def get_exercise(self, exercise_id: int):
        ex = self.repo.find_by_id(exercise_id)
        if not ex:
            raise HTTPException(status_code=404, detail="Ejercicio no encontrado")
        return ex

    def list_exercises(
        self,
        muscle_group: str | None = None,
        equipment: str | None = None,
        difficulty: str | None = None,
        limit: int = 50,
    ):
        return self.repo.find_all_filtered(
            muscle_group=muscle_group,
            equipment=equipment,
            difficulty=difficulty,
            limit=limit,
        )

    def get_substitutes(self, exercise_id: int, available_equipment: list[str] | None = None):
        # First verify exercise exists
        self.get_exercise(exercise_id)
        # Get substitutes filtered by available equipment
        substitutes = self.repo.find_substitutes(exercise_id, available_equipment)
        # Order: same muscle + equipment available first, then bodyweight, then rest
        if not available_equipment:
            return substitutes

        def score(sub):
            try:
                eq_req = json.loads(sub.equipment_required or "[]")
            except Exception:
                eq_req = []
            if not eq_req:  # bodyweight
                return 1
            if any(e in available_equipment for e in eq_req):
                return 0  # best match (equipment available)
            return 2  # has equipment requirement but not available

        return sorted(substitutes, key=score)
