#!/bin/sh

BASE=$(dirname $0)
BASE_SCRIPT=$(basename $0)

DEBUG=${DEBUG:-0}
DRY_RUN=0

show_usage() {
  cat <<EOM
Usage: ${BASE_SCRIPT} <COMMAND> [SUBCOMMAND] [OPTIONS]

COMMANDS
EOM

for script in commands/*.sh; do
  cmd=${script%".sh"}
  cmd=${cmd#"commands/"}
  cat <<EOM
  ${cmd}
EOM
done

  cat <<EOM

OPTIONS
  --help,-h                           Print this help message
  --dry-run                           The script will only print the required configuration
EOM
}

# Process arguments
PARAMS=""
while [ -n "${1}" ]; do
  case "$1" in
    --help|-h) show_usage; exit 0 ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) PARAMS="$PARAMS $1"; shift ;;
  esac
done

eval set -- "$PARAMS"

if [ -z "${1}" ]; then
  echo "You must specify one of the available command"
  show_usage
  exit 1
fi

if [ -x "commands/${1}.sh" ]; then
  COMMAND="commands/${1}.sh"
  shift
  exec env BASE="${BASE}" BASE_SCRIPT="${BASE_SCRIPT}" DRY_RUN="${DRY_RUN}" "${COMMAND}" "$@"
else
  show_usage
  exit 2
fi