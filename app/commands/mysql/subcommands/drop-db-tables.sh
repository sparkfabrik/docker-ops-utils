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
echo "All the required inputs are present. Go on with the real job."

echo "Drop all tables from database."
format_string "Parameters:" "g"
echo "$(format_string "Host:" "bold") ${DB_HOST}"
echo "$(format_string "Port:" "bold") ${DB_PORT}"
echo "$(format_string "User:" "bold") ${DB_USER}"
echo "$(format_string "Database:" "bold") ${DB_NAME}"

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

echo "Fetch database tables."
debug "${MYSQL_CMD} -e \"SHOW TABLES;\""

TABLES=$(${MYSQL_CMD} -e "SHOW TABLES;")
if [ -z "${TABLES}" ]; then
  echo "There are no tables to drop"
  exit 0
fi

echo "There are some tables to be deleted."

QUERY="SET FOREIGN_KEY_CHECKS = 0;"
JOINED_TABLES=""
for TABLE in ${TABLES}; do
  debug "Drop table ${TABLE}"
  QUERY="${QUERY} DROP TABLE ${TABLE};"
done

QUERY="${QUERY} SET FOREIGN_KEY_CHECKS = 1;"

echo "Drop all tables."
debug "${MYSQL_CMD} -e \"${QUERY}\""

${MYSQL_CMD} -e "${QUERY}"
EXIT_CMD=$?

if [ ${EXIT_CMD} -ne 0 ]; then
  echo "Something went wrong during the drop all tables."
  exit ${EXIT_CMD}
fi

echo "The database is now empty."
exit ${EXIT_CMD}

