#!/bin/sh

SCRIPT=$(basename $0)
export SUBCOMMAND=""

export DB_HOST=${DB_HOST:-}
export DB_USER=${DB_USER:-}
export DB_PASSWORD=${DB_PASSWORD:-}
export DB_NAME=${DN_NAME:-}
export DB_PORT=${DB_PORT:-3306}
export BUCKET=${BUCKET:-}
export FILE=${FILE:-}

show_usage() {
  cat <<EOM
Usage: ${BASE_SCRIPT} ${TOPIC} [SUBCOMMAND] [OPTIONS]

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

# Real process
if [ -x "${WD}/subcommand/${SUBCOMMAND}.sh" ]; then
  SUBCMD="${WD}/subcommand/${SUBCOMMAND}.sh"
  exec "${SUBCMD}" "$@"
else
  show_usage
  exit 21
fi
