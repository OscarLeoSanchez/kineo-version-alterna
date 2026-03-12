import json
from abc import ABC, abstractmethod
from collections.abc import Iterable

from openai import OpenAI

from app.ai.planning_models import GeneratedProgram
from app.core.config import settings


class AIPlanningProvider(ABC):
    @abstractmethod
    def generate_program(self, profile_context: dict[str, object]) -> GeneratedProgram:
        raise NotImplementedError


class OpenAIPlanningProvider(AIPlanningProvider):
    def __init__(self) -> None:
        self.client = OpenAI(
            api_key=settings.ai_api_key,
            base_url=settings.ai_base_url or None,
        )

    def generate_program(self, profile_context: dict[str, object]) -> GeneratedProgram:
        schema = GeneratedProgram.model_json_schema()
        response = self.client.responses.create(
            model=settings.ai_model,
            input=[
                {
                    "role": "system",
                    "content": [
                        {
                            "type": "input_text",
                            "text": (
                                "Eres un coach de fitness y nutricion clinicamente prudente. "
                                "Debes devolver exclusivamente JSON valido y util para una app movil. "
                                "El plan debe ser realista, altamente personalizado y accionable."
                            ),
                        }
                    ],
                },
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "input_text",
                            "text": (
                                "Crea un programa semanal de entrenamiento y nutricion para este usuario. "
                                "Reglas obligatorias: "
                                "1) weekly_workouts debe traer exactamente 7 dias. "
                                "2) meal_slots debe incluir Desayuno, Almuerzo, Cena y Snack. "
                                "3) Cada meal slot debe traer exactamente 10 opciones detalladas en option_bank. "
                                "4) weekly_plan debe cubrir 7 dias para cada meal slot. "
                                "5) El plan debe respetar restricciones, equipo, preferencias y notas adicionales. "
                                "6) No uses lenguaje medico, no prometas resultados y no incluyas texto fuera del JSON. "
                                f"Perfil del usuario: {json.dumps(profile_context, ensure_ascii=True)}"
                            ),
                        }
                    ],
                },
            ],
            reasoning={"effort": "medium"},
            text={
                "format": {
                    "type": "json_schema",
                    "name": "kineo_generated_program",
                    "schema": schema,
                    "strict": True,
                }
            },
        )
        return GeneratedProgram.model_validate_json(response.output_text)


