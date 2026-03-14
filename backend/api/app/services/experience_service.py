import json
from datetime import UTC, datetime, timedelta

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
        self.activity_repository.sync_exercise_catalog(program=program)
        week_start_date = self._plan_anchor_date(plan)
        weekly_calendar = self.activity_repository.weekly_workout_calendar(
            user_id=user_id,
            target_per_week=profile.workout_days_per_week,
            start_date=week_start_date,
        )
        weekly_days = self._build_weekly_workout_days(
            user_id=user_id,
            plan_id=plan.id,
            program=program,
            weekly_calendar=weekly_calendar,
            catalog=self.activity_repository.exercise_catalog_map(),
        )
        selected_day_index = next(
            (index for index, item in enumerate(weekly_days) if item.get("is_today") is True),
            0,
        )
        todays_workout = weekly_days[selected_day_index] if weekly_days else None
        energy_level = "Media"
        blocks = []
        sos_hint = "Si aparece dolor o no tienes equipo, sustituye por una variante equivalente."

        if todays_workout is not None:
            blocks = [
                dict(block)
                for block in todays_workout.get("blocks", [])
            ]
            energy_level = todays_workout.get("intensity", "Media")
            sos_hint = todays_workout.get("adaptation_hint", sos_hint)

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
            title=(
                todays_workout.get("session_title")
                if todays_workout is not None
                else f"Sesion adaptativa de {profile.session_minutes} min"
            ),
            duration_minutes=(
                int(todays_workout.get("duration_minutes", profile.session_minutes))
                if todays_workout is not None
                else profile.session_minutes
            ),
            focus=todays_workout.get("focus") if todays_workout is not None else plan.workout_focus,
            energy_level=energy_level,
            blocks=blocks,
            sos_hint=sos_hint,
            completed_sessions=self.activity_repository.workout_count(user_id=user_id, days=7),
            completed_today=self.activity_repository.workout_completed_today(user_id=user_id),
            selected_day_index=selected_day_index,
            plan_id=plan.id,
            weekly_calendar=weekly_calendar,
            weekly_days=weekly_days,
        )

    def build_nutrition(
        self,
        profile: UserProfile,
        plan: InitialPlanRead,
        context: PersonalizationContext,
    ) -> NutritionSummaryRead:
        user_id = profile.user_id or 0
        priority = self._priority_focus(context.daily_priority)
        depth = self._depth_level(context.recommendation_depth)
        proactive_adjustments = context.proactive_adjustments is not False
        program = PlanService.parse_generated_program(plan)
        calorie_target_raw = program.calorie_target if program is not None else (
            "1900 kcal" if "grasa" in profile.goal.lower() else "2400 kcal"
        )
        calorie_target = self._parse_number(calorie_target_raw, fallback=2000)
        adherence_score = self.activity_repository.nutrition_average(user_id=user_id)
        week_start_date = self._plan_anchor_date(plan)
        weekly_calendar = self.activity_repository.weekly_workout_calendar(
            user_id=user_id,
            target_per_week=profile.workout_days_per_week,
            start_date=week_start_date,
        )
        weekly_days = self._build_weekly_nutrition_days(program, weekly_calendar)
        selected_day_index = next(
            (index for index, item in enumerate(weekly_days) if item.get("is_today") is True),
            0,
        )
        meals = weekly_days[selected_day_index]["meals"] if weekly_days else self._build_meals_from_program(program)
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

        today_day = next(
            (item for item in weekly_days if item.get("is_today") is True),
            weekly_days[selected_day_index] if weekly_days else None,
        )
        nutrition_metrics = self._summarize_nutrition_day(
            user_id=user_id,
            iso_date=today_day.get("iso_date", "") if today_day is not None else "",
            meals=(
                [
                    dict(item)
                    for item in today_day.get("meals", [])
                ]
                if today_day is not None
                else []
            ),
            calorie_target=calorie_target,
        )

        return NutritionSummaryRead(
            title="Marco nutricional del dia",
            calorie_target=calorie_target,
            calories_consumed_today=nutrition_metrics["calories_consumed_today"],
            protein_target_g=nutrition_metrics["protein_target_g"],
            protein_consumed_g=nutrition_metrics["protein_consumed_g"],
            carbs_target_g=nutrition_metrics["carbs_target_g"],
            carbs_consumed_g=nutrition_metrics["carbs_consumed_g"],
            fat_target_g=nutrition_metrics["fat_target_g"],
            fat_consumed_g=nutrition_metrics["fat_consumed_g"],
            water_target_l=nutrition_metrics["water_target_l"],
            water_consumed_l=nutrition_metrics["water_consumed_l"],
            macro_focus=macro_focus,
            meals=meals,
            swap_tip=swap_tip,
            adherence_score=adherence_score,
            selected_day_index=selected_day_index,
            plan_id=plan.id,
            weekly_days=weekly_days,
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

    def _build_weekly_workout_days(
        self,
        *,
        user_id: int,
        plan_id: int,
        program: GeneratedProgram | None,
        weekly_calendar: list[dict[str, object]],
        catalog: dict[str, object],
    ) -> list[dict[str, object]]:
        days: list[dict[str, object]] = []
        for calendar_entry in weekly_calendar:
            weekday_index = int(calendar_entry.get("weekday_index", 0))
            iso_date = calendar_entry.get("iso_date", "")
            block_states = self.activity_repository.block_state_map(
                user_id=user_id,
                plan_id=plan_id,
                day_iso_date=str(iso_date),
            )
            if program is None or not program.weekly_workouts:
                days.append(
                    {
                        "day_label": calendar_entry.get("label", ""),
                        "date": calendar_entry.get("date", ""),
                        "iso_date": calendar_entry.get("iso_date", ""),
                        "is_today": calendar_entry.get("is_today", False),
                        "is_past": calendar_entry.get("is_past", False),
                        "completed_sessions": calendar_entry.get("completed_sessions", 0),
                        "goal_hit": calendar_entry.get("goal_hit", False),
                        "session_title": "Sesion adaptativa",
                        "focus": "Foco adaptativo",
                        "objective": "",
                        "duration_minutes": 45,
                        "intensity": "Media",
                        "blocks": [],
                        "adaptation_hint": "",
                        "plan_id": plan_id,
                    }
                )
                continue

            workout = program.weekly_workouts[weekday_index % len(program.weekly_workouts)]
            days.append(
                {
                    "day_label": workout.day_label,
                    "date": calendar_entry.get("date", ""),
                    "iso_date": calendar_entry.get("iso_date", ""),
                    "is_today": calendar_entry.get("is_today", False),
                    "is_past": calendar_entry.get("is_past", False),
                    "completed_sessions": calendar_entry.get("completed_sessions", 0),
                    "goal_hit": calendar_entry.get("goal_hit", False),
                    "session_title": workout.session_title,
                    "focus": workout.focus,
                    "objective": workout.objective,
                    "duration_minutes": workout.duration_minutes,
                    "intensity": workout.intensity,
                    "adaptation_hint": workout.adaptation_hint,
                    "plan_id": plan_id,
                    "warmup": list(workout.warmup),
                    "cooldown": list(workout.cooldown),
                    "blocks": [
                        self._serialize_block(
                            block=block,
                            block_state=block_states.get(block.title, {}),
                            catalog=catalog,
                        )
                        for block in workout.blocks
                    ],
                }
            )
        return days

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

    @staticmethod
    def _build_weekly_nutrition_days(
        program: GeneratedProgram | None,
        weekly_calendar: list[dict[str, object]],
    ) -> list[dict[str, object]]:
        if program is None:
            return [
                {
                    "day_label": entry.get("label", ""),
                    "date": entry.get("date", ""),
                    "iso_date": entry.get("iso_date", ""),
                    "is_today": entry.get("is_today", False),
                    "is_past": entry.get("is_past", False),
                    "meals": ExperienceService._build_meals_from_program(None),
                }
                for entry in weekly_calendar
            ]

        days: list[dict[str, object]] = []
        for calendar_entry in weekly_calendar:
            weekday_index = int(calendar_entry.get("weekday_index", 0))
            meals: list[dict[str, object]] = []
            for slot in program.meal_slots:
                if not slot.weekly_plan:
                    continue
                entry = slot.weekly_plan[weekday_index % len(slot.weekly_plan)]
                meals.append(
                    {
                        "title": slot.title,
                        "meal": entry.meal_name,
                        "meal_name": entry.meal_name,
                        "macros": entry.macros,
                        "objective": slot.objective,
                        "detail": entry.detail,
                        "components": list(entry.components),
                        "preparation": entry.preparation,
                        "swap_options": list(entry.swap_options),
                        "calories_kcal": entry.calories_kcal,
                        "protein_g": entry.protein_g,
                        "carbs_g": entry.carbs_g,
                        "fat_g": entry.fat_g,
                        "fiber_g": entry.fiber_g,
                        "cooking_time_minutes": entry.cooking_time_minutes,
                        "ingredients_with_quantities": list(entry.ingredients_with_quantities),
                        "preparation_steps": list(entry.preparation_steps),
                        "allergens": list(entry.allergens),
                        "weekly_plan": [
                            {
                                "day_label": item.day_label,
                                "meal_name": item.meal_name,
                                "detail": item.detail,
                                "macros": item.macros,
                                "components": list(item.components),
                                "preparation": item.preparation,
                                "swap_options": list(item.swap_options),
                            }
                            for item in slot.weekly_plan
                        ],
                        "option_bank": [
                            {
                                "name": option.name,
                                "summary": option.summary,
                                "macros": option.macros,
                                "ingredients": list(option.ingredients),
                                "preparation": option.preparation,
                                "best_for": option.best_for,
                                "calories_kcal": option.calories_kcal,
                                "protein_g": option.protein_g,
                                "carbs_g": option.carbs_g,
                                "fat_g": option.fat_g,
                                "fiber_g": option.fiber_g,
                                "cooking_time_minutes": option.cooking_time_minutes,
                                "ingredients_with_quantities": list(option.ingredients_with_quantities),
                                "preparation_steps": list(option.preparation_steps),
                                "allergens": list(option.allergens),
                            }
                            for option in slot.option_bank
                        ],
                    }
                )
            days.append(
                {
                    "day_label": program.weekly_workouts[weekday_index % len(program.weekly_workouts)].day_label
                    if program.weekly_workouts
                    else calendar_entry.get("label", ""),
                    "date": calendar_entry.get("date", ""),
                    "iso_date": calendar_entry.get("iso_date", ""),
                    "is_today": calendar_entry.get("is_today", False),
                    "is_past": calendar_entry.get("is_past", False),
                    "completed_sessions": calendar_entry.get("completed_sessions", 0),
                    "goal_hit": calendar_entry.get("goal_hit", False),
                    "meals": meals,
                }
            )
        return days

    @staticmethod
    def _plan_anchor_date(plan: InitialPlanRead):
        created = plan.created_at.astimezone(UTC) if plan.created_at.tzinfo else plan.created_at.replace(tzinfo=UTC)
        today = datetime.now(UTC).date()
        if 0 <= (today - created.date()).days <= 1 and created >= datetime.now(UTC) - timedelta(hours=36):
            return today
        return created.date()

    @staticmethod
    def _parse_number(value: object, fallback: float = 0) -> float:
        if value is None:
            return fallback
        if isinstance(value, (int, float)):
            return float(value)
        cleaned = "".join(ch for ch in str(value) if ch.isdigit() or ch in {".", ","}).replace(",", ".")
        return float(cleaned) if cleaned else fallback

    @staticmethod
    def _parse_macro_string(value: object) -> tuple[float, float, float]:
        if value is None:
            return 0.0, 0.0, 0.0
        text = str(value).upper()
        protein = carbs = fat = 0.0
        for chunk in text.replace(" ", "").split("/"):
            if chunk.endswith("P"):
                protein = ExperienceService._parse_number(chunk[:-1], fallback=0)
            elif chunk.endswith("C"):
                carbs = ExperienceService._parse_number(chunk[:-1], fallback=0)
            elif chunk.endswith("G"):
                fat = ExperienceService._parse_number(chunk[:-1], fallback=0)
        return protein, carbs, fat

    @staticmethod
    def _normalize_meal_label(value: object) -> str:
        return str(value or "").strip().lower()

    def _summarize_nutrition_day(
        self,
        *,
        user_id: int,
        iso_date: str,
        meals: list[dict[str, object]],
        calorie_target: float,
    ) -> dict[str, float]:
        logs = (
            self.activity_repository.nutrition_logs_for_day(user_id=user_id, day_iso_date=iso_date)
            if iso_date
            else []
        )
        meal_by_label = {
            self._normalize_meal_label(meal.get("title")): meal
            for meal in meals
        }
        protein_target = carbs_target = fat_target = 0.0
        for meal in meals:
            protein_value = self._parse_number(meal.get("protein_g"), fallback=0)
            carbs_value = self._parse_number(meal.get("carbs_g"), fallback=0)
            fat_value = self._parse_number(meal.get("fat_g"), fallback=0)
            if protein_value == 0 and carbs_value == 0 and fat_value == 0:
                protein_value, carbs_value, fat_value = self._parse_macro_string(meal.get("macros"))
            protein_target += protein_value
            carbs_target += carbs_value
            fat_target += fat_value

        calories_consumed = protein_consumed = carbs_consumed = fat_consumed = 0.0
        water_consumed = 0.0
        for log in logs:
            matched_meal = meal_by_label.get(self._normalize_meal_label(log.meal_label))
            if matched_meal is not None:
                calories_consumed += self._parse_number(matched_meal.get("calories_kcal"), fallback=0)
                planned_protein = self._parse_number(matched_meal.get("protein_g"), fallback=0)
                planned_carbs = self._parse_number(matched_meal.get("carbs_g"), fallback=0)
                planned_fat = self._parse_number(matched_meal.get("fat_g"), fallback=0)
                if planned_protein == 0 and planned_carbs == 0 and planned_fat == 0:
                    planned_protein, planned_carbs, planned_fat = self._parse_macro_string(matched_meal.get("macros"))
                protein_consumed += float(log.protein_grams or planned_protein)
                carbs_consumed += planned_carbs
                fat_consumed += planned_fat
            else:
                protein_consumed += float(log.protein_grams or 0)
            water_consumed += float(log.hydration_liters or 0)

        return {
            "calories_consumed_today": calories_consumed,
            "protein_target_g": protein_target,
            "protein_consumed_g": protein_consumed,
            "carbs_target_g": carbs_target,
            "carbs_consumed_g": carbs_consumed,
            "fat_target_g": fat_target,
            "fat_consumed_g": fat_consumed,
            "water_target_l": 2.5,
            "water_consumed_l": water_consumed,
            "calorie_target": calorie_target,
        }

    @staticmethod
    def _catalog_entry(catalog: dict[str, object], name: str) -> dict[str, object]:
        item = catalog.get(name)
        if item is None:
            return {
                "name": name,
                "muscle_group": None,
                "location": None,
                "notes": "",
                "image_url": None,
                "substitutions": [],
            }
        return {
            "name": item.name,
            "muscle_group": item.muscle_group,
            "location": item.location,
            "notes": item.default_notes,
            "image_url": item.image_url,
            "substitutions": json.loads(item.substitutions_json or "[]"),
        }

    def _serialize_block(
        self,
        *,
        block,
        block_state: dict[str, object],
        catalog: dict[str, object],
    ) -> dict[str, object]:
        selected_exercises = {
            item for item in (block_state.get("selected_exercises", []) or [])
        }
        exercises = []
        substitutions = []
        for exercise in block.exercises:
            exercise_catalog = self._catalog_entry(catalog, exercise.name)
            exercises.append(
                {
                    "name": exercise.name,
                    "sets": exercise.sets,
                    "reps": exercise.reps,
                    "rest": exercise.rest,
                    "notes": exercise.notes,
                    "muscle_group": exercise.muscle_group,
                    "location": exercise.location,
                    "substitutions": list(exercise.substitutions),
                    "image_url": exercise.image_url,
                    "is_selected": not selected_exercises or exercise.name in selected_exercises,
                    "catalog": exercise_catalog,
                }
            )
            for substitution_name in exercise.substitutions:
                item = self._catalog_entry(catalog, substitution_name)
                substitutions.append(
                    {
                        **item,
                        "for_exercise": exercise.name,
                        "is_selected": substitution_name in selected_exercises,
                    }
                )
        return {
            "title": block.title,
            "description": block.description,
            "time_box": block.time_box,
            "goal": block.goal,
            "muscle_group": ", ".join(
                sorted({exercise.muscle_group for exercise in block.exercises if exercise.muscle_group})
            ),
            "location": next((exercise.location for exercise in block.exercises if exercise.location), None),
            "substitutions": substitutions[:8],
            "completed": bool(block_state.get("completed", False)),
            "selected_exercises": list(selected_exercises),
            "exercises": exercises,
        }
