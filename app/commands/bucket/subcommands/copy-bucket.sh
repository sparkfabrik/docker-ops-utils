#!/bin/sh

# Source functions library.
. ${BASE}/functions

DST_DIR="/tmp"

# Check for the required input
if [ -z "${PROVIDER}" ]; then
  echo "You have to define the bucket provider"
  exit 12
fi
if [ "${PROVIDER_LOWER}" != "aws" ] && [ "${PROVIDER_LOWER}" != "gcs" ] && [ "${PROVIDER_LOWER}" != "minio" ]; then
  echo "You have to define a valid bucket provider (aws, gcs, minio)"
  exit 12
fi
if [ "${PROVIDER_LOWER}" = "minio" ] && [ -z "${BUCKET_SRC_ENDPOINT}" ]; then
  echo "You have to define the source bucket endpoint"
  exit 12
fi
if [ -z "${BUCKET_SRC}" ]; then
  echo "You have to define the source bucket name"
  exit 12
fi
if [ -z "${FILE_SRC}" ]; then
  echo "You have to define the source file in the bucket"
  exit 12
fi
if [ "${PROVIDER_LOWER}" = "minio" ] && [ -z "${BUCKET_DST_ENDPOINT}" ]; then
  echo "You have to define the destination bucket endpoint"
  exit 12
fi
if [ -z "${BUCKET_DST}" ]; then
  echo "You have to define the destination bucket name"
  exit 12
fi
if [ -z "${FILE_DST}" ]; then
  echo "You have to define the destination file in the bucket"
  exit 12
fi

# All the required inputs are present! Do the job
debug "All the required inputs are present. Go on with the real job."

debug "Copy the file from the source bucket to the destination bucket (provider: ${PROVIDER_LOWER})."

if [ "${PROVIDER_LOWER}" = "aws" ]; then
  rclone_aws copy :s3://${BUCKET_SRC}/${FILE_SRC} :s3://${BUCKET_DST}/${FILE_DST} 2> /dev/null
  EXIT_RCLONE=$?
elif [ "${PROVIDER_LOWER}" = "gcs" ]; then
  rclone_gcs copy :gcs://${BUCKET_SRC}/${FILE_SRC} :gcs://${BUCKET_SRC}/${FILE_DST} 2> /dev/null
  EXIT_RCLONE=$?
elif [ "${PROVIDER_LOWER}" = "minio" ]; then
  # Wait for source minio service
  WAIT_ENDPOINT=$(remove_http_proto "${BUCKET_SRC_ENDPOINT}")
  debug "Wait for source minio service (${WAIT_ENDPOINT}, timeout ${TIMEOUT_BUCKET_SRC} seconds)."

  wait-for-it "${WAIT_ENDPOINT}" -t ${TIMEOUT_BUCKET_SRC}
  EXIT_WAIT=$?
  debug "Wait for minio service ended (${EXIT_WAIT})."
  if [ ${EXIT_WAIT} -ne 0 ]; then
    echo "ERROR: Wait for minio service fails."
    exit ${EXIT_WAIT}
  fi

  # Wait for destination minio service
  WAIT_ENDPOINT=$(remove_http_proto "${BUCKET_DST_ENDPOINT}")
  debug "Wait for destination minio service (${WAIT_ENDPOINT}, timeout ${TIMEOUT_BUCKET_DST} seconds)."

  wait-for-it "${WAIT_ENDPOINT}" -t ${TIMEOUT_BUCKET_DST}
  EXIT_WAIT=$?
  debug "Wait for minio service ended (${EXIT_WAIT})."
  if [ ${EXIT_WAIT} -ne 0 ]; then
    echo "ERROR: Wait for minio service fails."
    exit ${EXIT_WAIT}
  fi
  
  # Wait until the file is present in the bucket
  LOOP_CNT=0
  EXIT_LS=3

  debug "Wait for source minio service files (timeout ${TIMEOUT_BUCKET_SRC} seconds)."
  while [ ${EXIT_LS} -ne 0 ]; do
    rclone_minio ls :s3://${BUCKET_SRC}/${FILE} 1> /dev/null 2>&1
    EXIT_LS=$?

    debug "Check for loop ${LOOP_CNT} fail"
    LOOP_CNT=$(($LOOP_CNT+1))
    sleep 1

    if [ ${LOOP_CNT} -ge ${TIMEOUT_BUCKET_SRC} ]; then
      echo "ERROR: the file is not present in the bucket after ${TIMEOUT_BUCKET_SRC} seconds."
      exit 13
    fi
  done

  rclone_minio copy :s3://${BUCKET_SRC}/${FILE_SRC} :s3://${BUCKET_DST}/${FILE_DST} 2> /dev/null
  EXIT_RCLONE=$?
fi

if [ ${EXIT_RCLONE} -eq 0 ]; then
  debug "The file was correctly copied."
else
  debug "Something went wrong during the copy of files."
fi

exit ${EXIT_RCLONE}
