#!/bin/bash

QUOTEDCMD=()
for token in "$@"; do
  QUOTEDCMD+=($(printf "%q" "$token"))
done
CMD="${QUOTEDCMD[*]}"

export BASE=$(dirname $0)

# Source functions library.
. ${BASE}/functions

export BASE_SCRIPT=$(basename $0)
export DRY_RUN=0
export TOPIC=
export WD=

export DEBUG=${DEBUG:-0}

show_usage() {
  cat <<EOM
Usage: ${BASE_SCRIPT} <COMMAND> [SUBCOMMAND] [OPTIONS]

COMMANDS
  ash | sh
EOM

for topic in "${BASE}"/commands/*; do
  cmd=${topic#"${BASE}"/commands/}
  if [ -x "${topic}/main.sh" ]; then
    cat <<EOM
  ${cmd}
EOM
  fi
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

if [ "${1}" = "ash" ] || [ "${1}" = "sh" ]; then
  eval ${CMD}
elif [ -x "${BASE}/commands/${1}/main.sh" ]; then
  CMD="${BASE}/commands/${1}/main.sh"
  TOPIC="${1}"
  WD="${BASE}/commands/${1}"
  shift
  exec "${CMD}" "$@"
else
  show_usage
  exit 2
fi