#!/bin/sh
set -e

mc config host add minio http://${MINIO_HOST}:9000 ${MINIO_ACCESS_KEY} ${MINIO_SECRET_KEY} --api S3v4

mc mb -p minio/seeds
mc policy public minio/seeds
mc cp /minio/seeds/* minio/seeds
mc cp --recursive /minio/basebucket minio/seeds

mc config host add minio_dst http://${MINIO_HOST_DST}:9000 ${MINIO_ACCESS_KEY} ${MINIO_SECRET_KEY} --api S3v4

mc mb -p minio_dst/dstbucket
