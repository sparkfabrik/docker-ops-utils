#!/bin/sh

SCRIPT=$(basename $0)
COMMAND=${SCRIPT%.sh}
SUBCOMMAND=""

DB_HOST=${DB_HOST:-}
DB_USER=${DB_USER:-}
DB_PASSWORD=${DB_PASSWORD:-}
DN_NAME=${DN_NAME:-}
DB_PORT=${DB_PORT:-3306}
BUCKET=${BUCKET:-}
FILE=${FILE:-}

show_usage() {
    cat <<EOM
Usage: ${BASE_SCRIPT} ${COMMAND} [SUBCOMMAND] [OPTIONS]

SUBCOMMANDS
  import                              Import database from a bucket file

OPTIONS
  --help,-h                           Print this help message
  --db-host                           Defines the database host
  --db-user                           Defines the database user
  --db-password                       Defines the database password
  --db-name                           Defines the database name
  --db-port                           Defines the database port [default: 3306]
  --bucket                            Defines the bucket
  --file                              Defines the file in the bucket
EOM
}

print_dry_run() {
  PAD=40
  cat <<EOM
I will run the subcommand '${SUBCOMMAND}' with the variables defined as below:

EOM
printf "%-${PAD}s %s\n" "DB_HOST" "${DB_HOST}"
printf "%-${PAD}s %s\n" "DB_USER" "${DB_USER}"
printf "%-${PAD}s %s\n" "DB_PASSWORD" "${DB_PASSWORD}"
printf "%-${PAD}s %s\n" "DN_NAME" "${DN_NAME}"
printf "%-${PAD}s %s\n" "DB_PORT" "${DB_PORT}"
printf "%-${PAD}s %s\n" "BUCKET" "${BUCKET}"
printf "%-${PAD}s %s\n" "FILE" "${FILE}"
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
while [ -n "${1}" ]; do
  case "$1" in
    --db-host) DB_HOST="${2}"; shift 2 ;;
    --db-user) DB_USER="${2}"; shift 2 ;;
    --db-password) DB_PASSWORD="${2}"; shift 2 ;;
    --db-name) DB_NAME="${2}"; shift 2 ;;
    --db-port) DB_PORT="${2}"; shift 2 ;;
    --bucket) BUCKET="${2}"; shift 2 ;;
    --file) FILE="${2}"; shift 2 ;;
    -*|--*=) echo "Error: Unsupported flag ${1}" >&2; exit 1 ;;
    *) PARAMS="$PARAMS $1"; shift ;;
  esac
done

eval set -- "$PARAMS"

if [ ${DRY_RUN} -eq 1 ]; then
  print_dry_run
  exit 0
fi

# Real process
if [ "${SUBCOMMAND}" = "import" ]; then
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
  rclone --s3-env-auth=true copy :s3://bucket-name/test.txt test.txt
fi
