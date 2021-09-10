#!/bin/sh

# Source functions library.
. ${BASE}/functions

SCRIPT=$(basename $0)
export SUBCOMMAND=""

export BUCKET=${BUCKET:-}

show_usage() {
  cat <<EOM
Usage: ${BASE_SCRIPT} ${TOPIC} [SUBCOMMAND] [OPTIONS]

SUBCOMMANDS
  clean-bucket                        Remove all files and versions from a bucket

OPTIONS
  --bucket                            Defines the bucket
EOM
}

print_dry_run() {
  PAD=40
  cat <<EOM
I will run the subcommand '${SUBCOMMAND}' with the variables defined as below:

EOM

  printf "%-${PAD}s %s\n" "BUCKET" "${BUCKET}"
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
  case "${1}" in
    --bucket) BUCKET="${2}"; shift 2 ;;
    -*|--*=) echo "Error: Unsupported flag ${1}" >&2; exit 1 ;;
    *) PARAMS="$PARAMS $1"; shift ;;
  esac
done

eval set -- "$PARAMS"

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