class DeterministicPlanningProvider(AIPlanningProvider):
    def generate_program(self, profile_context: dict[str, object]) -> GeneratedProgram:
        goal = str(profile_context.get("goal", "Mejorar condicion fisica"))
        focus = "Recomposicion y adherencia" if "grasa" in goal.lower() else "Base de fuerza y constancia"
        session_minutes = int(profile_context.get("session_minutes", 45))
        workout_days = int(profile_context.get("workout_days_per_week", 4))
        equipment = _as_list(profile_context.get("equipment"))
        restrictions = _as_list(profile_context.get("restrictions"))
        diet_prefs = _as_list(profile_context.get("dietary_preferences"))
        meal_style = "alta proteina" if any("prote" in item.lower() for item in diet_prefs) else "balanceada"
        restriction_note = ", ".join(restrictions) if restrictions else "sin restricciones limitantes"
        equipment_note = ", ".join(equipment) if equipment else "equipo basico"

        workouts = []
        weekday_names = [
            "Lunes",
            "Martes",
            "Miercoles",
            "Jueves",
            "Viernes",
            "Sabado",
            "Domingo",
        ]
        for index, day_label in enumerate(weekday_names):
            is_training_day = index < workout_days
            if is_training_day:
                workouts.append(
                    {
                        "day_label": day_label,
                        "session_title": f"Sesion {index + 1}: {focus}",
                        "focus": focus,
                        "objective": f"Trabajar fuerza util y adherencia con {equipment_note}.",
                        "duration_minutes": session_minutes,
                        "intensity": "Media" if index % 2 == 0 else "Media-alta",
                        "warmup": [
                            "Movilidad de cadera y torax",
                            "Activacion de core",
                            "Respiracion y patron tecnico",
                        ],
                        "blocks": [
                            {
                                "title": "Activacion",
                                "description": "Preparacion dinamica antes del trabajo principal.",
                                "time_box": "6 min",
                                "goal": "Entrar con movilidad, respiracion y control.",
                                "exercises": [
                                    {
                                        "name": "Movilidad articular",
                                        "sets": "2 vueltas",
                                        "reps": "40 seg",
                                        "rest": "20 seg",
                                        "notes": "Controla respiracion y rango.",
                                    },
                                    {
                                        "name": "Activacion de core",
                                        "sets": "2 series",
                                        "reps": "8 por lado",
                                        "rest": "30 seg",
                                        "notes": "Mantener pelvis estable.",
                                    },
                                ],
                            },
                            {
                                "title": "Bloque principal",
                                "description": f"Trabajo principal adaptado a {equipment_note}.",
                                "time_box": f"{max(session_minutes - 18, 18)} min",
                                "goal": "Resolver el trabajo fuerte del dia con tecnica limpia.",
                                "exercises": [
                                    {
                                        "name": "Patron dominante de pierna",
                                        "sets": "4 series",
                                        "reps": "8 a 10",
                                        "rest": "75 seg",
                                        "notes": "Escoge una variante segura si aparece molestia.",
                                    },
                                    {
                                        "name": "Empuje superior",
                                        "sets": "4 series",
                                        "reps": "8 a 12",
                                        "rest": "75 seg",
                                        "notes": f"Evita rangos agresivos si hay {restriction_note}.",
                                    },
                                    {
                                        "name": "Traccion superior",
                                        "sets": "3 series",
                                        "reps": "10 a 12",
                                        "rest": "60 seg",
                                        "notes": "Busca control escapular.",
                                    },
                                ],
                            },
                            {
                                "title": "Finisher",
                                "description": "Bloque corto para cerrar sin perder calidad.",
                                "time_box": "8 min",
                                "goal": "Cerrar con respiracion alta pero controlada.",
                                "exercises": [
                                    {
                                        "name": "Trabajo metabolico breve",
                                        "sets": "4 rondas",
                                        "reps": "40 seg",
                                        "rest": "20 seg",
                                        "notes": "Sustituye por caminata si el dia viene muy pesado.",
                                    }
                                ],
                            },
                        ],
                        "cooldown": [
                            "Respiracion nasal 2 min",
                            "Movilidad de cadera y espalda",
                        ],
                        "adaptation_hint": "Si el tiempo se aprieta, recorta el finisher antes del bloque principal.",
                    }
                )
            else:
                workouts.append(
                    {
                        "day_label": day_label,
                        "session_title": "Recuperacion activa",
                        "focus": "Recuperacion y movilidad",
                        "objective": "Moverte, bajar fatiga y sostener el habito.",
                        "duration_minutes": 25,
                        "intensity": "Baja",
                        "warmup": ["Caminata suave", "Movilidad global"],
                        "blocks": [
                            {
                                "title": "Bloque de recuperacion",
                                "description": "Movilidad, caminata o bici suave.",
                                "time_box": "20 min",
                                "goal": "Mantener continuidad sin sumar fatiga.",
                                "exercises": [
                                    {
                                        "name": "Movilidad global o caminata",
                                        "sets": "1 bloque",
                                        "reps": "20 min",
                                        "rest": "-",
                                        "notes": "Mantener percepcion de esfuerzo baja.",
                                    }
                                ],
                            }
                        ],
                        "cooldown": ["Respiracion y descarga"],
                        "adaptation_hint": "Si no puedes entrenar, al menos mantente activo 15 minutos.",
                    }
                )

        slot_titles = ["Desayuno", "Almuerzo", "Cena", "Snack"]
        meal_slots = []
        for slot in slot_titles:
            option_bank = []
            weekly_plan = []
            for option_index in range(10):
                option_bank.append(
                    {
                        "name": f"{slot} opcion {option_index + 1}",
                        "summary": f"Opcion {meal_style} pensada para {slot.lower()} con buena adherencia.",
                        "macros": "35P / 45C / 15G" if slot != "Snack" else "20P / 20C / 8G",
                        "ingredients": [
                            "Proteina principal",
                            "Carbohidrato util",
                            "Vegetal o fruta",
                            "Grasa ligera",
                        ],
                        "preparation": f"Preparacion simple de 10 a 20 minutos para {slot.lower()}.",
                        "best_for": "Dias de entrenamiento" if option_index % 2 == 0 else "Dias de descanso",
                    }
                )
            for day_index, day_label in enumerate(weekday_names):
                weekly_plan.append(
                    {
                        "day_label": day_label,
                        "meal_name": option_bank[day_index % 10]["name"],
                        "detail": f"{slot} estructurado para {day_label.lower()} con foco en adherencia.",
                        "macros": option_bank[day_index % 10]["macros"],
                        "components": option_bank[day_index % 10]["ingredients"],
                        "preparation": option_bank[day_index % 10]["preparation"],
                        "swap_options": [
                            option_bank[(day_index + 1) % 10]["name"],
                            option_bank[(day_index + 2) % 10]["name"],
                        ],
                    }
                )
            meal_slots.append(
                {
                    "title": slot,
                    "objective": f"Resolver {slot.lower()} con una estructura {meal_style} y repetible.",
                    "weekly_plan": weekly_plan,
                    "option_bank": option_bank,
                }
            )

        return GeneratedProgram.model_validate(
            {
                "plan_name": f"Plan personalizado {focus}",
                "workout_focus": focus,
                "workout_summary": (
                    f"Programa semanal de 7 dias con {workout_days} sesiones principales, "
                    f"duracion media de {session_minutes} minutos y adaptaciones segun {restriction_note}."
                ),
                "nutrition_summary": (
                    "Plan semanal con estructura completa por comida, banco de opciones y reemplazos simples."
                ),
                "habits_summary": (
                    "Foco en sueno, hidratacion, pasos diarios y adherencia progresiva sin friccion excesiva."
                ),
                "calorie_target": "2100 kcal" if "grasa" in goal.lower() else "2500 kcal",
                "macro_focus": ["Proteina suficiente", "Fibra", "Hidratacion", "Comidas repetibles"],
                "weekly_workouts": workouts,
                "meal_slots": meal_slots,
            }
        )


def build_planning_provider() -> AIPlanningProvider:
    if (
        settings.ai_enable_live_generation
        and settings.ai_provider.lower() == "openai"
        and settings.ai_api_key
    ):
        return OpenAIPlanningProvider()
    return DeterministicPlanningProvider()


def _as_list(value: object) -> list[str]:
    if isinstance(value, Iterable) and not isinstance(value, (str, bytes, dict)):
        return [str(item) for item in value]
    return []
