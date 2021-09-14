#!/bin/sh

# Source functions library.
. ${BASE}/functions

DST_DIR="/tmp"

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
debug "All the required inputs are present. Go on with the real job."

# Wait for mysql service
debug "Wait for mysql service (timeout ${TIMEOUT_MYSQL} seconds)."
wait-for-it ${DB_HOST}:${DB_PORT} -t ${TIMEOUT_MYSQL}
EXIT_WAIT=$?
debug "Wait for mysql service ended (${EXIT_WAIT})."
if [ ${EXIT_WAIT} -ne 0 ]; then
  echo "ERROR: Wait for mysql service fails."
  exit ${EXIT_WAIT}
fi

DUMP_FILE=${FILE}
NEED_COMPRESSION=0
if [ "${DUMP_FILE: -3}" == ".gz" ]; then
  DUMP_FILE="${DUMP_FILE%.gz}"
  NEED_COMPRESSION=1
fi

mysqldump -h "${DB_HOST}" -P ${DB_PORT} -u "${DB_USER}" --password="${DB_PASSWORD}" "${DB_NAME}" > "${DST_DIR}/${DUMP_FILE}"
EXIT_MYSQLEXPORT=$?

if [ ${EXIT_MYSQLEXPORT} -eq 0 ]; then
  debug "The database was correctly exported (${DST_DIR}/${DUMP_FILE})."
else
  debug "Something went wrong during the mysqldump procedure."
  exit 13
fi

if [ ${NEED_COMPRESSION} -eq 1 ]; then
  gzip "${DST_DIR}/${DUMP_FILE}"
fi

if [ ! -s "${DST_DIR}/${FILE}" ] || [ ! -r "${DST_DIR}/${FILE}" ]; then
  echo "ERROR: the file was not created."
  exit 14
fi

debug "Upload the file ${FILE} to the bucket (provider: ${PROVIDER_LOWER})."

if [ "${PROVIDER_LOWER}" = "aws" ]; then
  rclone_aws copy "${DST_DIR}/${FILE}" :s3://${BUCKET}/
elif [ "${PROVIDER_LOWER}" = "gcs" ]; then
  rclone_gcs copy "${DST_DIR}/${FILE}" :gcs://${BUCKET}/ 2> /dev/null
elif [ "${PROVIDER_LOWER}" = "minio" ]; then
  # Wait for minio service
  WAIT_ENDPOINT=$(remove_http_proto "${BUCKET_ENDPOINT}")
  debug "Wait for minio service (${WAIT_ENDPOINT}, timeout ${TIMEOUT_BUCKET} seconds)."

  wait-for-it "${WAIT_ENDPOINT}" -t ${TIMEOUT_BUCKET}
  EXIT_WAIT=$?
  debug "Wait for minio service ended (${EXIT_WAIT})."
  if [ ${EXIT_WAIT} -ne 0 ]; then
    echo "ERROR: Wait for minio service fails."
    exit ${EXIT_WAIT}
  fi
  
  # Wait until the file is present in the bucket
  LOOP_CNT=0
  EXIT_LS=3

  debug "Wait for minio service (timeout ${TIMEOUT_BUCKET} seconds)."
  while [ ${EXIT_LS} -ne 0 ]; do
    rclone_minio ls :s3://${BUCKET}/ 1> /dev/null 2>&1
    EXIT_LS=$?

    debug "Check for loop ${LOOP_CNT} fail"
    LOOP_CNT=$(($LOOP_CNT+1))
    sleep 1

    if [ ${LOOP_CNT} -ge ${TIMEOUT_BUCKET} ]; then
      echo "ERROR: the file is not present in the bucket after ${TIMEOUT_BUCKET} seconds."
      exit 13
    fi
  done

  rclone_minio copy "${DST_DIR}/${FILE}" :s3://${BUCKET}/ 2> /dev/null
fi