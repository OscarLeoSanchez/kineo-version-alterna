import os
from pathlib import Path

TEST_DB_PATH = Path(__file__).resolve().parent / "integration_test.db"
os.environ["DATABASE_URL"] = f"sqlite:///{TEST_DB_PATH}"

from fastapi.testclient import TestClient

from app.db.base import Base
from app.db.session import engine
from app.main import app

client = TestClient(app)


def _register_and_get_token() -> str:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": "onboarding@example.com",
            "password": "supersecreta",
            "full_name": "Oscar",
        },
    )
    return response.json()["access_token"]


def setup_module() -> None:
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)


def teardown_module() -> None:
    Base.metadata.drop_all(bind=engine)


def test_creates_profile() -> None:
    token = _register_and_get_token()
    payload = {
        "full_name": "Oscar",
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
    }

    response = client.post(
        "/api/v1/onboarding/profile",
        json=payload,
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["full_name"] == "Oscar"
    assert body["equipment"] == ["mancuernas", "banda"]


def test_returns_dashboard_summary() -> None:
    response = client.get(
        "/api/v1/onboarding/dashboard-summary",
        headers={"Authorization": "Bearer invalid"},
    )

    assert response.status_code == 401

    login_response = client.post(
        "/api/v1/auth/login",
        json={
            "email": "onboarding@example.com",
            "password": "supersecreta",
        },
    )
    token = login_response.json()["access_token"]

    response = client.get(
        "/api/v1/onboarding/dashboard-summary",
        headers={
            "Authorization": f"Bearer {token}",
            "X-Coach-Style": "Exigente",
            "X-Experience-Mode": "Full",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert "Oscar" in body["headline"]
    assert "proteina" in body["nutrition_focus"].lower()
    assert "45 minutos" in body["current_plan_summary"]
    assert "ajuste adaptativo" in body["workout_focus"] or "timing flexible" in body["nutrition_focus"]
