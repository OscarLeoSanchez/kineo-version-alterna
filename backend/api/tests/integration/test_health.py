from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_root_returns_service_metadata() -> None:
    response = client.get("/")

    assert response.status_code == 200
    assert response.json()["name"] == "Kineo Coach API"


def test_healthcheck_returns_ok() -> None:
    response = client.get("/api/v1/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
