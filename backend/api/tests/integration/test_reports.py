import os
from pathlib import Path

TEST_DB_PATH = Path(__file__).resolve().parent / "reports_test.db"
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
            "email": "reports@example.com",
            "password": "supersecreta",
            "full_name": "Reports User",
        },
    )
    token = register.json()["access_token"]
    client.put(
        "/api/v1/goals/current",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "workout_sessions_target": 4,
            "nutrition_adherence_target": 85,
            "weight_checkins_target": 2,
            "reminders_enabled": True,
            "reminder_time": "07:00",
        },
    )
    return {"Authorization": f"Bearer {token}"}


def test_returns_weekly_report() -> None:
    headers = _headers()
    response = client.get("/api/v1/reports/weekly", headers=headers)

    assert response.status_code == 200
    assert response.json()["title"] == "Reporte semanal Kineo"
    assert len(response.json()["goal_status"]) == 3
    assert "## Estado de objetivos" in response.json()["markdown_report"]
