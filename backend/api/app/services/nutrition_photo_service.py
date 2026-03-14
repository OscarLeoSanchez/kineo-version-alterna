import base64
import json
import logging

from fastapi import UploadFile
from openai import AsyncOpenAI

from app.core.config import settings
from app.schemas.experience import NutritionPhotoAnalysisRead

logger = logging.getLogger(__name__)


_SYSTEM_PROMPT = """Eres un nutricionista experto y analizas imágenes de comida.
Cuando el usuario te envíe una foto de comida, responde ÚNICAMENTE con un JSON válido con esta estructura exacta:
{
  "dish_name": "Nombre del plato en español",
  "estimated_calories": 450,
  "protein_g": 25.0,
  "carbs_g": 45.0,
  "fat_g": 12.0,
  "fiber_g": 3.5,
  "detected_items": ["Ingrediente 1", "Ingrediente 2"],
  "ingredients": ["100g de arroz cocido", "150g de pollo a la plancha"],
  "confidence_note": "Estimación basada en porción visible. Los valores pueden variar ±15%.",
  "serving_hint": "1 plato mediano (~350g)",
  "coach_note": "Buena fuente de proteínas. Considera añadir más verduras para aumentar la fibra."
}

Reglas:
- Si no puedes identificar claramente la comida, da una estimación aproximada
- Los macros deben ser coherentes con las calorías (1g proteína=4kcal, 1g carb=4kcal, 1g grasa=9kcal)
- Si la imagen no contiene comida, responde con dish_name="No se detectó comida" y valores 0
- NUNCA incluyas texto fuera del JSON
"""


class NutritionPhotoService:
    def __init__(self) -> None:
        self._client: AsyncOpenAI | None = None

    def _get_client(self) -> AsyncOpenAI:
        if self._client is None:
            self._client = AsyncOpenAI(
                api_key=settings.ai_api_key,
                base_url=settings.ai_base_url or None,
            )
        return self._client

    async def analyze_photo(
        self,
        *,
        meal_label: str,
        upload: UploadFile,
    ) -> NutritionPhotoAnalysisRead:
        if (
            not settings.ai_enable_live_generation
            or not settings.ai_api_key
            or settings.ai_api_key == "replace-me"
        ):
            return self._fallback_response(meal_label)

        try:
            image_bytes = await upload.read()
            b64_image = base64.b64encode(image_bytes).decode("utf-8")
            content_type = upload.content_type or "image/jpeg"

            client = self._get_client()
            response = await client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system", "content": _SYSTEM_PROMPT},
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "text",
                                "text": (
                                    f"Analiza esta foto de comida. Es para la comida: {meal_label}. "
                                    "Dame el JSON de análisis nutricional."
                                ),
                            },
                            {
                                "type": "image_url",
                                "image_url": {
                                    "url": f"data:{content_type};base64,{b64_image}",
                                    "detail": "low",
                                },
                            },
                        ],
                    },
                ],
                max_tokens=600,
                temperature=0.2,
            )

            raw = response.choices[0].message.content or ""
            raw = raw.strip()
            if raw.startswith("```"):
                raw = raw.split("```")[1]
                if raw.startswith("json"):
                    raw = raw[4:]
            raw = raw.strip()

            data = json.loads(raw)
            return NutritionPhotoAnalysisRead(
                meal_label=meal_label,
                detected_dish_name=data.get("dish_name", "Comida detectada"),
                estimated_calories_kcal=int(data.get("estimated_calories", 0)),
                estimated_protein_g=float(data.get("protein_g", 0)),
                estimated_carbs_g=float(data.get("carbs_g", 0)),
                estimated_fat_g=float(data.get("fat_g", 0)),
                estimated_fiber_g=float(data.get("fiber_g", 0)),
                detected_items=data.get("detected_items", []),
                ingredients=data.get("ingredients", []),
                confidence_note=data.get("confidence_note", ""),
                serving_hint=data.get("serving_hint", ""),
                coach_note=data.get("coach_note", ""),
            )

        except json.JSONDecodeError as e:
            logger.error("JSON parse error from GPT-4o Vision: %s", e)
            return self._fallback_response(meal_label)
        except Exception as e:
            logger.error("GPT-4o Vision error: %s", e)
            return self._fallback_response(meal_label)

    def _fallback_response(self, meal_label: str) -> NutritionPhotoAnalysisRead:
        defaults: dict[str, tuple[int, float, float, float]] = {
            "Desayuno": (350, 15.0, 45.0, 10.0),
            "Almuerzo": (600, 30.0, 65.0, 18.0),
            "Cena": (500, 25.0, 55.0, 15.0),
            "Snack": (200, 8.0, 25.0, 7.0),
        }
        cal, prot, carbs, fat = defaults.get(meal_label, (400, 20.0, 50.0, 12.0))
        return NutritionPhotoAnalysisRead(
            meal_label=meal_label,
            detected_dish_name=f"{meal_label} típico",
            estimated_calories_kcal=cal,
            estimated_protein_g=prot,
            estimated_carbs_g=carbs,
            estimated_fat_g=fat,
            estimated_fiber_g=3.0,
            detected_items=[],
            ingredients=[],
            confidence_note="Estimación sin análisis de imagen (IA no disponible).",
            serving_hint="1 porción estándar",
            coach_note="Sube una foto para obtener un análisis personalizado.",
        )
