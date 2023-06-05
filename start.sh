#!/bin/sh

set -e # script will exit if a cmd returns a non-zero status

# for k3d deployment
# export DB_SOURCE=postgresql://root:secret@database-service:5432/simple_bank?sslmode=disable
# export DB_SOURCE=postgresql://root:secret@postgres:5432/simple_bank?sslmode=disable

echo "[start the app]"
exec "$@"