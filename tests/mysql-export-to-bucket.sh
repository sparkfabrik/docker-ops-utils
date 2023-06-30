#!/bin/sh
set -e

export BASE=$(dirname $0)

# Source functions library.
. ${BASE}/functions

envprepare
mysqlimport
mysql_create_exp_database
mysqlimport_exported_db

# Expectations

# Current DB is the re-imported
TEST_STR="The selected db is the re-imported"
ACTUAL=$(query_exported_db "SELECT DATABASE();")
EXPECTED="$(getenvvar DB_NAME_EXP)"
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  fail "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"
fi
success "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"

# Row count on tbl1
TEST_STR="The rows count on tbl1"
ACTUAL=$(query_exported_db "SELECT COUNT(*) FROM tbl1;")
EXPECTED="3"
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  fail "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"
fi
success "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"

# Row count on tbl2
TEST_STR="The rows count on tbl2"
ACTUAL=$(query_exported_db "SELECT COUNT(*) FROM tbl2;")
EXPECTED="4"
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  fail "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"
fi
success "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"

# Row content with ID=1 on tbl1
TEST_STR="The row content where id=1 on tbl1"
ACTUAL=$(query_exported_db "SELECT name FROM tbl1 WHERE id=1;")
EXPECTED="name1"
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  fail "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"
fi
success "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"

# Row content with ID=1 on tbl2
TEST_STR="The row content where id=1 on tbl2"
ACTUAL=$(query_exported_db "SELECT name FROM tbl2 WHERE id=1;")
EXPECTED="name4"
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  fail "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"
fi
success "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"

# End of Expectations

envdestroy
