#!/bin/sh
echo ">> Starting ..."

file="./app.properties"

if [ -f ${file} ]
then
  echo ">> ${file} found."

  while IFS='=' read -r key value
  do
    key=$(echo ${key} | tr .-/ _ | tr -cd 'A-Za-z0-9_')
    eval ${key}=\${value}
  done < ${file}
else
  echo ">> ${file} not found."
  exit 0
fi

if [ -z ${db_uat_user} ] || [ -z ${db_uat_passwd} ] || [ -z ${tflow_db} ]  || [ -z ${plugin_db} ]  
then
      echo ">> No config"
      exit 0
fi

echo ">> Python Config"

echo ">> Deleting old migrations"
find . -path "*/plugin_pg_scheduler/migrations/*.py" -not -name "__init__.py" -delete
find . -path "*/plugin_pg_scheduler/migrations/*.pyc"  -delete

# Optional
echo ">> Deleting sqlite (if exists) database"
find . -name "db.sqlite3" -delete

echo ">> Running manage.py makemigrations"
python plugin_pg_scheduler/manage.py makemigrations scheduler

echo ">> Running manage.py migrate auth"
python plugin_pg_scheduler/manage.py migrate --database=auth_db

echo ">> Postgres Config"
for file in ./bucket/db_migration_bootstrap/*; do
    PGPASSWORD=${db_uat_passwd} psql -U ${db_uat_user} -f ${file}
done

for file in ./bucket/db_migration_plugin/*; do
    PGPASSWORD=${db_uat_passwd} psql -U ${db_uat_user} ${plugin_db} -f ${file}
done

for file in ./bucket/db_migration_tflow/*; do
    PGPASSWORD=${db_uat_passwd} psql -U ${db_uat_user} ${tflow_db} -f ${file}
done

for file in ./bucket/db_migration_seed/*; do
    PGPASSWORD=${db_uat_passwd} psql -U ${db_uat_user} ${plugin_db} -f ${file}
done

for file in ./bucket/db_migration_priv/db_tflow/*; do
    PGPASSWORD=${db_uat_passwd} psql -U ${db_uat_user} ${tflow_db} -f ${file}
done

for file in ./bucket/db_migration_priv/db_plugin/*; do
    PGPASSWORD=${db_uat_passwd} psql -U ${db_uat_user} ${plugin_db} -f ${file}
done

echo ">> Django Superuser"
python plugin_pg_scheduler/manage.py creategroup
python plugin_pg_scheduler/manage.py createsuperuser2 \
--username ${super_name} --password ${super_password} \
--noinput --email ${super_mail} --database=auth_db

echo ">> Done"