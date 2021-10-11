#!/bin/sh

# Source functions library.
. ${BASE}/functions

# Check for the required input
if [ -z "${BUCKET}" ]; then
  echo "You have to define the bucket name"
  exit 12
fi

# All the required inputs are present! Do the job
echo "All the required inputs are present. Go on with the real job."

echo "Start process of delete the file versions and the delete markers."
format_string "Parameters:" "g"
echo "$(format_string "Bucket:" "bold") ${BUCKET}"

echo "Get objects."
ITEMS=$(aws s3api list-object-versions --bucket "${BUCKET}" --output json | jq '. | to_entries | [.[] | select(.key | match("^Versions|DeleteMarkers$")) | .value[] | {Key:.Key,VersionId:.VersionId}]')

if [ -z "${ITEMS}" ]; then
  echo "There is no items to delete."
  exit 13
fi

echo "Delete objects."
aws s3api delete-objects --bucket "${BUCKET}" --delete "{\"Objects\": ${ITEMS}}"
EXIT_CMD=$?

if [ ${EXIT_CMD} -ne 0 ]; then
  echo "Something went wrong during the objects delete."
  exit ${EXIT_CMD}
fi

echo "Objects are deleted."
exit ${EXIT_CMD}
