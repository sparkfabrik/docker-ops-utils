#!/bin/sh

# Source functions library.
. ${BASE}/functions

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
echo "All the required inputs are present. Go on with the real job."

echo "Copy the file from the source bucket to the destination bucket."
format_string "Parameters:" "g"
echo "$(format_string "Provider:" "bold") ${PROVIDER_LOWER}"
echo "$(format_string "Src:" "bold") ${BUCKET_SRC}/${FILE_SRC}"
echo "$(format_string "Dst:" "bold") ${BUCKET_DST}/${FILE_DST}"

if [ "${PROVIDER_LOWER}" = "aws" ]; then
  echo "rclone_aws sync :s3://${BUCKET_SRC}/${FILE_SRC} :s3://${BUCKET_DST}/${FILE_DST}"
  rclone_aws sync :s3://${BUCKET_SRC}/${FILE_SRC} :s3://${BUCKET_DST}/${FILE_DST} 2> /dev/null
  EXIT_RCLONE=$?
elif [ "${PROVIDER_LOWER}" = "gcs" ]; then
  echo "rclone_gcs sync :gcs://${BUCKET_SRC}/${FILE_SRC} :gcs://${BUCKET_SRC}/${FILE_DST}"
  rclone_gcs sync :gcs://${BUCKET_SRC}/${FILE_SRC} :gcs://${BUCKET_SRC}/${FILE_DST} 2> /dev/null
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
    rclone_minio_multi ls src://${BUCKET_SRC}/${FILE_SRC} 1> /dev/null 2>&1
    EXIT_LS=$?

    debug "Check for loop ${LOOP_CNT} fail"
    LOOP_CNT=$(($LOOP_CNT+1))
    sleep 1

    if [ ${LOOP_CNT} -ge ${TIMEOUT_BUCKET_SRC} ]; then
      echo "ERROR: the file is not present in the source bucket after ${TIMEOUT_BUCKET_SRC} seconds."
      exit 13
    fi
  done

  echo "rclone_minio_multi sync src://${BUCKET_SRC}/${FILE_SRC} dst://${BUCKET_DST}/${FILE_DST}"
  rclone_minio_multi sync src://${BUCKET_SRC}/${FILE_SRC} dst://${BUCKET_DST}/${FILE_DST} 2> /dev/null
  EXIT_RCLONE=$?
fi

if [ ${EXIT_RCLONE} -ne 0 ]; then
  echo "Something went wrong during the copy of files."
  exit ${EXIT_RCLONE}
fi

echo "The file was correctly copied."
exit ${EXIT_RCLONE}
