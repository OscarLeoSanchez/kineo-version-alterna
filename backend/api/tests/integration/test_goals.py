import os
from pathlib import Path

TEST_DB_PATH = Path(__file__).resolve().parent / "goals_test.db"
os.environ["DATABASE_URL"] = f"sqlite:///{TEST_DB_PATH}"

from fastapi.testclient import TestClient

from app.db.base import Base
from app.db.session import engine
from app.main import app

client = TestClient(app)


def setup_module() -> None:
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)


def _headers() -> dict[str, str]:
    register = client.post(
        "/api/v1/auth/register",
        json={
            "email": "goals@example.com",
            "password": "supersecreta",
            "full_name": "Goals User",
        },
    )
    return {"Authorization": f"Bearer {register.json()['access_token']}"}


def test_reads_and_updates_weekly_goals() -> None:
    headers = _headers()

    current = client.get("/api/v1/goals/current", headers=headers)
    updated = client.put(
        "/api/v1/goals/current",
        headers=headers,
        json={
            "workout_sessions_target": 5,
            "nutrition_adherence_target": 90,
            "weight_checkins_target": 3,
            "reminders_enabled": True,
            "reminder_time": "06:30",
        },
    )

    assert current.status_code == 200
    assert updated.status_code == 200
    assert updated.json()["workout_sessions_target"] == 5
    assert updated.json()["reminder_time"] == "06:30"
