import copy
import json

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.repositories.plan_modification_repository import PlanModificationRepository
from app.repositories.plan_repository import PlanRepository


class PlanModificationService:
    def __init__(self, db: Session) -> None:
        self.repo = PlanModificationRepository(db)
        self.plan_repo = PlanRepository(db)

    def apply_modification(self, user_id: int, plan_id: int, data: dict):
        # Verify plan belongs to user
        self.plan_repo.get_by_id_for_user(user_id=user_id, plan_id=plan_id)
        mod = self.repo.create(user_id, plan_id, data)
        return mod

    def remove_modification(self, mod_id: int, user_id: int):
        deleted = self.repo.delete(mod_id, user_id)
        if not deleted:
            raise HTTPException(status_code=404, detail="Modificación no encontrada")
        return {"ok": True}

    def get_modifications(self, user_id: int, plan_id: int | None = None):
        return self.repo.list_active(user_id, plan_id)

    @staticmethod
    def merge_plan_with_modifications(plan_payload: dict, modifications: list) -> dict:
        """
        Pure function — never mutates plan_payload.
        Returns a deep copy with modifications applied in created_at order.

        Modification types:
        - exclude: remove target item from its location in the plan
        - swap: replace target item name with replacement_item_name
        - edit_params: merge override_json into target item
        - add_note: append note_text to target item as '_coach_note' field

        Target matching:
        - For exercises: match weekly_workouts[day_label].blocks[block_title].exercises[name]
        - For meals: match meal_slots[title].weekly_plan[day_label] or option_bank[name]
        """
        if not modifications:
            plan = copy.deepcopy(plan_payload)
            plan["_has_modifications"] = False
            plan["_modification_count"] = 0
            return plan

        plan = copy.deepcopy(plan_payload)
        applied = 0

        # Sort by created_at if available
        mods_sorted = sorted(
            modifications,
            key=lambda m: getattr(m, "created_at", None) or "",
        )

        for mod in mods_sorted:
            if not getattr(mod, "is_active", True):
                continue

            mod_type = mod.modification_type
            target_type = getattr(mod, "target_type", "exercise")
            target_day = getattr(mod, "target_day_label", None)
            target_block = getattr(mod, "target_block_title", None)
            target_name = getattr(mod, "target_item_name", None)
            replacement = getattr(mod, "replacement_item_name", None)
            note = getattr(mod, "note_text", None)
            try:
                override = json.loads(getattr(mod, "override_json", "{}") or "{}")
            except Exception:
                override = {}

            if target_type == "exercise":
                _apply_exercise_modification(
                    plan, mod_type, target_day, target_block, target_name, replacement, note, override
                )
            elif target_type == "meal":
                _apply_meal_modification(
                    plan, mod_type, target_day, target_name, replacement, note, override
                )

            applied += 1

        plan["_has_modifications"] = applied > 0
        plan["_modification_count"] = applied
        return plan


def _apply_exercise_modification(
    plan: dict,
    mod_type: str,
    target_day: str | None,
    target_block: str | None,
    target_name: str | None,
    replacement: str | None,
    note: str | None,
    override: dict,
) -> None:
    """Apply modification to an exercise within weekly_workouts."""
    workouts = plan.get("weekly_workouts", [])
    for workout in workouts:
        if target_day and workout.get("day_label") != target_day:
            continue
        for block in workout.get("blocks", []):
            if target_block and block.get("title") != target_block:
                continue
            exercises = block.get("exercises", [])
            for i, ex in enumerate(exercises):
                if ex.get("name") == target_name or ex.get("name_es") == target_name:
                    if mod_type == "exclude":
                        exercises.pop(i)
                        return
                    elif mod_type == "swap" and replacement:
                        ex["name"] = replacement
                        ex["name_es"] = replacement
                        ex["_swapped"] = True
                    elif mod_type == "edit_params":
                        ex.update(override)
                        ex["_edited"] = True
                    elif mod_type == "add_note" and note:
                        ex["_coach_note"] = note
                    return


def _apply_meal_modification(
    plan: dict,
    mod_type: str,
    target_day: str | None,
    target_name: str | None,
    replacement: str | None,
    note: str | None,
    override: dict,
) -> None:
    """Apply modification to a meal within meal_slots."""
    slots = plan.get("meal_slots", [])
    for slot in slots:
        # Check weekly_plan entries
        for entry in slot.get("weekly_plan", []):
            if target_day and entry.get("day_label") != target_day:
                continue
            if entry.get("meal_name") == target_name:
                if mod_type == "exclude":
                    entry["_excluded"] = True
                elif mod_type == "swap" and replacement:
                    entry["meal_name"] = replacement
                    entry["_swapped"] = True
                elif mod_type == "edit_params":
                    entry.update(override)
                elif mod_type == "add_note" and note:
                    entry["_coach_note"] = note
                return
