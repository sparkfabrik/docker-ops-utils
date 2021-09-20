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

# All the required inputs are present! Do the job
debug "All the required inputs are present. Go on with the real job."

debug "Download the file from the bucket (provider: ${PROVIDER_LOWER})."

if [ "${PROVIDER_LOWER}" = "aws" ]; then
  debug "rclone_aws copy :s3://${BUCKET}/${FILE} \"${DST_DIR}\""
  rclone_aws copy :s3://${BUCKET}/${FILE} "${DST_DIR}" 2> /dev/null
elif [ "${PROVIDER_LOWER}" = "gcs" ]; then
  debug "rclone_gcs copy :gcs://${BUCKET}/${FILE} \"${DST_DIR}\""
  rclone_gcs copy :gcs://${BUCKET}/${FILE} "${DST_DIR}" 2> /dev/null
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
    rclone_minio ls :s3://${BUCKET}/${FILE} 1> /dev/null 2>&1
    EXIT_LS=$?

    debug "Check for loop ${LOOP_CNT} fail"
    LOOP_CNT=$(($LOOP_CNT+1))
    sleep 1

    if [ ${LOOP_CNT} -ge ${TIMEOUT_BUCKET} ]; then
      echo "ERROR: the file is not present in the bucket after ${TIMEOUT_BUCKET} seconds."
      exit 13
    fi
  done

  debug "rclone_minio copy :s3://${BUCKET}/${FILE} \"${DST_DIR}\""
  rclone_minio copy :s3://${BUCKET}/${FILE} "${DST_DIR}" 2> /dev/null
fi

LOCAL_FILE=$(basename "${FILE}")
DUMP_FILE="${DST_DIR}/${LOCAL_FILE}"

if [ ! -s "${DUMP_FILE}" ] || [ ! -r "${DUMP_FILE}" ]; then
  echo "ERROR: the file was not downloaded."
  echo "Are you sure about this path: s3://${BUCKET}/${FILE} ?"
  exit 14
fi

debug "The file was correctly downloaded."

if [ "$(file --mime-type "${DUMP_FILE}" | awk '{print $2}')" = "application/gzip" ]; then
  debug "The downloaded file is gzipped. I will unzip the file ${DUMP_FILE} in ${DUMP_FILE%.gz}."
  rm -f "${DUMP_FILE%.gz}"
  gzip -dk "${DUMP_FILE}"
  DUMP_FILE=${DUMP_FILE%.gz}
fi

if [ ! -r "${DUMP_FILE}" ]; then
  echo "ERROR: the file '${DUMP_FILE}' is not readable."
  exit 15
fi

MIME_ACTUAL="$(file --mime-type "${DUMP_FILE}" | awk '{print $2}')"

debug "The file mime-type is: ${MIME_ACTUAL}"

echo "${MIMES_EXPECTED}" | grep "|${MIME_ACTUAL}|" 1> /dev/null 2>&1
MIME_VALID=$?

if [ ${MIME_VALID} -ne 0 ]; then
  echo "ERROR: the file has an incorrect mime type:"
  echo "Actual mime-type: '${MIME_ACTUAL}'."
  echo "Expected mime-type: '${MIMES_EXPECTED}'."
  exit 1
fi

debug "The file mime-type is valid. Go on with db import."

# Wait for mysql service
debug "Wait for mysql service (timeout 30 seconds)."
wait-for-it ${DB_HOST}:${DB_PORT} -t ${TIMEOUT_MYSQL}
EXIT_WAIT=$?
debug "Wait for mysql service ended (${EXIT_WAIT})."
if [ ${EXIT_WAIT} -ne 0 ]; then
  echo "ERROR: Wait for mysql service fails."
  exit ${EXIT_WAIT}
fi

mysql -h "${DB_HOST}" -P ${DB_PORT} -u "${DB_USER}" --password="${DB_PASSWORD}" "${DB_NAME}" < "${DUMP_FILE}"
EXIT_MYSQLIMPORT=$?

if [ ${EXIT_MYSQLIMPORT} -eq 0 ]; then
  debug "The database was correctly imported."
else
  debug "Something went wrong during the mysql import procedure."
fi

exit ${EXIT_MYSQLIMPORT}
