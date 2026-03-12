from datetime import datetime

from app.ai.planning_models import GeneratedProgram
from app.core.personalization import PersonalizationContext
from app.models.user_profile import UserProfile
from app.repositories.activity_repository import ActivityRepository
from app.schemas.experience import (
    NutritionSummaryRead,
    ProgressSummaryRead,
    WorkoutSummaryRead,
)
from app.schemas.plan import InitialPlanRead
from app.services.plan_service import PlanService


class ExperienceService:
    def __init__(self, activity_repository: ActivityRepository) -> None:
        self.activity_repository = activity_repository

    @staticmethod
    def _priority_focus(priority: str) -> str:
        return priority or "Adherencia"

    @staticmethod
    def _depth_level(depth: str) -> str:
        return depth or "Balanceada"

    def build_workout(
        self,
        profile: UserProfile,
        plan: InitialPlanRead,
        context: PersonalizationContext,
    ) -> WorkoutSummaryRead:
        user_id = profile.user_id or 0
        priority = self._priority_focus(context.daily_priority)
        depth = self._depth_level(context.recommendation_depth)
        proactive_adjustments = context.proactive_adjustments is not False
        program = PlanService.parse_generated_program(plan)
        todays_workout = self._workout_for_today(program)
        energy_level = "Media"
        blocks = []
        sos_hint = "Si aparece dolor o no tienes equipo, sustituye por una variante equivalente."

        if todays_workout is not None:
            blocks = [
                {
                    "title": block.title,
                    "description": block.description,
                    "time_box": block.time_box,
                    "goal": block.goal,
                    "exercises": [
                        {
                            "name": exercise.name,
                            "sets": exercise.sets,
                            "reps": exercise.reps,
                            "rest": exercise.rest,
                            "notes": exercise.notes,
                        }
                        for exercise in block.exercises
                    ],
                }
                for block in todays_workout.blocks
            ]
            energy_level = todays_workout.intensity
            sos_hint = todays_workout.adaptation_hint

        if context.coach_style == "Exigente":
            energy_level = "Alta"
            if len(blocks) > 1:
                blocks[1]["description"] = (
                    f"{blocks[1]['description']} Hoy buscamos ejecucion decidida y descansos medidos."
                )
            sos_hint = "Reduce accesorios antes de tocar el bloque principal."
        elif context.coach_style == "Flexible":
            energy_level = "Baja"
            if len(blocks) > 2:
                blocks[2]["description"] = (
                    "Cierre opcional: puedes cambiarlo por movilidad o caminata rapida si el dia viene pesado."
                )
            sos_hint = "Recorta volumen si hace falta, pero conserva continuidad."

        if priority == "Rendimiento":
            energy_level = "Alta" if context.coach_style != "Flexible" else "Media"
            if len(blocks) > 1:
                blocks[1]["title"] = "Bloque de rendimiento"
                blocks[1]["description"] = (
                    f"{blocks[1]['description']} Incluye una serie marcador y una ultima serie de calidad."
                )
                blocks[1]["goal"] = "Mover mejor, medir una serie fuerte y registrar la sensacion final."
                blocks[1]["exercises"].append(
                    {
                        "name": "Serie marcador",
                        "sets": "1 serie",
                        "reps": "AMRAP tecnico",
                        "rest": "2 min",
                        "notes": "Corta cuando la tecnica se degrade.",
                    }
                )
            blocks.append(
                {
                    "title": "Marcador del dia",
                    "description": "Registra percepcion de esfuerzo y la mejor serie para comparar avance real.",
                    "time_box": "4 min",
                    "goal": "Dejar trazabilidad de como rindio tu cuerpo hoy.",
                    "exercises": [{"name": "Nota de esfuerzo y mejor serie", "sets": "1 registro", "reps": "RPE + carga", "rest": "-", "notes": "Deja trazabilidad."}],
                }
            )
            sos_hint = "Si el rendimiento cae, reduce una serie y protege la calidad tecnica."
        elif priority == "Recuperacion":
            energy_level = "Baja"
            if blocks:
                blocks[0]["description"] = "Entrada larga con movilidad, respiracion y preparacion progresiva."
            if len(blocks) > 1:
                blocks[1]["title"] = "Bloque de control"
                blocks[1]["description"] = (
                    "Trabajo tecnico con volumen moderado, tempos estables y margen amplio para salir fresco."
                )
                blocks[1]["goal"] = "Mantener tecnica y sensacion de control."
            if len(blocks) > 2:
                blocks[2]["title"] = "Salida de recuperacion"
                blocks[2]["description"] = (
                    "Movilidad guiada, descarga ligera y respiracion para cerrar la sesion sin fatiga extra."
                )
                blocks[2]["goal"] = "Recuperar rango y bajar pulsaciones."
            sos_hint = "Hoy vale mas terminar mejor de lo que empezaste que perseguir volumen."

        if depth == "Esencial":
            blocks = blocks[:2]
            sos_hint = f"{sos_hint} Mantente en dos bloques y una sola consigna tecnica."
        elif depth == "Profunda":
            blocks.append(
                {
                    "title": "Checklist tecnico",
                    "description": "Define un patron a vigilar, una pausa objetivo y un criterio claro para cortar a tiempo.",
                    "time_box": "3 min",
                    "goal": "No perder calidad cuando sube el cansancio.",
                    "exercises": [
                        {
                            "name": "Checklist post sesion",
                            "sets": "3 preguntas",
                            "reps": "Tecnica / fatiga / dolor",
                            "rest": "-",
                        }
                    ],
                }
            )

        if context.full_access_active and proactive_adjustments:
            blocks.append(
                {
                    "title": "Ajuste adaptativo",
                    "description": "Microajuste segun energia percibida, adherencia reciente y tiempo restante del dia.",
                    "time_box": "2 min",
                    "goal": "Decidir si subir, mantener o recortar sin improvisar.",
                    "exercises": [{"name": "Decision adaptativa", "sets": "1 ajuste", "reps": "Subir / mantener / recortar", "rest": "-", "notes": "Evalua energia, dolor y tiempo real."}],
                }
            )

        return WorkoutSummaryRead(
            title=todays_workout.session_title if todays_workout is not None else f"Sesion adaptativa de {profile.session_minutes} min",
            duration_minutes=todays_workout.duration_minutes if todays_workout is not None else profile.session_minutes,
            focus=todays_workout.focus if todays_workout is not None else plan.workout_focus,
            energy_level=energy_level,
            blocks=blocks,
            sos_hint=sos_hint,
            completed_sessions=self.activity_repository.workout_count(user_id=user_id, days=7),
            completed_today=self.activity_repository.workout_completed_today(user_id=user_id),
            weekly_calendar=self.activity_repository.weekly_workout_calendar(
                user_id=user_id,
                target_per_week=profile.workout_days_per_week,
            ),
        )

    def build_nutrition(
        self,
        profile: UserProfile,
        plan: InitialPlanRead,
        context: PersonalizationContext,
    ) -> NutritionSummaryRead:
        priority = self._priority_focus(context.daily_priority)
        depth = self._depth_level(context.recommendation_depth)
        proactive_adjustments = context.proactive_adjustments is not False
        program = PlanService.parse_generated_program(plan)
        calorie_target = program.calorie_target if program is not None else (
            "1900 kcal" if "grasa" in profile.goal.lower() else "2400 kcal"
        )
        adherence_score = self.activity_repository.nutrition_average(user_id=profile.user_id or 0)
        meals = self._build_meals_from_program(program)
        macro_focus = program.macro_focus if program is not None else ["Proteina alta", "Fibra", "Comidas simples"]
        swap_tip = plan.nutrition_summary

        if context.coach_style == "Exigente":
            macro_focus = ["Proteina dominante", "Timing de comidas", "Cero improvisacion"]
            if meals:
                meals[0]["meal"] = f"{meals[0]['meal']} con estructura fija"
        elif context.coach_style == "Flexible":
            macro_focus = ["Equivalencias rapidas", "Proteina base", "Saciedad"]
            swap_tip = f"{swap_tip} Si no llegas a una comida ideal, usa una alternativa equivalente y sigue."

        if priority == "Rendimiento":
            macro_focus = ["Energia util", "Proteina dominante", "Carbohidrato alrededor del entreno"]
            if len(meals) > 1:
                meals[1]["meal"] = f"{meals[1]['meal']} para sostener rendimiento"
                meals[1]["objective"] = "Asegurar combustible util antes o despues del entreno."
            swap_tip = f"{swap_tip} Prioriza una comida pre o post entreno con carbohidrato facil de digerir."
        elif priority == "Recuperacion":
            macro_focus = ["Saciedad", "Hidratacion", "Digestiones simples"]
            if len(meals) > 2:
                meals[2]["meal"] = "Cena suave con proteina magra, verduras cocidas y carbohidrato moderado"
                meals[2]["objective"] = "Favorecer recuperacion y bajar friccion digestiva."
            swap_tip = f"{swap_tip} Hoy conviene bajar friccion digestiva y reforzar hidratacion."

        if depth == "Esencial":
            meals = meals[:2]
            swap_tip = f"{swap_tip} Enfocate en dos comidas ancla y una colacion simple si la necesitas."
        elif depth == "Profunda":
            meals.append(
                {
                    "title": "Guia de decision",
                    "meal": "Usa hambre, horario real y adherencia previa para decidir porcion y reemplazo.",
                    "macros": "Contextual",
                    "objective": "Tomar mejores decisiones sin improvisar.",
                    "components": ["Hambre", "Horario", "Contexto", "Adherencia"],
                    "swap_options": [
                        "Proteina primero",
                        "Carbohidrato segun entreno",
                    ],
                    "weekly_plan": [],
                    "option_bank": [],
                }
            )

        if context.full_access_active and proactive_adjustments:
            meals.append(
                {
                    "title": "Ajuste adaptativo",
                    "meal": "Snack de proteina o colacion puente segun horario real y adherencia de la semana",
                    "macros": "20P / 15C / 8G",
                    "objective": "Evitar huecos largos y llegar mejor a la siguiente comida.",
                    "components": ["Proteina rapida", "Fruta o carbohidrato", "Grasa ligera"],
                    "swap_options": [
                        "Yogurt + fruta",
                        "Sandwich pequeno de pavo",
                    ],
                    "weekly_plan": [],
                    "option_bank": [],
                }
            )
            swap_tip = f"{swap_tip} Incluye timing flexible y reemplazos guiados por tu contexto."

        return NutritionSummaryRead(
            title="Marco nutricional del dia",
            calorie_target=calorie_target,
            macro_focus=macro_focus,
            meals=meals,
            swap_tip=swap_tip,
            adherence_score=adherence_score,
        )

    def build_progress(
        self,
        profile: UserProfile,
        plan: InitialPlanRead,
        context: PersonalizationContext,
    ) -> ProgressSummaryRead:
        user_id = profile.user_id or 0
        priority = self._priority_focus(context.daily_priority)
        depth = self._depth_level(context.recommendation_depth)
        streak_days = self.activity_repository.workout_streak_days(user_id=user_id)
        completed_sessions = self.activity_repository.workout_count(user_id=user_id, days=30)
        weekly_adherence = self.activity_repository.nutrition_average(user_id=user_id)
        first_metric = self.activity_repository.first_body_metric(user_id=user_id)
        latest_metric = self.activity_repository.latest_body_metric(user_id=user_id)
        weekly_target = profile.workout_days_per_week
        weekly_completed = self.activity_repository.workout_count(user_id=user_id, days=7)
        completion_rate = min(100, int(round((weekly_completed / weekly_target) * 100))) if weekly_target else 0
        weight_series = [
            {
                "label": metric.recorded_at.strftime("%d/%m"),
                "value": round(metric.weight_kg, 1),
            }
            for metric in self.activity_repository.weight_series(user_id=user_id)
        ]
        adherence_series = [
            {"label": key[-5:], "value": value}
            for key, value in sorted(
                self.activity_repository.daily_nutrition_average(user_id=user_id).items()
            )
        ]

        weight_trend = "Sin registros suficientes"
        if first_metric is not None and latest_metric is not None:
            delta = latest_metric.weight_kg - first_metric.weight_kg
            if abs(delta) < 0.1:
                weight_trend = "Peso estable desde tu primer registro"
            else:
                direction = "subida" if delta > 0 else "bajada"
                weight_trend = f"{abs(delta):.1f} kg de {direction} desde tu primer registro"

        return ProgressSummaryRead(
            streak_days=streak_days,
            weekly_adherence=weekly_adherence,
            weight_trend=weight_trend,
            completed_sessions=completed_sessions,
            latest_weight_kg=latest_metric.weight_kg if latest_metric is not None else None,
            weekly_workout_target=weekly_target,
            workout_completion_rate=completion_rate,
            weight_series=weight_series,
            adherence_series=adherence_series,
            insights=[
                {
                    "title": "Adherencia",
                    "note": f"Tu media nutricional reciente es de {weekly_adherence}% y la racha actual es de {streak_days} dias.",
                },
                {
                    "title": "Recuperacion",
                    "note": (
                        "El plan mantiene volumen sostenible para tu tiempo disponible."
                        if context.coach_style != "Exigente"
                        else "El plan empuja una progresion mas firme sin perder control tecnico."
                    ),
                },
                {
                    "title": "Direccion",
                    "note": (
                        f"{plan.habits_summary} Priorizando rendimiento medible esta semana."
                        if priority == "Rendimiento"
                        else (
                            f"{plan.habits_summary} Priorizando recuperacion y sostenibilidad."
                            if priority == "Recuperacion"
                            else plan.habits_summary
                        )
                    ),
                },
                {
                    "title": "Nivel de detalle",
                    "note": (
                        "Estamos usando una lectura profunda para detectar ajustes finos."
                        if depth == "Profunda"
                        else "Mantendremos un marco compacto para que el seguimiento sea facil."
                    ),
                },
            ],
        )

    @staticmethod
    def _workout_for_today(program: GeneratedProgram | None):
        if program is None or not program.weekly_workouts:
            return None
        return program.weekly_workouts[datetime.now().weekday() % len(program.weekly_workouts)]

    @staticmethod
    def _build_meals_from_program(program: GeneratedProgram | None) -> list[dict[str, object]]:
        if program is None:
            return [
                {
                    "title": "Desayuno",
                    "meal": "Yogurt griego, avena y frutos rojos",
                    "macros": "35P / 45C / 14G",
                    "objective": "Abrir el dia con proteina y energia estable.",
                    "components": ["Yogurt griego", "Avena", "Fruta", "Semillas"],
                    "swap_options": [
                        "Batido de proteina + fruta + avena",
                        "Huevos + tostadas + fruta",
                    ],
                    "weekly_plan": [],
                    "option_bank": [],
                },
                {
                    "title": "Almuerzo",
                    "meal": "Pollo, arroz y vegetales crujientes",
                    "macros": "42P / 55C / 16G",
                    "objective": "Sostener energia y evitar hambre reactiva por la tarde.",
                    "components": ["Pollo", "Arroz", "Vegetales", "Aceite de oliva"],
                    "swap_options": [
                        "Carne magra + papa + ensalada",
                        "Bowl de atún con arroz y verduras",
                    ],
                    "weekly_plan": [],
                    "option_bank": [],
                },
                {
                    "title": "Cena",
                    "meal": "Wrap de atun con hummus y ensalada",
                    "macros": "34P / 28C / 12G",
                    "objective": "Cerrar con saciedad y digestion simple.",
                    "components": ["Atun", "Wrap", "Hummus", "Ensalada"],
                    "swap_options": [
                        "Huevos + arepa + ensalada",
                        "Pollo + verduras cocidas + arroz",
                    ],
                    "weekly_plan": [],
                    "option_bank": [],
                },
            ]

        today_index = datetime.now().weekday() % 7
        meals: list[dict[str, object]] = []
        for slot in program.meal_slots:
            entry = slot.weekly_plan[today_index]
            meals.append(
                {
                    "title": slot.title,
                    "meal": entry.meal_name,
                    "macros": entry.macros,
                    "objective": slot.objective,
                    "components": entry.components,
                    "swap_options": entry.swap_options,
                    "detail": entry.detail,
                    "preparation": entry.preparation,
                    "weekly_plan": [
                        {
                            "day_label": item.day_label,
                            "meal_name": item.meal_name,
                            "detail": item.detail,
                            "macros": item.macros,
                            "components": item.components,
                            "preparation": item.preparation,
                            "swap_options": item.swap_options,
                        }
                        for item in slot.weekly_plan
                    ],
                    "option_bank": [
                        {
                            "name": option.name,
                            "summary": option.summary,
                            "macros": option.macros,
                            "ingredients": option.ingredients,
                            "preparation": option.preparation,
                            "best_for": option.best_for,
                        }
                        for option in slot.option_bank
                    ],
                }
            )
        return meals
