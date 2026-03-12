import json

from app.core.personalization import PersonalizationContext
from app.repositories.activity_repository import ActivityRepository
from app.repositories.plan_repository import PlanRepository
from app.repositories.profile_repository import ProfileRepository
from app.schemas.onboarding import DashboardSummary, UserProfileCreate, UserProfileRead
from app.services.plan_service import PlanService


class OnboardingService:
    def __init__(
        self,
        repository: ProfileRepository,
        plan_service: PlanService,
        activity_repository: ActivityRepository,
    ) -> None:
        self.repository = repository
        self.plan_service = plan_service
        self.activity_repository = activity_repository

    def create_profile(self, *, user_id: int, payload: UserProfileCreate) -> UserProfileRead:
        profile = self.repository.upsert_latest_profile(user_id=user_id, payload=payload)
        self.plan_service.generate_for_profile(profile)
        return self._to_read_model(profile)

    def get_latest_profile(self, user_id: int) -> UserProfileRead | None:
        profile = self.repository.get_latest_for_user(user_id)
        if profile is None:
            return None
        return self._to_read_model(profile)

    def get_dashboard_summary(
        self,
        user_id: int,
        context: PersonalizationContext,
    ) -> DashboardSummary:
        profile = self.repository.get_latest_for_user(user_id)
        if profile is None:
            return DashboardSummary(
                headline="Completa tu onboarding",
                workout_focus="Cuéntanos tu objetivo y el tiempo disponible para construir tu primer plan.",
                nutrition_focus="Agregaremos lineamientos nutricionales en cuanto tengamos tu perfil.",
                adherence_message="Tu experiencia adaptativa empieza con una anamnesis breve.",
                current_plan_summary="Cuando completes el perfil generaremos tu primera estructura de trabajo.",
            )

        goal = profile.goal.lower()
        plan = self.plan_service.get_current_plan_for_user(user_id)
        if plan is None:
            plan = self.plan_service.generate_for_profile(profile)
        plan = self.plan_service.personalize_plan(
            plan=plan,
            profile=profile,
            context=context,
        )

        workout_streak = self.activity_repository.workout_streak_days(user_id=user_id)
        weekly_adherence = self.activity_repository.nutrition_average(user_id=user_id)

        return DashboardSummary(
            headline=self._headline(profile.full_name, goal, context),
            workout_focus=self._workout_focus(goal, profile.session_minutes, context),
            nutrition_focus=self._nutrition_focus(goal, context),
            adherence_message=(
                f"Llevas {workout_streak} dias de racha y una adherencia nutricional de {weekly_adherence}%."
            ),
            current_plan_summary=plan.workout_summary,
            streak_days=workout_streak,
            weekly_adherence=weekly_adherence,
        )

    @staticmethod
    def _to_read_model(profile: object) -> UserProfileRead:
        return UserProfileRead.model_validate(
            {
                "id": profile.id,
                "user_id": profile.user_id,
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
                "created_at": profile.created_at,
                "updated_at": profile.updated_at,
            }
        )

    @staticmethod
    def _headline(full_name: str, goal: str, context: PersonalizationContext) -> str:
        prefix = {
            "Exigente": "Vamos con foco total,",
            "Flexible": "Vamos a sostener el ritmo,",
        }.get(context.coach_style, "Hola")
        if prefix == "Hola":
            return f"Hola {full_name}, hoy seguimos con {goal}"
        return f"{prefix} {full_name}: hoy seguimos con {goal}"

    @staticmethod
    def _workout_focus(goal: str, session_minutes: int, context: PersonalizationContext) -> str:
        if "mus" in goal:
            base = f"Sesion de fuerza de {session_minutes} minutos con foco en progresion de cargas."
        elif "grasa" in goal or "peso" in goal:
            base = f"Sesion metabolica de {session_minutes} minutos con base de fuerza y acondicionamiento."
        else:
            base = f"Sesion equilibrada de {session_minutes} minutos orientada a constancia y movilidad."
        if context.daily_priority == "Rendimiento":
            return f"{base} Hoy empujaremos el bloque principal y registraremos un marcador claro del dia."
        if context.daily_priority == "Recuperacion":
            return f"{base} Hoy la estructura baja friccion y protege recuperacion sin perder continuidad."
        if context.full_access_active and context.proactive_adjustments is not False:
            return f"{base} Incluye ajuste adaptativo segun energia y tiempo real."
        if context.coach_style == "Flexible":
            return f"{base} Tendras margen para una version reducida si el dia se aprieta."
        return base

    @staticmethod
    def _nutrition_focus(goal: str, context: PersonalizationContext) -> str:
        if "mus" in goal:
            base = "Prioriza proteina suficiente, distribucion de comidas y recuperacion post entrenamiento."
        elif "grasa" in goal or "peso" in goal:
            base = "Mantendremos un enfoque de saciedad, proteina alta y estructura sencilla para adherencia."
        else:
            base = "Trabajaremos habitos base, hidratacion y comidas repetibles durante la semana."
        if context.coach_style == "Exigente":
            return f"{base} Hoy buscamos estructura estricta y ejecucion limpia."
        if context.daily_priority == "Rendimiento":
            return f"{base} Sumamos energia util antes y despues del entreno para rendir mejor."
        if context.daily_priority == "Recuperacion":
            return f"{base} Priorizaremos digestiones simples, hidratacion y menor carga de decision."
        if context.full_access_active and context.proactive_adjustments is not False:
            return f"{base} Sumamos reemplazos inteligentes y timing flexible."
        return base
