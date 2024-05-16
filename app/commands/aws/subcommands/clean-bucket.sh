#!/usr/bin/env bash

# This script is used to empty an aws s3 bucket.
#
# We first get the list of objects versions paying attention to get also
# the DeleteMarkers since our buckets are versioned and a bucket cannot be
# considered empty unless also the deletion markers have been deleted.
# We then iteratively go through this list, deleting 1000 items at a time
# (since that is the maximum limit accepted by the aws s3api delete-objects command).

# Source functions library.
# shellcheck disable=SC1091
. "${BASE}/functions"

# Check for the required input
if [ -z "${BUCKET}" ]; then
  echo "You have to define the bucket name."
  exit 12
fi

CLEAN_BUCKET_JSON_TEMPLATE_FILE="${BASE}/files/clean-bucket-template.json"
PAGE_SIZE=${PAGE_SIZE:-200}

echo "All the required inputs are present."

echo "Start process of delete the file versions and the delete markers."
format_string "Parameters:" "g"
echo "$(format_string "Bucket:" "bold") ${BUCKET}"

echo "Get objects list."
ITEMS_TEMP_FILE=$(mktemp)
aws s3api list-object-versions --bucket "${BUCKET}" --output json | jq '. | to_entries | [.[] | select(.key | match("^Versions|DeleteMarkers$")) | .value[] | {Key:.Key,VersionId:.VersionId}]' >"${ITEMS_TEMP_FILE}"
if [ ! -s "${ITEMS_TEMP_FILE}" ]; then
  echo Bucket is already empty, bailing out.
  exit 0
fi
ITEMS_TOT_COUNT=$(jq 'length' <"${ITEMS_TEMP_FILE}")
echo There are "$(format_string "${ITEMS_TOT_COUNT}" "bold")" items in the bucket.

I=0
until ((I * PAGE_SIZE > ITEMS_TOT_COUNT)); do
  FROM=$((I * PAGE_SIZE))
  TO=$(((I + 1) * PAGE_SIZE))
  ITEMS=$(jq -rc ".[${FROM}:${TO}]" <"${ITEMS_TEMP_FILE}")
  COUNT_ITEMS=$(echo "${ITEMS}" | jq 'length')
  echo "Interval: [${FROM}:${TO}], deleting ${COUNT_ITEMS} objects."
  if ((COUNT_ITEMS == 0)); then
    echo "No items left to delete."
    break
  fi
  aws s3api delete-objects --bucket "${BUCKET}" --delete "$(jq -rc ".Objects = ${ITEMS}" <${CLEAN_BUCKET_JSON_TEMPLATE_FILE})"
  EXIT_CMD=$?
  if [ ${EXIT_CMD} -ne 0 ]; then
    echo "Something went wrong during objects deletion."
    exit ${EXIT_CMD}
  fi
  ((I += 1))
done
rm -f "${ITEMS_TEMP_FILE}"

echo "Objects have been deleted."
exit "${EXIT_CMD}"
