#!/bin/sh

if [ ${DRY_RUN} -eq 1 ]; then
  print_dry_run
  exit 0
fi

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
if [ -z "${BUCKET}" ]; then
  echo "You have to define the bucket url"
  exit 12
fi
if [ -z "${FILE}" ]; then
  echo "You have to define the file in the bucket"
  exit 12
fi

# All the required inputs are present! Do the job
# --s3-access-key-id "${AWS_ACCESS_KEY_ID}" --s3-secret-access-key "${AWS_SECRET_ACCESS_KEY}" --s3-region "${AWS_DEFAULT_REGION}"
# rclone --s3-env-auth=true copy :s3://bucket-name/test.txt test.txt
