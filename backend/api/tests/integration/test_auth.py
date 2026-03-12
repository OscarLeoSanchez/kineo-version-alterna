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


def test_register_login_and_me() -> None:
    register_response = client.post(
        "/api/v1/auth/register",
        json={
            "email": "oscar@example.com",
            "password": "supersecreta",
            "full_name": "Oscar Dev",
        },
    )
    assert register_response.status_code == 200
    token = register_response.json()["access_token"]

    me_response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert me_response.status_code == 200
    assert me_response.json()["email"] == "oscar@example.com"

    login_response = client.post(
        "/api/v1/auth/login",
        json={
            "email": "oscar@example.com",
            "password": "supersecreta",
        },
    )
    assert login_response.status_code == 200
    assert login_response.json()["user"]["full_name"] == "Oscar Dev"

    update_response = client.patch(
        "/api/v1/auth/me",
        json={"full_name": "Oscar Coach"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert update_response.status_code == 200
    assert update_response.json()["full_name"] == "Oscar Coach"
