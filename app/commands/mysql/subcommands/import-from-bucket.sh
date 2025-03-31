#!/bin/sh

# Source functions library.
. ${BASE}/functions

DST_DIR="/tmp"
MIMES_EXPECTED="|text/plain|application/octet-stream|"

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

if [[ -z "${DB_EXTRA_ARGS:-}" ]]; then
  echo "DB_EXTRA_ARGS not set. Defaulting to --skip-ssl"
  DB_EXTRA_ARGS="--skip-ssl"
fi

if [[ -z "${DB_DUMP_SANITIZE:-}" ]]; then
  echo "DB_DUMP_SANITIZE not set. Defaulting to 1"
  DB_DUMP_SANITIZE=1
fi

# All the required inputs are present! Do the job
echo "All the required inputs are present. Go on with the real job."

echo "Import MySQL dump from bucket."
format_string "Parameters:" "g"
echo "$(format_string "Host:" "bold") ${DB_HOST}"
echo "$(format_string "Port:" "bold") ${DB_PORT}"
echo "$(format_string "User:" "bold") ${DB_USER}"
echo "$(format_string "Database:" "bold") ${DB_NAME}"
echo "$(format_string "Provider:" "bold") ${PROVIDER_LOWER}"
echo "$(format_string "Dst:" "bold") ${BUCKET}/${FILE}"

echo "Download the file from the bucket."

if [ "${PROVIDER_LOWER}" = "aws" ]; then
  echo "rclone_aws copy :s3://${BUCKET}/${FILE} \"${DST_DIR}\""
  rclone_aws copy :s3://${BUCKET}/${FILE} "${DST_DIR}"
elif [ "${PROVIDER_LOWER}" = "gcs" ]; then
  echo "rclone_gcs copy :gcs://${BUCKET}/${FILE} \"${DST_DIR}\""
  rclone_gcs copy :gcs://${BUCKET}/${FILE} "${DST_DIR}"
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
    debug "rclone_minio ls :s3://${BUCKET}/${FILE}"
    rclone_minio ls :s3://${BUCKET}/${FILE} 1> /dev/null
    EXIT_LS=$?

    debug "Check for loop ${LOOP_CNT} fail"
    LOOP_CNT=$(($LOOP_CNT+1))
    sleep 1

    if [ ${LOOP_CNT} -ge ${TIMEOUT_BUCKET} ]; then
      echo "ERROR: the file is not present in the bucket after ${TIMEOUT_BUCKET} seconds."
      exit 13
    fi
  done

  echo "rclone_minio copy :s3://${BUCKET}/${FILE} \"${DST_DIR}\""
  rclone_minio copy :s3://${BUCKET}/${FILE} "${DST_DIR}"
fi

LOCAL_FILE=$(basename "${FILE}")
DUMP_FILE="${DST_DIR}/${LOCAL_FILE}"

if [ ! -s "${DUMP_FILE}" ] || [ ! -r "${DUMP_FILE}" ]; then
  echo "ERROR: the file was not downloaded."
  echo "Are you sure about this path: s3://${BUCKET}/${FILE} ?"
  exit 14
fi

debug "Check if decompression is needed."

if [ "$(file --mime-type "${DUMP_FILE}" | awk '{print $2}')" = "application/gzip" ]; then
  echo "The downloaded file is gzipped. I will unzip the file ${DUMP_FILE} in ${DUMP_FILE%.gz}."
  rm -f "${DUMP_FILE%.gz}"
  gzip -dk "${DUMP_FILE}"
  DUMP_FILE=${DUMP_FILE%.gz}
fi

if [ ! -r "${DUMP_FILE}" ]; then
  echo "ERROR: the file '${DUMP_FILE}' is not readable."
  exit 15
fi

MIME_ACTUAL="$(file --mime-type "${DUMP_FILE}" | awk '{print $2}')"

echo "Check if the dump file mime-type is valid."
echo "The file mime-type is: '${MIME_ACTUAL}'"
echo "The expected mime-type is one of: '${MIMES_EXPECTED}'"

echo "${MIMES_EXPECTED}" | grep "|${MIME_ACTUAL}|" 1> /dev/null 2>&1
MIME_VALID=$?

if [ ${MIME_VALID} -ne 0 ]; then
  echo "ERROR: the file has an incorrect mime type:"
  exit 1
fi

echo "The file mime-type is valid. Go on with db import."

# Wait for mysql service
debug "Wait for mysql service (timeout 30 seconds)."
wait-for-it ${DB_HOST}:${DB_PORT} -t ${TIMEOUT_MYSQL}
EXIT_WAIT=$?
debug "Wait for mysql service ended (${EXIT_WAIT})."
if [ ${EXIT_WAIT} -ne 0 ]; then
  echo "ERROR: Wait for mysql service fails."
  exit ${EXIT_WAIT}
fi

# Prepare the database.
if [ "${DB_DUMP_SANITIZE}" -eq 1 ]; then
  echo "Sanitizing the database dump file."
  sanitizeDbSeed "${DUMP_FILE}"
fi

echo "Exec mysql import."
mariadb -h "${DB_HOST}" -P ${DB_PORT} -u "${DB_USER}" --password="${DB_PASSWORD}" "${DB_NAME}" ${DB_EXTRA_ARGS} < "${DUMP_FILE}"
EXIT_CMD=$?

if [ ${EXIT_CMD} -ne 0 ]; then
  echo "Something went wrong during the mysql import procedure."
  exit ${EXIT_CMD}
fi

echo "The database \"${DB_NAME}\" was correctly imported to \"${DB_HOST}:${DB_PORT}\"."
exit ${EXIT_CMD}
