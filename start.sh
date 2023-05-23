#!/bin/sh

set -e # script will exit if a cmd returns a non-zero status

# for k3d deployment
# export DB_SOURCE=postgresql://root:secret@database-service:5432/simple_bank?sslmode=disable

echo "[run db migration]"
/app/migrate -path /app/migration -database "$DB_SOURCE" -verbose up

echo "[start the app]"
exec "$@"