#!/bin/sh

# Source functions library.
. ${BASE}/functions

DST_DIR="/tmp"

# Check for the required input
if [ -z "${BUCKET}" ]; then
  echo "You have to define the bucket name"
  exit 12
fi

# All the required inputs are present! Do the job
debug "All the required inputs are present. Go on with the real job."

debug "Delete the file versions and the delete markers"
aws s3api delete-objects --bucket "${BUCKET}" --delete "{\"Objects\": $(aws s3api list-object-versions --bucket "${BUCKET}" --output json | jq '. | to_entries | [.[] | select(.key | match("^Versions|DeleteMarkers$")) | .value[] | {Key:.Key,VersionId:.VersionId}]')}"
