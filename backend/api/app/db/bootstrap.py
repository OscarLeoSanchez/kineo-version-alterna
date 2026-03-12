from sqlalchemy import inspect, text
from sqlalchemy.engine import Engine

from app.db.base import Base


def bootstrap_database(engine: Engine) -> None:
    Base.metadata.create_all(bind=engine)

    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names())

    with engine.begin() as connection:
        if "user_profiles" in existing_tables:
            _ensure_column(connection, inspector, "user_profiles", "user_id", "INTEGER")
            _ensure_column(
                connection,
                inspector,
                "user_profiles",
                "training_location",
                "VARCHAR(80) DEFAULT 'Mixto'",
            )
            _ensure_column(
                connection,
                inspector,
                "user_profiles",
                "cooking_style",
                "VARCHAR(80) DEFAULT 'Simple'",
            )
            _ensure_column(
                connection,
                inspector,
                "user_profiles",
                "meals_per_day",
                "INTEGER DEFAULT 4",
            )
            _ensure_column(connection, inspector, "user_profiles", "allergies", "TEXT DEFAULT '[]'")
            _ensure_column(connection, inspector, "user_profiles", "food_dislikes", "TEXT DEFAULT '[]'")
            _ensure_column(connection, inspector, "user_profiles", "body_measurements", "TEXT DEFAULT '{}'")
            _ensure_column(connection, inspector, "user_profiles", "additional_notes", "TEXT DEFAULT ''")
        if "initial_plans" in existing_tables:
            _ensure_column(connection, inspector, "initial_plans", "user_id", "INTEGER")
            _ensure_column(connection, inspector, "initial_plans", "plan_payload", "TEXT")
        if "user_preferences" in existing_tables:
            _ensure_column(
                connection,
                inspector,
                "user_preferences",
                "daily_priority",
                "VARCHAR(32) DEFAULT 'Adherencia'",
            )
            _ensure_column(
                connection,
                inspector,
                "user_preferences",
                "recommendation_depth",
                "VARCHAR(32) DEFAULT 'Profunda'",
            )
            _ensure_column(
                connection,
                inspector,
                "user_preferences",
                "proactive_adjustments",
                "BOOLEAN DEFAULT TRUE",
            )
        if "body_metrics" in existing_tables:
            _ensure_column(connection, inspector, "body_metrics", "hip_cm", "FLOAT")
            _ensure_column(connection, inspector, "body_metrics", "chest_cm", "FLOAT")
            _ensure_column(connection, inspector, "body_metrics", "arm_cm", "FLOAT")
            _ensure_column(connection, inspector, "body_metrics", "thigh_cm", "FLOAT")
            _ensure_column(connection, inspector, "body_metrics", "sleep_hours", "FLOAT")
            _ensure_column(connection, inspector, "body_metrics", "steps", "INTEGER")
            _ensure_column(connection, inspector, "body_metrics", "resting_heart_rate", "INTEGER")


def _ensure_column(connection, inspector, table_name: str, column_name: str, sql_type: str) -> None:
    columns = {column["name"] for column in inspector.get_columns(table_name)}
    if column_name in columns:
        return
    connection.execute(text(f"ALTER TABLE {table_name} ADD COLUMN {column_name} {sql_type}"))
