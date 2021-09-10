#!/bin/sh
set -e

export BASE=$(dirname $0)

# Source functions library.
. ${BASE}/functions

envprepare
copyfiles dump.sql.gz ./
copybucket entirebucket/seeds

# Expectations

# There is 2 object in root (count)
TEST_STR="There is 2 object in root (count)"
ACTUAL=$(bucketlsf "http://minio-dst:9000" dstbucket/ | wc -l)
EXPECTED="2"
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  fail "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"
fi
success "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"

# dump.sql.gz is present in root (count)
TEST_STR="dump.sql.gz is present in root (count)"
ACTUAL=$(bucketlsf "http://minio-dst:9000" dstbucket/dump.sql.gz | wc -l)
EXPECTED="1"
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  fail "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"
fi
success "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"

# dump.sql.gz is present in root (filename)
TEST_STR="dump.sql.gz is present in root (filename)"
ACTUAL=$(bucketlsf "http://minio-dst:9000" dstbucket/dump.sql.gz)
EXPECTED="dump.sql.gz"
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  fail "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"
fi
success "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"

# entirebucket folder is present in root (count)
TEST_STR="entirebucket folder is present in root (count)"
ACTUAL=$(bucketlsf "http://minio-dst:9000" dstbucket/entirebucket | wc -l)
EXPECTED="1"
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  fail "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"
fi
success "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"

# entirebucket folder is present in root (filename)
TEST_STR="entirebucket folder is present in root (filename)"
ACTUAL=$(bucketlsf "http://minio-dst:9000" dstbucket/ | grep entirebucket)
EXPECTED="entirebucket/"
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  fail "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"
fi
success "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"

# entirebucket folder contains only seeds subfolder (count)
TEST_STR="entirebucket folder contains only seeds subfolder (count)"
ACTUAL=$(bucketlsf "http://minio-dst:9000" dstbucket/entirebucket/ | wc -l)
EXPECTED="1"
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  fail "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"
fi
success "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"

# entirebucket folder contains only seeds subfolder (filename)
TEST_STR="entirebucket folder contains only seeds subfolder (filename)"
ACTUAL=$(bucketlsf "http://minio-dst:9000" dstbucket/entirebucket/)
EXPECTED="seeds/"
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  fail "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"
fi
success "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"

# seeds subfolder contains correct files (count)
TEST_STR="seeds subfolder contains correct files (count)"
ACTUAL=$(bucketlsf "http://minio-dst:9000" dstbucket/entirebucket/seeds/ | wc -l)
EXPECTED="2"
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  fail "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"
fi
success "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"

# seeds subfolder contains correct files (dump.sql)
TEST_STR="seeds subfolder contains correct files (dump.sql)"
ACTUAL=$(bucketlsf "http://minio-dst:9000" dstbucket/entirebucket/seeds/dump.sql)
EXPECTED="dump.sql"
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  fail "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"
fi
success "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"

# seeds subfolder contains correct files (dump.sql.gz)
TEST_STR="seeds subfolder contains correct files (dump.sql.gz)"
ACTUAL=$(bucketlsf "http://minio-dst:9000" dstbucket/entirebucket/seeds/dump.sql.gz)
EXPECTED="dump.sql.gz"
if [ "${ACTUAL}" != "${EXPECTED}" ]; then
  fail "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"
fi
success "${TEST_STR}" "${ACTUAL}" "${EXPECTED}"

# End of Expectations

envdestroy
