-- M2: one generic prediction table, shared by every model this project trains.
-- The M1 nullable columns are filled FROM this table (step 2.11), so the raw
-- predictions stay auditable even if the M1 join keys change later.

CREATE TABLE IF NOT EXISTS auth_events (
    event_ref       VARCHAR(60) PRIMARY KEY,
    src_user        VARCHAR(80),
    src_comp        VARCHAR(80),
    dst_comp        VARCHAR(80),
    auth_type       VARCHAR(30),
    outcome         VARCHAR(20),
    step            INT,
    risk_score      DOUBLE PRECISION,
    model_version   TEXT
);

CREATE TABLE IF NOT EXISTS alerts (
    alert_id        BIGSERIAL PRIMARY KEY,
    event_ref       VARCHAR(60) NOT NULL,
    layer           VARCHAR(20) NOT NULL DEFAULT 'model',
    score           DOUBLE PRECISION,
    techniques      TEXT[] NOT NULL DEFAULT '{}',
    evidence        JSONB NOT NULL DEFAULT '{}'::jsonb,
    model_version   TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (event_ref, layer)
);

CREATE TABLE IF NOT EXISTS ml_predictions (
    entity_id      TEXT        NOT NULL,
    step           TEXT        NOT NULL,      -- cycle, timestamp, date or token span
    model_name     TEXT        NOT NULL,
    model_version  TEXT        NOT NULL,      -- registry name:version, e.g. my-model:v3
    score          DOUBLE PRECISION,
    label          TEXT,
    extra          JSONB       NOT NULL DEFAULT '{}'::jsonb,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (entity_id, step, model_name)
);

CREATE INDEX IF NOT EXISTS ix_ml_predictions_model ON ml_predictions (model_name, model_version);

