import json
import logging

from app.ai.planner import DeterministicPlanningProvider, build_planning_provider
from app.ai.planning_models import GeneratedProgram
from app.core.personalization import PersonalizationContext
from app.models.user_profile import UserProfile
from app.repositories.plan_repository import PlanRepository
from app.schemas.plan import InitialPlanRead


class PlanService:
    def __init__(self, repository: PlanRepository) -> None:
        self.repository = repository
        self.provider = build_planning_provider()
        self.fallback_provider = DeterministicPlanningProvider()

    def generate_for_profile(self, profile: UserProfile) -> InitialPlanRead:
        profile_context = self._profile_context(profile)
        try:
            program = self.provider.generate_program(profile_context)
        except Exception:
            logging.exception("AI planning failed, using deterministic fallback")
            program = self.fallback_provider.generate_program(profile_context)
        plan = self.repository.upsert_plan(
            user_id=profile.user_id or 0,
            profile_id=profile.id,
            workout_focus=program.workout_focus,
            workout_summary=program.workout_summary,
            nutrition_summary=program.nutrition_summary,
            habits_summary=program.habits_summary,
            plan_payload=program.model_dump_json(),
        )
        return self._to_read_model(plan)

    def get_current_plan(self, profile_id: int) -> InitialPlanRead | None:
        plan = self.repository.get_by_profile_id(profile_id)
        if plan is None:
            return None
        return self._to_read_model(plan)

    def get_current_plan_for_user(self, user_id: int) -> InitialPlanRead | None:
        plan = self.repository.get_by_user_id(user_id)
        if plan is None:
            return None
        return self._to_read_model(plan)

    def personalize_plan(
        self,
        *,
        plan: InitialPlanRead,
        profile: UserProfile,
        context: PersonalizationContext,
    ) -> InitialPlanRead:
        workout_summary = plan.workout_summary
        nutrition_summary = plan.nutrition_summary
        habits_summary = plan.habits_summary
        priority = context.daily_priority or "Adherencia"
        depth = context.recommendation_depth or "Balanceada"
        proactive_adjustments = context.proactive_adjustments is not False

        if context.coach_style == "Exigente":
            workout_summary = (
                f"{workout_summary} Intensidad objetivo: disciplina alta, descansos medidos y foco tecnico."
            )
            nutrition_summary = (
                f"{nutrition_summary} Hoy la estructura va mas cerrada para reducir improvisacion."
            )
        elif context.coach_style == "Flexible":
            workout_summary = (
                f"{workout_summary} El plan admite una version corta si tu tiempo o energia bajan."
            )
            nutrition_summary = (
                f"{nutrition_summary} Se permiten equivalencias practicas para mantener adherencia."
            )
        else:
            habits_summary = (
                f"{habits_summary} Mantendremos equilibrio entre esfuerzo, recuperacion y consistencia."
            )

        if priority == "Rendimiento":
            workout_summary = (
                f"{workout_summary} La sesion del dia prioriza el bloque principal y una referencia de rendimiento."
            )
            nutrition_summary = (
                f"{nutrition_summary} Cargamos mejor el pre y post entreno para rendir mas util."
            )
        elif priority == "Recuperacion":
            workout_summary = (
                f"{workout_summary} La prioridad inmediata es descargar fatiga sin romper el ritmo semanal."
            )
            habits_summary = f"{habits_summary} Priorizamos sueno, hidratacion y percepcion de esfuerzo."
        else:
            habits_summary = f"{habits_summary} La prioridad actual es sostener adherencia simple y repetible."

        if depth == "Esencial":
            nutrition_summary = (
                f"{nutrition_summary} El sistema resumira la ejecucion en pocas decisiones claras."
            )
        elif depth == "Profunda":
            workout_summary = (
                f"{workout_summary} Incluye checkpoints tacticos para tecnica, descanso y progresion."
            )
            nutrition_summary = (
                f"{nutrition_summary} Anade criterios de reemplazo, timing y lectura de hambre."
            )

        if proactive_adjustments:
            habits_summary = (
                f"{habits_summary} El sistema puede sugerir microajustes segun adherencia y contexto diario."
            )

        return InitialPlanRead(
            id=plan.id,
            profile_id=plan.profile_id,
            workout_focus=plan.workout_focus,
            workout_summary=workout_summary,
            nutrition_summary=nutrition_summary,
            habits_summary=habits_summary,
            plan_payload=plan.plan_payload,
            created_at=plan.created_at,
        )

    @staticmethod
    def parse_generated_program(plan: InitialPlanRead) -> GeneratedProgram | None:
        if plan.plan_payload is None:
            return None
        return GeneratedProgram.model_validate(plan.plan_payload)

    @staticmethod
    def _to_read_model(plan: object) -> InitialPlanRead:
        payload = None
        raw_payload = getattr(plan, "plan_payload", None)
        if raw_payload:
            payload = json.loads(raw_payload)
        return InitialPlanRead.model_validate(
            {
                "id": plan.id,
                "profile_id": plan.profile_id,
                "workout_focus": plan.workout_focus,
                "workout_summary": plan.workout_summary,
                "nutrition_summary": plan.nutrition_summary,
                "habits_summary": plan.habits_summary,
                "plan_payload": payload,
                "created_at": plan.created_at,
            }
        )

    @staticmethod
    def _profile_context(profile: UserProfile) -> dict[str, object]:
        return {
            "full_name": profile.full_name,
            "age": profile.age,
            "height_cm": profile.height_cm,
            "weight_kg": profile.weight_kg,
            "goal": profile.goal,
            "activity_level": profile.activity_level,
            "workout_days_per_week": profile.workout_days_per_week,
            "session_minutes": profile.session_minutes,
            "training_location": profile.training_location,
            "cooking_style": profile.cooking_style,
            "meals_per_day": profile.meals_per_day,
            "equipment": json.loads(profile.equipment),
            "dietary_preferences": json.loads(profile.dietary_preferences),
            "allergies": json.loads(profile.allergies),
            "food_dislikes": json.loads(profile.food_dislikes),
            "restrictions": json.loads(profile.restrictions),
            "body_measurements": json.loads(profile.body_measurements),
            "additional_notes": profile.additional_notes,
        }
