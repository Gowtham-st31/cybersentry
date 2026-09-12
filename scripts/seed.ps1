$ErrorActionPreference = "Stop"

Write-Host "Seeding CyberSentry database..."

docker compose exec -T postgres psql `
  -U sentry `
  -d cybersentry `
  -f /seed.sql

Write-Host "Seed completed."