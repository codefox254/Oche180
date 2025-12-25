#!/bin/sh
set -e

: "${POSTGRES_HOST:=db}"
: "${POSTGRES_PORT:=5432}"
: "${DJANGO_SETTINGS_MODULE:=config.settings.production}"

printf "Waiting for database at %s:%s...\n" "$POSTGRES_HOST" "$POSTGRES_PORT"
until nc -z "$POSTGRES_HOST" "$POSTGRES_PORT"; do
  sleep 1
  printf "."
done
printf "\nDatabase is up.\n"

python manage.py migrate --noinput
python manage.py collectstatic --noinput

gunicorn config.wsgi:application --bind 0.0.0.0:8000
