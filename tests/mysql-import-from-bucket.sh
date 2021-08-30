#!/bin/sh
set -e

export BASE=$(dirname $0)

# Source functions library.
. ${BASE}/functions

envprepare

# Expectations

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

# Row content with ID=1 on tbl1
TEST_STR="The row content where id=1 on tbl1"
ACTUAL=$(query "SELECT name FROM tbl1 WHERE id=1;")
EXPECTED="name1"
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  fail "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"
fi
success "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"

# Row content with ID=1 on tbl2
TEST_STR="The row content where id=1 on tbl2"
ACTUAL=$(query "SELECT name FROM tbl2 WHERE id=1;")
EXPECTED="name4"
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  fail "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"
fi
success "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"

# End of Expectations

envdestroy
