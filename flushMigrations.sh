#!/bin/sh
echo "Starting ..."

echo ">> Deleting old migrations"
find . -path "*/scheduler/migrations/*.py" -not -name "__init__.py" -delete
find . -path "*/scheduler/migrations/*.pyc"  -delete

# Optional
echo ">> Deleting sqlite  (if exists) database"
find . -name "db.sqlite3" -delete

echo ">> Running manage.py makemigrations"
python plugin_pg_scheduler/manage.py makemigrations

echo ">> Running manage.py migrate"
python plugin_pg_scheduler/manage.py migrate --database=primary
python plugin_pg_scheduler/manage.py migrate --database=auth_db

echo ">> Done"