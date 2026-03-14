from sqlalchemy import inspect, text
from sqlalchemy.engine import Engine

from app.db.base import Base


def bootstrap_database(engine: Engine) -> None:
    Base.metadata.create_all(bind=engine, checkfirst=True)

    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names())

    with engine.begin() as connection:
        if "user_profiles" in existing_tables:
            _ensure_column(connection, inspector, "user_profiles", "user_id", "INTEGER")
            _ensure_column(connection, inspector, "user_profiles", "training_location", "VARCHAR(80) DEFAULT 'Mixto'")
            _ensure_column(connection, inspector, "user_profiles", "cooking_style", "VARCHAR(80) DEFAULT 'Simple'")
            _ensure_column(connection, inspector, "user_profiles", "meals_per_day", "INTEGER DEFAULT 4")
            _ensure_column(connection, inspector, "user_profiles", "allergies", "TEXT DEFAULT '[]'")
            _ensure_column(connection, inspector, "user_profiles", "food_dislikes", "TEXT DEFAULT '[]'")
            _ensure_column(connection, inspector, "user_profiles", "body_measurements", "TEXT DEFAULT '{}'")
            _ensure_column(connection, inspector, "user_profiles", "additional_notes", "TEXT DEFAULT ''")
            _ensure_column(connection, inspector, "user_profiles", "birth_date", "DATE")
            _ensure_column(connection, inspector, "user_profiles", "sex", "VARCHAR(32)")
            _ensure_column(connection, inspector, "user_profiles", "gender_identity", "VARCHAR(32)")
        if "initial_plans" in existing_tables:
            _ensure_column(connection, inspector, "initial_plans", "user_id", "INTEGER")
            _ensure_column(connection, inspector, "initial_plans", "plan_payload", "TEXT")
        if "user_preferences" in existing_tables:
            _ensure_column(connection, inspector, "user_preferences", "daily_priority", "VARCHAR(32) DEFAULT 'Adherencia'")
            _ensure_column(connection, inspector, "user_preferences", "recommendation_depth", "VARCHAR(32) DEFAULT 'Profunda'")
            _ensure_column(connection, inspector, "user_preferences", "proactive_adjustments", "BOOLEAN DEFAULT TRUE")
        if "body_metrics" in existing_tables:
            _ensure_column(connection, inspector, "body_metrics", "hip_cm", "FLOAT")
            _ensure_column(connection, inspector, "body_metrics", "chest_cm", "FLOAT")
            _ensure_column(connection, inspector, "body_metrics", "arm_cm", "FLOAT")
            _ensure_column(connection, inspector, "body_metrics", "thigh_cm", "FLOAT")
            _ensure_column(connection, inspector, "body_metrics", "sleep_hours", "FLOAT")
            _ensure_column(connection, inspector, "body_metrics", "steps", "INTEGER")
            _ensure_column(connection, inspector, "body_metrics", "resting_heart_rate", "INTEGER")
        if "workout_sessions" in existing_tables:
            _ensure_column(connection, inspector, "workout_sessions", "plan_id", "INTEGER")
            _ensure_column(connection, inspector, "workout_sessions", "day_iso_date", "VARCHAR(10)")

        # exercise_catalog — new columns for robust-platform
        if "exercise_catalog" in existing_tables:
            _ensure_column(connection, inspector, "exercise_catalog", "name_es", "VARCHAR(160)")
            _ensure_column(connection, inspector, "exercise_catalog", "description_es", "TEXT")
            _ensure_column(connection, inspector, "exercise_catalog", "instructions_es", "TEXT DEFAULT '[]'")
            _ensure_column(connection, inspector, "exercise_catalog", "primary_muscle", "VARCHAR(120)")
            _ensure_column(connection, inspector, "exercise_catalog", "secondary_muscles", "TEXT DEFAULT '[]'")
            _ensure_column(connection, inspector, "exercise_catalog", "equipment_required", "TEXT DEFAULT '[]'")
            _ensure_column(connection, inspector, "exercise_catalog", "equipment_alternatives", "TEXT DEFAULT '[]'")
            _ensure_column(connection, inspector, "exercise_catalog", "difficulty", "VARCHAR(32)")
            _ensure_column(connection, inspector, "exercise_catalog", "category", "VARCHAR(32)")
            _ensure_column(connection, inspector, "exercise_catalog", "tags", "TEXT DEFAULT '[]'")
            _ensure_column(connection, inspector, "exercise_catalog", "is_unilateral", "BOOLEAN DEFAULT FALSE")
            _ensure_column(connection, inspector, "exercise_catalog", "estimated_duration_seconds", "INTEGER")
            _ensure_column(connection, inspector, "exercise_catalog", "image_urls", "TEXT DEFAULT '[]'")
            _ensure_column(connection, inspector, "exercise_catalog", "video_url", "TEXT")
            _ensure_column(connection, inspector, "exercise_catalog", "thumbnail_url", "TEXT")

        # exercise_substitutions — new table
        if "exercise_substitutions" not in existing_tables:
            connection.execute(text(
                """
                CREATE TABLE IF NOT EXISTS exercise_substitutions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    exercise_id INTEGER NOT NULL REFERENCES exercise_catalog(id) ON DELETE CASCADE,
                    substitute_id INTEGER NOT NULL REFERENCES exercise_catalog(id) ON DELETE CASCADE,
                    reason VARCHAR(60),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(exercise_id, substitute_id)
                )
                """
            ))
            connection.execute(text(
                "CREATE INDEX IF NOT EXISTS ix_exercise_substitutions_exercise_id ON exercise_substitutions(exercise_id)"
            ))

        # plan_modifications — new table
        if "plan_modifications" not in existing_tables:
            connection.execute(text(
                """
                CREATE TABLE IF NOT EXISTS plan_modifications (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                    plan_id INTEGER REFERENCES initial_plans(id) ON DELETE SET NULL,
                    modification_type VARCHAR(32) NOT NULL,
                    target_type VARCHAR(32) NOT NULL DEFAULT 'exercise',
                    target_day_label VARCHAR(20),
                    target_block_title VARCHAR(120),
                    target_item_name VARCHAR(240),
                    replacement_item_name VARCHAR(240),
                    override_json TEXT NOT NULL DEFAULT '{}',
                    note_text TEXT,
                    is_active BOOLEAN NOT NULL DEFAULT TRUE,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            ))
            connection.execute(text(
                "CREATE INDEX IF NOT EXISTS ix_plan_modifications_user_id ON plan_modifications(user_id)"
            ))
            connection.execute(text(
                "CREATE INDEX IF NOT EXISTS ix_plan_modifications_is_active ON plan_modifications(is_active)"
            ))

        # exercise_logs — new table
        if "exercise_logs" not in existing_tables:
            connection.execute(text(
                """
                CREATE TABLE IF NOT EXISTS exercise_logs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                    plan_id INTEGER REFERENCES initial_plans(id) ON DELETE SET NULL,
                    day_iso_date VARCHAR(10) NOT NULL,
                    exercise_name VARCHAR(240) NOT NULL,
                    exercise_catalog_id INTEGER REFERENCES exercise_catalog(id) ON DELETE SET NULL,
                    block_title VARCHAR(120),
                    set_number INTEGER NOT NULL DEFAULT 1,
                    reps INTEGER,
                    weight_kg REAL,
                    duration_seconds INTEGER,
                    notes TEXT,
                    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            ))
            connection.execute(text(
                "CREATE INDEX IF NOT EXISTS ix_exercise_logs_user_day ON exercise_logs(user_id, day_iso_date)"
            ))

        # nutrition_logs — hydration precision fix (REAL instead of INTEGER)
        # For SQLite this is a no-op (SQLite is typeless), safe to skip.
        # For PostgreSQL the column type change is handled via ALTER TABLE.
        # We check column type from information_schema to avoid redundant ops.
        if "nutrition_logs" in existing_tables:
            _ensure_hydration_real_type(connection)


def _ensure_hydration_real_type(connection) -> None:
    """Upgrade hydration_liters from INTEGER to REAL on PostgreSQL if needed."""
    try:
        result = connection.execute(text(
            """
            SELECT data_type FROM information_schema.columns
            WHERE table_name = 'nutrition_logs' AND column_name = 'hydration_liters'
            """
        ))
        row = result.fetchone()
        if row and row[0].lower() in ("integer", "int", "int4", "bigint"):
            connection.execute(text(
                "ALTER TABLE nutrition_logs ALTER COLUMN hydration_liters TYPE REAL"
            ))
    except Exception:
        # SQLite or table/column doesn't exist — safe to ignore
        pass


def _ensure_column(connection, inspector, table_name: str, column_name: str, sql_type: str) -> None:
    columns = {column["name"] for column in inspector.get_columns(table_name)}
    if column_name in columns:
        return
    connection.execute(text(f"ALTER TABLE {table_name} ADD COLUMN {column_name} {sql_type}"))
