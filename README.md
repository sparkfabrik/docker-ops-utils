# ops-utils

This is a very small docker image with some useful operation utils (like rclone, mysql-client, postgresql-client, wait-for-it).

## MySQL

MySQL specific commands. The commands can manage plain SQL or GZIP compressed dump files.

### Import from bucket

```bash
docker run --rm ops-utils:latest mysql import-from-bucket
```

### Paramenters

| Parameter | Environment Variable | Description |
| ----- | ----- | ----- |
| `--db-host` | `DB_HOST` | Defines the database host |
| `--db-user` | `DB_USER` | Defines the database user |
| `--db-password` | `DB_PASSWORD` | Defines the database password |
| `--db-name` | `DB_NAME` | Defines the database name |
| `--db-port` | `DB_PORT` | Defines the database port [default: 3306] |
| `--provider` | `PROVIDER` | Defines the bucket provider (aws, gcs, minio) |
| `--bucket-endpoint` | `BUCKET_ENDPOINT` | Defines the bucket endpoint |
| `--bucket` | `BUCKET` | Defines the bucket |
| `--file` | `FILE` | Defines the file in the bucket (*.sql or *.sql.gz) |
| `--rclone-add-params` | `RCLONE_ADD_PARAMS` | Defines the additional parameters to be passed to rclone command |
| `--timeout-bucket` | `TIMEOUT_BUCKET` | Defines the maximum waiting time for bucket set up (default 10s) |
| `--timeout-mysql` | `TIMEOUT_MYSQL` | Defines the maximum waiting time for mysql service (default 30s) |

### Export to bucket

```bash
docker run --rm ops-utils:latest mysql export-to-bucket
```

### Paramenters

| Parameter | Environment Variable | Description |
| ----- | ----- | ----- |
| `--db-host` | `DB_HOST` | Defines the database host |
| `--db-user` | `DB_USER` | Defines the database user |
| `--db-password` | `DB_PASSWORD` | Defines the database password |
| `--db-name` | `DB_NAME` | Defines the database name |
| `--db-port` | `DB_PORT` | Defines the database port [default: 3306] |
| `--provider` | `PROVIDER` | Defines the bucket provider (aws, gcs, minio) |
| `--bucket-endpoint` | `BUCKET_ENDPOINT` | Defines the bucket endpoint |
| `--bucket` | `BUCKET` | Defines the bucket |
| `--file` | `FILE` | Defines the file in the bucket (*.sql or *.sql.gz) |
| `--rclone-add-params` | `RCLONE_ADD_PARAMS` | Defines the additional parameters to be passed to rclone command |
| `--timeout-bucket` | `TIMEOUT_BUCKET` | Defines the maximum waiting time for bucket set up (default 10s) |
| `--timeout-mysql` | `TIMEOUT_MYSQL` | Defines the maximum waiting time for mysql service (default 30s) |

### AWS Auth

In order to use the AWS S3 buckets you need to specify the following environment variables:

| Variable | Description |
| ----- | ----- |
| `AWS_ACCESS_KEY_ID` | AWS IAM access key ID |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret access key |
| `AWS_DEFAULT_REGION` | AWS bucket region |

### GCS Auth

In order to use the Google Cloud Storage buckets you need to specify the following environment variable:

| Variable | Description |
| ----- | ----- |
| `GOOGLE_APPLICATION_CREDENTIALS` | Defines the file path of the service account file |

### Minio Auth

In order to use the Minio buckets you need to specify the following environment variables:

| Variable | Description |
| ----- | ----- |
| `BUCKET_ENDPOINT` | Defines the bucket endpoint |
| `MINIO_ACCESS_KEY` | Minio access key |
| `MINIO_SECRET_KEY` | Minio secret key |

