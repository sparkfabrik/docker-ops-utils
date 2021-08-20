#!/bin/sh

SCRIPT=$(basename $0)
COMMAND=${SCRIPT%.sh}

DB_HOST=${DB_HOST:-}
DB_USER=${DB_USER:-}
DB_PASSWORD=${DB_PASSWORD:-}
DN_NAME=${DN_NAME:-}
DB_PORT=${DB_PORT:-3306}
BUCKET=${BUCKET:-}

show_usage() {
    cat <<EOM
Usage: ${BASE_SCRIPT} ${COMMAND} <SUBCOMMAND>
Options:
  --help,-h                           Print this help message
  --db-host                           Defines the database host
  --db-user                           Defines the database user
  --db-password                       Defines the database password
  --db-name                           Defines the database name
  --db-port                           Defines the database port
  --bucket                            Defines the bucket
  --file                              Defines the file in the bucket
SUBCOMMANDS
  import
EOM
}

# Process arguments
PARAMS=""
while [ -n "${1}" ]; do
  case "$1" in
    --help|-h) show_usage; exit 0 ;;
    --db-host) DB_HOST="${2}"; shift 2 ;;
    --db-user) DB_USER="${2}"; shift 2 ;;
    --db-password) DB_PASSWORD="${2}"; shift 2 ;;
    --db-name) DB_NAME="${2}"; shift 2 ;;
    --db-port) DB_PORT="${2}"; shift 2 ;;
    --bucket) BUCKET="${2}"; shift 2 ;;
    -*|--*=) echo "Error: Unsupported flag $1" >&2; exit 1 ;;
    *) PARAMS="$PARAMS $1"; shift ;;
  esac
done

eval set -- "$PARAMS"

show_usage
