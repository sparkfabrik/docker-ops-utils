#!/bin/sh

# Source functions library.
. ${BASE}/functions

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

# All the required inputs are present! Do the job
debug "All the required inputs are present. Go on with the real job."

MYSQL_CMD="mysql --skip-column-names --silent --raw -h "${DB_HOST}" -P ${DB_PORT} -u "${DB_USER}" --password="${DB_PASSWORD}" --database="${DB_NAME}""

# Wait for mysql service
debug "Wait for mysql service (timeout ${TIMEOUT_MYSQL} seconds)."
wait-for-it ${DB_HOST}:${DB_PORT} -t ${TIMEOUT_MYSQL}
EXIT_WAIT=$?
debug "Wait for mysql service ended (${EXIT_WAIT})."
if [ ${EXIT_WAIT} -ne 0 ]; then
  echo "ERROR: Wait for mysql service fails."
  exit ${EXIT_WAIT}
fi

debug "Fetch database tables"
debug "${MYSQL_CMD} -e \"SHOW TABLES;\""

TABLES=$(${MYSQL_CMD} -e "SHOW TABLES;")
if [ -z "${TABLES}" ]; then
  echo "There are no tables to drop"
  exit 0
fi

debug "There are some tables to be deleted"

QUERY="SET FOREIGN_KEY_CHECKS = 0;"
JOINED_TABLES=""
for TABLE in ${TABLES}; do
  debug "Drop table ${TABLE}"
  QUERY="${QUERY} DROP TABLE ${TABLE};"
done

QUERY="${QUERY} SET FOREIGN_KEY_CHECKS = 1;"

debug "Drop all tables"
debug "${MYSQL_CMD} -e \"${QUERY}\""

${MYSQL_CMD} -e "${QUERY}"

debug "The database is now empty"
