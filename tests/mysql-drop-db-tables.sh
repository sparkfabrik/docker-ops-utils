#!/bin/sh
set -e

export BASE=$(dirname $0)

# Source functions library.
. ${BASE}/functions

envprepare
mysqlimport

# Expectations

# Current DB is the imported
TEST_STR="The selected db is the imported"
ACTUAL=$(query "SELECT DATABASE();")
EXPECTED="$(getenvvar DB_NAME)"
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  fail "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"
fi
success "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"

# Row count on tbl1
TEST_STR="The rows count on tbl1"
ACTUAL=$(query "SELECT COUNT(*) FROM tbl1;")
EXPECTED="3"
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  fail "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"
fi
success "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"

# Row count on tbl2
TEST_STR="The rows count on tbl2"
ACTUAL=$(query "SELECT COUNT(*) FROM tbl2;")
EXPECTED="4"
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  fail "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"
fi
success "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"

mysqldroptables

# The db is empty
TEST_STR="SHOW TABLES returns an empty string"
ACTUAL=$(query "SHOW TABLES;")
EXPECTED=""
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  fail "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"
fi
success "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"

# End of Expectations

envdestroy
