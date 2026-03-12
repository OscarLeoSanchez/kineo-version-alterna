import os
from pathlib import Path

TEST_DB_PATH = Path(__file__).resolve().parent / "integration_test.db"
os.environ["DATABASE_URL"] = f"sqlite:///{TEST_DB_PATH}"

from fastapi.testclient import TestClient

from app.db.base import Base
from app.db.session import engine
from app.main import app

client = TestClient(app)


def setup_module() -> None:
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)


def _authorized_headers() -> dict[str, str]:
    register = client.post(
        "/api/v1/auth/register",
        json={
            "email": "experience@example.com",
            "password": "supersecreta",
            "full_name": "Oscar Experience",
        },
    )
    token = register.json()["access_token"]
    client.post(
        "/api/v1/onboarding/profile",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "full_name": "Oscar Experience",
            "age": 30,
            "height_cm": 178,
            "weight_kg": 82,
            "goal": "Perder grasa",
            "activity_level": "Intermedio",
            "workout_days_per_week": 4,
            "session_minutes": 45,
            "equipment": ["mancuernas", "banda"],
            "dietary_preferences": ["alto en proteina"],
            "restrictions": ["rodilla sensible"],
        },
    )
    return {"Authorization": f"Bearer {token}"}


def test_returns_experience_modules() -> None:
    headers = _authorized_headers()
    update_preferences = client.patch(
        "/api/v1/preferences/me",
        headers=headers,
        json={
            "coaching_style": "Flexible",
            "units": "Imperiales",
            "reminders_enabled": True,
            "experience_mode": "Full",
            "daily_priority": "Rendimiento",
            "recommendation_depth": "Profunda",
            "proactive_adjustments": True,
        },
    )
    assert update_preferences.status_code == 200
    headers.update(
        {
            "X-Coach-Style": "Flexible",
            "X-Experience-Mode": "Full",
            "X-Units": "Imperiales",
        }
    )

    workout = client.get("/api/v1/experience/workout", headers=headers)
    nutrition = client.get("/api/v1/experience/nutrition", headers=headers)
    progress = client.get("/api/v1/experience/progress", headers=headers)

    assert workout.status_code == 200
    assert nutrition.status_code == 200
    assert progress.status_code == 200
    assert workout.json()["duration_minutes"] == 45
    assert workout.json()["completed_sessions"] == 0
    assert len(nutrition.json()["meals"]) >= 5
    assert workout.json()["energy_level"] == "Media"
    assert nutrition.json()["adherence_score"] == 0
    assert "timing flexible" in nutrition.json()["swap_tip"]
    assert workout.json()["blocks"][1]["title"] == "Bloque de rendimiento"
    assert workout.json()["blocks"][1]["exercises"][0]["name"]
    assert workout.json()["blocks"][0]["goal"]
    assert workout.json()["blocks"][-1]["title"] == "Ajuste adaptativo"
    assert nutrition.json()["meals"][0]["objective"]
    assert len(nutrition.json()["meals"][0]["swap_options"]) >= 1
    assert len(nutrition.json()["meals"][0]["weekly_plan"]) == 7
    assert len(nutrition.json()["meals"][0]["option_bank"]) == 10
    assert progress.json()["streak_days"] == 0
    assert progress.json()["insights"][-1]["title"] == "Nivel de detalle"
