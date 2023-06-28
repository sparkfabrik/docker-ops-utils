#!/bin/bash

# Source functions library.
. ${BASE}/functions

DST_DIR="/tmp"
# MySQL default system databases
MYSQL_SYSTEM_DEFAULT_DATABASES="SCHEMA_NAME,information_schema,mysql,performance_schema,sys"

# Check for the required input
if [ -z "${DB_HOST}" ]; then
  echo "You have to define the db host"
  exit 12
fi
if [ -z "${DB_USER}" ]; then
  echo "You have to define the db user"
  exit 12
fi
if [ -z "${DB_PASSWORD}" ]; then
  echo "You have to define the db password"
  exit 12
fi
if [ -z "${DB_NAME}" ]; then
  echo "You have to define the db name"
  exit 12
fi
if [ -z "${DB_PORT}" ]; then
  echo "You have to define the db port"
  exit 12
fi
if [ -z "${PROVIDER}" ]; then
  echo "You have to define the bucket provider"
  exit 12
fi
if [ "${PROVIDER_LOWER}" != "aws" ] && [ "${PROVIDER_LOWER}" != "gcs" ] && [ "${PROVIDER_LOWER}" != "minio" ]; then
  echo "You have to define a valid bucket provider (aws, gcs, minio)"
  exit 12
fi
if [ "${PROVIDER_LOWER}" = "minio" ] && [ -z "${BUCKET_ENDPOINT}" ]; then
  echo "You have to define the bucket endpoint"
  exit 12
fi
if [ -z "${BUCKET}" ]; then
  echo "You have to define the bucket name"
  exit 12
fi
if [ -z "${FILE}" ]; then
  echo "You have to define the file in the bucket"
  exit 12
fi

# All the required inputs are present! Do the job
echo "All the required inputs are present. Go on with the real job."

echo "Export all MySQL databases dump to bucket."
format_string "Parameters:" "g"
echo "$(format_string "Host:" "bold") ${DB_HOST}"
echo "$(format_string "Port:" "bold") ${DB_PORT}"
echo "$(format_string "User:" "bold") ${DB_USER}"
echo "$(format_string "Database:" "bold") ${DB_NAME}"
echo "$(format_string "Provider:" "bold") ${PROVIDER_LOWER}"

EXCLUDE=${MYSQL_SYSTEM_DEFAULT_DATABASES}

# Check if we have to include system databases
if [ -n "${INCLUDE_SYSTEM_DATABASES}" ]; then
  EXCLUDE=""
fi

# Add database to exclude
if [ -n "${EXCLUDE_DATABASES}" ]; then
  if [ -n "${EXCLUDE}" ]; then
    EXCLUDE="${EXCLUDE},${EXCLUDE_DATABASES}"    
  else
    EXCLUDE=${EXCLUDE_DATABASES}
  fi
fi
EXCLUDE=(`echo $EXCLUDE | tr ',' ' '`)

echo "Get all databases from ${DB_HOST}."
databases=$(mysql -h "${DB_HOST}" -u "${DB_USER}" --password="${DB_PASSWORD}" -e "SELECT schema_name FROM information_schema.schemata;")
debug "mysql -h \"${DB_HOST}\" -u \${DB_USER}\" --password=\"${DB_PASSWORD}\" -e \"SELECT schema_name FROM information_schema.schemata;\""
databases=(`echo $databases | tr '\n' ' '`)

EXPORTED_DATABASES=""

for db in "${databases[@]}"; do
  if [[ " ${EXCLUDE[@]} " =~ " ${db} " ]]; then
    debug "Database ${db} is in the exclude list. Skip it."
  else
    echo "Dump database ${db}."
    # Remove `-db` from the database name, it is a Drupal chart naming convention
    folder=$(echo "$db" | sed 's/-db$//')
    export FILE="${folder}/${FILE}"
    debug "sh ${BASE}/commands/mysql/subcommands/export-to-bucket.sh"
    exec "sh" "${BASE}/commands/mysql/subcommands/export-to-bucket.sh"
  fi
done