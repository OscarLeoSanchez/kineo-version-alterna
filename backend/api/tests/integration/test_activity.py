import os
from pathlib import Path

TEST_DB_PATH = Path(__file__).resolve().parent / "activity_test.db"
os.environ["DATABASE_URL"] = f"sqlite:///{TEST_DB_PATH}"

from fastapi.testclient import TestClient

from app.db.base import Base
from app.db.session import engine
from app.main import app

client = TestClient(app)


def setup_module() -> None:
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)


def _bootstrap_user(email: str) -> dict[str, str]:
    register = client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": "supersecreta",
            "full_name": email.split("@", maxsplit=1)[0],
        },
    )
    token = register.json()["access_token"]
    client.post(
        "/api/v1/onboarding/profile",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "full_name": email.split("@", maxsplit=1)[0],
            "age": 30,
            "height_cm": 178,
            "weight_kg": 82,
            "goal": "Perder grasa",
            "activity_level": "Intermedio",
            "workout_days_per_week": 4,
            "session_minutes": 45,
            "equipment": ["mancuernas"],
            "dietary_preferences": ["alto en proteina"],
            "restrictions": [],
        },
    )
    return {"Authorization": f"Bearer {token}"}


def test_logs_activity_and_keeps_user_scope_isolated() -> None:
    headers_a = _bootstrap_user("athlete-a@example.com")
    headers_b = _bootstrap_user("athlete-b@example.com")

    workout_response = client.post(
        "/api/v1/activity/workouts",
        headers=headers_a,
        json={
            "session_minutes": 45,
            "focus": "Fuerza full body",
            "energy_level": "Alta",
            "notes": "Buen rendimiento",
        },
    )
    nutrition_response = client.post(
        "/api/v1/activity/nutrition",
        headers=headers_a,
        json={
            "meal_label": "Dia completo",
            "adherence_score": 88,
            "protein_grams": 145,
            "hydration_liters": 3,
            "notes": "Dia estable",
        },
    )
    body_metric_response = client.post(
        "/api/v1/activity/body-metrics",
        headers=headers_a,
        json={
            "weight_kg": 79.8,
            "waist_cm": 89,
            "body_fat_percentage": 20,
            "hip_cm": 97,
            "sleep_hours": 7.5,
            "steps": 9200,
        },
    )

    updated_workout = client.put(
        f"/api/v1/activity/workouts/{workout_response.json()['id']}",
        headers=headers_a,
        json={
            "session_minutes": 50,
            "focus": "Fuerza full body B",
            "energy_level": "Media",
            "notes": "Ajuste",
        },
    )
    updated_nutrition = client.put(
        f"/api/v1/activity/nutrition/{nutrition_response.json()['id']}",
        headers=headers_a,
        json={
            "meal_label": "Dia ajustado",
            "adherence_score": 91,
            "protein_grams": 155,
            "hydration_liters": 4,
            "notes": "Ajuste",
        },
    )
    updated_metric = client.put(
        f"/api/v1/activity/body-metrics/{body_metric_response.json()['id']}",
        headers=headers_a,
        json={
            "weight_kg": 79.2,
            "waist_cm": 88,
            "body_fat_percentage": 19,
            "hip_cm": 96,
            "chest_cm": 101,
            "arm_cm": 34,
            "thigh_cm": 58,
            "sleep_hours": 8,
            "steps": 11000,
            "resting_heart_rate": 58,
        },
    )

    workout_summary = client.get("/api/v1/experience/workout", headers=headers_a)
    progress_a = client.get("/api/v1/experience/progress", headers=headers_a)
    progress_b = client.get("/api/v1/experience/progress", headers=headers_b)
    history_a = client.get("/api/v1/activity/history", headers=headers_a)
    delete_nutrition = client.delete(
        f"/api/v1/activity/nutrition/{nutrition_response.json()['id']}",
        headers=headers_a,
    )
    history_after_delete = client.get("/api/v1/activity/history", headers=headers_a)
    filtered_workouts = client.get(
        "/api/v1/activity/history/filter?filter_type=workout&energy_level=Media",
        headers=headers_a,
    )

    assert workout_response.status_code == 201
    assert nutrition_response.status_code == 201
    assert body_metric_response.status_code == 201
    assert updated_workout.status_code == 200
    assert updated_nutrition.status_code == 200
    assert updated_metric.status_code == 200
    assert workout_summary.status_code == 200
    assert progress_a.status_code == 200
    assert progress_b.status_code == 200
    assert history_a.status_code == 200
    assert delete_nutrition.status_code == 200
    assert filtered_workouts.status_code == 200
    assert progress_a.json()["completed_sessions"] == 1
    assert progress_a.json()["weekly_adherence"] == 91
    assert progress_a.json()["latest_weight_kg"] == 79.2
    assert progress_a.json()["weekly_workout_target"] == 4
    assert len(workout_summary.json()["weekly_calendar"]) == 7
    assert len(history_a.json()["workouts"]) == 1
    assert len(history_a.json()["nutrition_logs"]) == 1
    assert len(history_a.json()["body_metrics"]) == 1
    assert history_a.json()["workouts"][0]["focus"] == "Fuerza full body B"
    assert history_a.json()["body_metrics"][0]["hip_cm"] == 96
    assert history_a.json()["body_metrics"][0]["resting_heart_rate"] == 58
    assert history_after_delete.json()["nutrition_logs"] == []
    assert filtered_workouts.json()["filter_type"] == "workout"
    assert len(filtered_workouts.json()["workouts"]) == 1
    assert progress_b.json()["completed_sessions"] == 0
    assert progress_b.json()["weekly_adherence"] == 0
