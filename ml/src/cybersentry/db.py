"""Database helpers for writeback. ml_predictions is created by migration 002."""
import json
import pandas as pd
from sqlalchemy import create_engine, text
from .config import DATABASE_URL, ROOT

_engine = None


def _init_sqlite(eng):
    with eng.begin() as cx:
        cx.execute(text("""
        CREATE TABLE IF NOT EXISTS auth_events (
            event_ref       TEXT PRIMARY KEY,
            src_user        TEXT,
            src_comp        TEXT,
            dst_comp        TEXT,
            auth_type       TEXT,
            outcome         TEXT,
            step            INTEGER,
            risk_score      REAL,
            model_version   TEXT
        );
        """))
        cx.execute(text("""
        CREATE TABLE IF NOT EXISTS alerts (
            alert_id        INTEGER PRIMARY KEY AUTOINCREMENT,
            event_ref       TEXT NOT NULL,
            layer           TEXT NOT NULL DEFAULT 'model',
            score           REAL,
            techniques      TEXT NOT NULL DEFAULT '[]',
            evidence        TEXT NOT NULL DEFAULT '{}',
            model_version   TEXT,
            created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            UNIQUE (event_ref, layer)
        );
        """))
        cx.execute(text("""
        CREATE TABLE IF NOT EXISTS ml_predictions (
            entity_id      TEXT NOT NULL,
            step           TEXT NOT NULL,
            model_name     TEXT NOT NULL,
            model_version  TEXT NOT NULL,
            score          REAL,
            label          TEXT,
            extra          TEXT NOT NULL DEFAULT '{}',
            created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (entity_id, step, model_name)
        );
        """))


def engine():
    global _engine
    if _engine is None:
        try:
            test_eng = create_engine(DATABASE_URL, pool_pre_ping=True)
            with test_eng.connect() as cx:
                pass
            _engine = test_eng
        except Exception:
            sqlite_path = ROOT / "cybersentry.db"
            _engine = create_engine(f"sqlite:///{sqlite_path}")
            _init_sqlite(_engine)
    return _engine


UPSERT_PG = text("""
INSERT INTO ml_predictions (entity_id, step, model_name, model_version, score, label, extra)
VALUES (:entity_id, :step, :model_name, :model_version, :score, :label, CAST(:extra AS JSONB))
ON CONFLICT (entity_id, step, model_name) DO UPDATE
SET model_version = EXCLUDED.model_version, score = EXCLUDED.score,
    label = EXCLUDED.label, extra = EXCLUDED.extra, created_at = now()
""")

UPSERT_SQLITE = text("""
INSERT INTO ml_predictions (entity_id, step, model_name, model_version, score, label, extra)
VALUES (:entity_id, :step, :model_name, :model_version, :score, :label, :extra)
ON CONFLICT (entity_id, step, model_name) DO UPDATE
SET model_version = EXCLUDED.model_version, score = EXCLUDED.score,
    label = EXCLUDED.label, extra = EXCLUDED.extra, created_at = CURRENT_TIMESTAMP
""")


def upsert_predictions(df: pd.DataFrame, model_name: str, model_version: str) -> int:
    """df columns: entity_id, step, score, label (nullable), extra (dict)."""
    rows = [{"entity_id": str(r.entity_id), "step": str(r.step), "model_name": model_name,
             "model_version": model_version,
             "score": None if pd.isna(r.score) else float(r.score),
             "label": None if pd.isna(r.label) else str(r.label),
             "extra": json.dumps(r.extra, default=float)} for r in df.itertuples()]
    eng = engine()
    upsert_stmt = UPSERT_SQLITE if eng.dialect.name == "sqlite" else UPSERT_PG
    with eng.begin() as cx:
        for i in range(0, len(rows), 1000):
            cx.execute(upsert_stmt, rows[i:i + 1000])
    return len(rows)


def run_sql(sql: str, **params) -> int:
    eng = engine()
    if eng.dialect.name == "sqlite":
        sql = sql.replace("UPDATE auth_events e", "UPDATE auth_events")
        sql = sql.replace("e.event_ref", "auth_events.event_ref")
        sql = sql.replace("CAST(:extra AS JSONB)", ":extra")
        sql = sql.replace("CAST(:evidence AS JSONB)", ":evidence")
        sql = sql.replace("ARRAY['T1110','T1021']", "'[\"T1110\",\"T1021\"]'")
        sql = sql.replace("ARRAY['T1110', 'T1021']", "'[\"T1110\",\"T1021\"]'")
    with eng.begin() as cx:
        return cx.execute(text(sql), params).rowcount


def scalar(sql: str, **params):
    with engine().connect() as cx:
        return cx.execute(text(sql), params).scalar()
