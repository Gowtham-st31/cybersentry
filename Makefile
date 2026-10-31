up:
	docker compose up -d

down:
	docker compose down

reset:
	docker compose down -v

ps:
	docker compose ps

logs:
	docker compose logs -f

db-init:
	docker compose exec -T postgres psql -U sentry -d cybersentry -f /init_db.sql

seed:
	docker compose exec -T postgres psql -U sentry -d cybersentry -f /seed.sql

data:
	python scripts/generate_data.py

verify:
	python scripts/verify.py

test:
	python -m pytest -v

lint:
	python -m ruff check .

# ---- M2 targets ----
PY   := PYTHONPATH=ml/src python
PKG  := cybersentry
PSQL := docker compose exec -T postgres psql -U sentry

mlflow-up:
	$(PSQL) -tc "SELECT 1 FROM pg_database WHERE datname='mlflow'" | grep -q 1 \
	  || $(PSQL) -c "CREATE DATABASE mlflow"
	docker compose -f docker-compose.yml -f docker-compose.mlflow.yml up -d mlflow

migrate-m2:
	$(PSQL) -d cybersentry < db/migrations/002_m2_predictions.sql

extract:
	$(PY) -m $(PKG).split

test-m2:
	PYTHONPATH=ml/src pytest -q ml/tests/test_m2_leakage.py

baseline:
	$(PY) -m $(PKG).baseline

train:
	$(PY) -m $(PKG).train

hpo:
	$(PY) -m $(PKG).hpo --trials 30

evaluate:
	$(PY) -m $(PKG).evaluate

promote:
	$(PY) -m $(PKG).promote

writeback:
	$(PY) -m $(PKG).writeback

verify-m2:
	$(PY) scripts/verify_m2.py

m2: extract test-m2 train evaluate promote writeback verify-m2

.PHONY: mlflow-up migrate-m2 extract test-m2 baseline train hpo evaluate promote writeback verify-m2 m2
