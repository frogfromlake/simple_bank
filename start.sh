#!/bin/sh

set -e # script will exit if a cmd returns a non-zero status

echo "[run db migration]"
/app/migrate -path /app/migration -database "$DB_SOURCE" -verbose up

echo "[start the app]"
exec $@