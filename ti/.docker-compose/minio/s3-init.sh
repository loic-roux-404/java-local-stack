#!/bin/sh
set -e

COMPANIES=${COMPANIES:-worldline}

mc config host add minio-cloud --api "${AWS_API_VERSION:-S3v4}" http://minio:9900 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD

# Bucket, ignore if already present

IFS=','
for COMPANY in $COMPANIES; do
    mc mb minio-cloud/${S3_BUCKET_PREFIX}$COMPANY || true
done

# Policy & User
mc admin policy create minio-cloud user /run/user.json
mc admin user add minio-cloud testClientKey testClientSecret
mc admin user add minio-cloud $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY
mc admin policy attach minio-cloud user --user testClientKey
mc admin policy attach minio-cloud user --user $AWS_ACCESS_KEY_ID
