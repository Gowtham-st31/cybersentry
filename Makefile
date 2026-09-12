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