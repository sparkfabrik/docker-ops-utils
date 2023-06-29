#!/bin/sh

# Source functions library.
. ${BASE}/functions

SCRIPT=$(basename $0)
export SUBCOMMAND=""

export DB_HOST=${DB_HOST:-}
export DB_USER=${DB_USER:-}
export DB_PASSWORD=${DB_PASSWORD:-}
export DB_NAME=${DB_NAME:-}
export DB_PORT=${DB_PORT:-3306}
export PROVIDER=${PROVIDER:-}
export PROVIDER_LOWER=
export BUCKET_ENDPOINT=${BUCKET_ENDPOINT:-}
export BUCKET=${BUCKET:-}
export FILE=${FILE:-}
export RCLONE_ADD_PARAMS=${RCLONE_ADD_PARAMS:-}
export MYSQLDUMP_ADD_PARAMS=${MYSQLDUMP_ADD_PARAMS:-}

export TIMEOUT_BUCKET=${TIMEOUT_BUCKET:-10}
export TIMEOUT_MYSQL=${TIMEOUT_MYSQL:-30}

export INCLUDE_SYSTEM_DATABASES=${INCLUDE_SYSTEM_DATABASES:-}
export EXCLUDE_DATABASES=${EXCLUDE_DATABASES:-}

show_usage() {
  cat <<EOM
Usage: ${BASE_SCRIPT} ${TOPIC} [SUBCOMMAND] [OPTIONS]

SUBCOMMANDS
  help                                Print this help message
  import-from-bucket                  Import database from a bucket file
  export-to-bucket                    Export database (mysqldump) to a bucket
  export-all-to-bucket                Export all databases (mysqldump) to a bucket
  drop-db-tables                      Drop all tables in the database

OPTIONS
  --db-host                           Defines the database host
  --db-user                           Defines the database user
  --db-password                       Defines the database password
  --db-name                           Defines the database name
  --db-port                           Defines the database port [default: 3306]
  --provider                          Defines the bucket provider (aws, gcs, minio)
  --bucket-endpoint                   Defines the bucket endpoint
  --bucket                            Defines the bucket
  --file                              Defines the file in the bucket (*.sql or *.sql.gz)
  --rclone-add-params                 Defines the additional parameters to be passed to rclone command
  --mysqldump-add-params              Defines the additional parameters to be passed to mysqldump command
  --timeout-bucket                    Defines the maximum waiting time for bucket set up (default ${TIMEOUT_BUCKET}s)
  --timeout-mysql                     Defines the maximum waiting time for mysql service (default ${TIMEOUT_MYSQL}s)
  --include-system-databases          Defines if system databases should be included in export-all-to-bucket command (default false) 
  --exclude                           Defines the databases (comma separated list) to be excluded in export-all-to-bucket command
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
  printf "%-${PAD}s %s\n" "DB_NAME" "${DB_NAME}"
  printf "%-${PAD}s %s\n" "DB_PORT" "${DB_PORT}"
  printf "%-${PAD}s %s\n" "PROVIDER" "${PROVIDER}"
  printf "%-${PAD}s %s\n" "PROVIDER_LOWER" "${PROVIDER_LOWER}"
  printf "%-${PAD}s %s\n" "BUCKET_ENDPOINT" "${BUCKET_ENDPOINT}"
  printf "%-${PAD}s %s\n" "BUCKET" "${BUCKET}"
  printf "%-${PAD}s %s\n" "FILE" "${FILE}"
  printf "%-${PAD}s %s\n" "RCLONE_ADD_PARAMS" "${RCLONE_ADD_PARAMS}"
  printf "%-${PAD}s %s\n" "MYSQLDUMP_ADD_PARAMS" "${MYSQLDUMP_ADD_PARAMS}"
  printf "%-${PAD}s %s\n" "TIMEOUT_BUCKET" "${TIMEOUT_BUCKET}"
  printf "%-${PAD}s %s\n" "TIMEOUT_MYSQL" "${TIMEOUT_MYSQL}"
  printf "%-${PAD}s %s\n" "INCLUDE_SYSTEM_DATABASES" "${INCLUDE_SYSTEM_DATABASES}"
  printf "%-${PAD}s %s\n" "EXCLUDE_DATABASES" "${EXCLUDE_DATABASES}"
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
    --db-host) DB_HOST="${2}"; shift 2 ;;
    --db-user) DB_USER="${2}"; shift 2 ;;
    --db-password) DB_PASSWORD="${2}"; shift 2 ;;
    --db-name) DB_NAME="${2}"; shift 2 ;;
    --db-port) DB_PORT="${2}"; shift 2 ;;
    --provider) PROVIDER="${2}"; shift 2 ;;
    --bucket-endpoint) BUCKET_ENDPOINT="${2}"; shift 2 ;;
    --bucket) BUCKET="${2}"; shift 2 ;;
    --file) FILE="${2}"; shift 2 ;;
    --rclone-add-params) RCLONE_ADD_PARAMS="${2}"; shift 2 ;;
    --mysqldump-add-params) MYSQLDUMP_ADD_PARAMS="${2}"; shift 2 ;;
    --timeout-bucket) TIMEOUT_BUCKET="${2}"; shift 2 ;;
    --timeout-mysql) TIMEOUT_MYSQL="${2}"; shift 2 ;;
    -*|--*=) echo "Error: Unsupported flag ${1}" >&2; exit 1 ;;
    *) PARAMS="$PARAMS $1"; shift ;;
  esac
done

eval set -- "$PARAMS"

PROVIDER_LOWER=$(echo ${PROVIDER} | awk '{print tolower($0)}')

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
