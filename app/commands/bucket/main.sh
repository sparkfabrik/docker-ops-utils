#!/bin/sh

# Source functions library.
. ${BASE}/functions

SCRIPT=$(basename $0)
export SUBCOMMAND=""

export PROVIDER=${PROVIDER:-}
export PROVIDER_SRC=${PROVIDER_SRC:-}
export PROVIDER_SRC_LOWER=
export PROVIDER_DST=${PROVIDER_DST:-}
export PROVIDER_DST_LOWER=
export BUCKET_SRC_ENDPOINT=${BUCKET_SRC_ENDPOINT:-}
export BUCKET_SRC=${BUCKET_SRC:-}
export FILE_SRC=${FILE_SRC:-""}
export BUCKET_DST_ENDPOINT=${BUCKET_DST_ENDPOINT:-}
export BUCKET_DST=${BUCKET_DST:-}
export FILE_DST=${FILE_DST:-""}
export ACL=${ACL:-}
export RCLONE_ADD_PARAMS=${RCLONE_ADD_PARAMS:-}

export TIMEOUT_BUCKET_SRC=${TIMEOUT_BUCKET_SRC:-10}
export TIMEOUT_BUCKET_DST=${TIMEOUT_BUCKET_DST:-10}

show_usage() {
  cat <<EOM
Usage: ${BASE_SCRIPT} ${TOPIC} [SUBCOMMAND] [OPTIONS]

SUBCOMMANDS
  help                                Print this help message
  copy-bucket

OPTIONS
  --provider                          Defines the bucket provider (aws, gcs, minio)
  --bucket-src-endpoint               Defines the source bucket endpoint
  --bucket-src                        Defines the source bucket
  --file-src                          Defines the source file in the bucket (default: entire bucket)
  --bucket-dst-endpoint               Defines the destination bucket endpoint
  --bucket-dst                        Defines the destination bucket
  --file-dst                          Defines the destination file in the bucket
  --acl                               Difines the ACL used to create the copied objects in the destination
  --rclone-add-params                 Defines the additional parameters to be passed to rclone command
  --timeout-bucket-src                Defines the maximum waiting time for source bucket set up (default ${TIMEOUT_BUCKET_SRC}s)
  --timeout-bucket-dst                Defines the maximum waiting time for destination bucket set up (default ${TIMEOUT_BUCKET_DST}s)
EOM
}

print_dry_run() {
  PAD=40
  cat <<EOM
I will run the subcommand '${SUBCOMMAND}' with the variables defined as below:

EOM

  printf "%-${PAD}s %s\n" "PROVIDER" "${PROVIDER}"
  printf "%-${PAD}s %s\n" "PROVIDER_LOWER" "${PROVIDER_LOWER}"
  printf "%-${PAD}s %s\n" "BUCKET_SRC_ENDPOINT" "${BUCKET_SRC_ENDPOINT}"
  printf "%-${PAD}s %s\n" "BUCKET_SRC" "${BUCKET_SRC}"
  printf "%-${PAD}s %s\n" "FILE_SRC" "${FILE_SRC}"
  printf "%-${PAD}s %s\n" "BUCKET_DST_ENDPOINT" "${BUCKET_DST_ENDPOINT}"
  printf "%-${PAD}s %s\n" "BUCKET_DST" "${BUCKET_DST}"
  printf "%-${PAD}s %s\n" "FILE_DST" "${FILE_DST}"
  printf "%-${PAD}s %s\n" "ACL" "${ACL}"
  printf "%-${PAD}s %s\n" "RCLONE_ADD_PARAMS" "${RCLONE_ADD_PARAMS}"
  printf "%-${PAD}s %s\n" "TIMEOUT_BUCKET_SRC" "${TIMEOUT_BUCKET_SRC}"
  printf "%-${PAD}s %s\n" "TIMEOUT_BUCKET_DST" "${TIMEOUT_BUCKET_DST}"
}

# Process subcommand
if [ -z "${1}" ]; then
  echo "You must specify one of the available subcommand"
  show_usage
  exit 11
fi

SUBCOMMAND="${1}"
shift

# Process arguments
PARAMS=""
while [ -n "${1:-}" ]; do
  case "${1}" in
    --provider) PROVIDER_SRC="${2}"; PROVIDER_DST="${2}"; shift 2 ;;
    --provider-src) PROVIDER_SRC="${2}"; shift 2 ;;
    --provider-dst) PROVIDER_DST="${2}"; shift 2 ;;
    --bucket-src-endpoint) BUCKET_SRC_ENDPOINT="${2}"; shift 2 ;;
    --bucket-src) BUCKET_SRC="${2}"; shift 2 ;;
    --file-src) FILE_SRC="${2}"; shift 2 ;;
    --bucket-dst-endpoint) BUCKET_DST_ENDPOINT="${2}"; shift 2 ;;
    --bucket-dst) BUCKET_DST="${2}"; shift 2 ;;
    --file-dst) FILE_DST="${2}"; shift 2 ;;
    --acl) ACL="${2}"; shift 2 ;;
    --rclone-add-params) RCLONE_ADD_PARAMS="${2}"; shift 2 ;;
    --timeout-bucket-src) TIMEOUT_BUCKET_SRC="${2}"; shift 2 ;;
    --timeout-bucket-dst) TIMEOUT_BUCKET_DST="${2}"; shift 2 ;;
    -*|--*=) echo "Error: Unsupported flag ${1}" >&2; exit 1 ;;
    *) PARAMS="$PARAMS $1"; shift ;;
  esac
done

eval set -- "$PARAMS"

PROVIDER_SRC_LOWER=$(echo ${PROVIDER_SRC} | awk '{print tolower($0)}')
PROVIDER_DST_LOWER=$(echo ${PROVIDER_DST} | awk '{print tolower($0)}')

# Check dry run execution
if [ ${DRY_RUN} -eq 1 ]; then
  print_dry_run
  exit 0
fi

# Real process
if [ -x "${WD}/subcommands/${SUBCOMMAND}.sh" ]; then
  SUBCMD="${WD}/subcommands/${SUBCOMMAND}.sh"
  exec "${SUBCMD}" "$@"
else
  show_usage
  exit 21
fi
