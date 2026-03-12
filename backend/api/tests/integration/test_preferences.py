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


def teardown_module() -> None:
    Base.metadata.drop_all(bind=engine)


def test_gets_and_updates_preferences() -> None:
    register_response = client.post(
        "/api/v1/auth/register",
        json={
            "email": "prefs@example.com",
            "password": "1234",
            "full_name": "Prefs User",
        },
    )
    token = register_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    initial_response = client.get("/api/v1/preferences/me", headers=headers)
    assert initial_response.status_code == 200
    assert initial_response.json()["experience_mode"] == "Full"
    assert initial_response.json()["daily_priority"] == "Adherencia"
    assert initial_response.json()["recommendation_depth"] == "Profunda"
    assert initial_response.json()["proactive_adjustments"] is True

    update_response = client.patch(
        "/api/v1/preferences/me",
        headers=headers,
        json={
            "coaching_style": "Flexible",
            "units": "Imperiales",
            "reminders_enabled": False,
            "experience_mode": "Full",
            "daily_priority": "Recuperacion",
            "recommendation_depth": "Esencial",
            "proactive_adjustments": False,
        },
    )
    assert update_response.status_code == 200
    assert update_response.json()["coaching_style"] == "Flexible"
    assert update_response.json()["experience_mode"] == "Full"
    assert update_response.json()["daily_priority"] == "Recuperacion"
    assert update_response.json()["recommendation_depth"] == "Esencial"
    assert update_response.json()["proactive_adjustments"] is False

    goal_response = client.get("/api/v1/goals/current", headers=headers)
    assert goal_response.status_code == 200
    assert goal_response.json()["reminders_enabled"] is False
