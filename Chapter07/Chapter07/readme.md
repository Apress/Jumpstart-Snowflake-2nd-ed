# Iceberg and Snowflake

Snowflake Open Catalog is a catalog implementation for Apache Iceberg™ tables and is built on the open source Apache Iceberg™ REST protocol. Snowflake Open Catalog is a managed service for Apache Polaris.

## Create virtual environment

Install Conda https://docs.anaconda.com/miniconda/install/#quick-command-line-install

Download Conda https://www.anaconda.com/download/success


Create file `environment.yml`

```yaml
name: iceberg-lab
channels:
  - conda-forge
dependencies:
  - findspark=2.0.1
  - jupyter=1.0.0
  - pyspark=3.5.0
  - openjdk=11.0.13
```

Disable SSL:

```bash
conda config --set ssl_verify no
```

Create virtual environment using Conda:

```bash
conda env create -f environment.yml
```

Activate environment:

```bash
conda activate iceberg-lab
```

## Prepare Snowflake

In Snowflake we should create resources:

```sql
CREATE WAREHOUSE iceberg_lab;
CREATE ROLE iceberg_lab;
CREATE DATABASE iceberg_lab;
CREATE SCHEMA iceberg_lab;
GRANT ALL ON DATABASE iceberg_lab TO ROLE iceberg_lab WITH GRANT OPTION;
GRANT ALL ON SCHEMA iceberg_lab.iceberg_lab TO ROLE iceberg_lab WITH GRANT OPTION;;
GRANT ALL ON WAREHOUSE iceberg_lab TO ROLE iceberg_lab WITH GRANT OPTION;;

CREATE USER iceberg_lab
    PASSWORD='Iceberglab2024!',
    LOGIN_NAME='ICEBERG_LAB',
    MUST_CHANGE_PASSWORD=FALSE,
    DISABLED=FALSE,
    DEFAULT_WAREHOUSE='ICEBERG_LAB',
    DEFAULT_NAMESPACE='ICEBERG_LAB.ICEBERG_LAB',
    DEFAULT_ROLE='ICEBERG_LAB';

GRANT ROLE iceberg_lab TO USER iceberg_lab;
GRANT ROLE iceberg_lab TO ROLE accountadmin;
GRANT ROLE accountadmin TO USER iceberg_lab;
```

Snowflake Trial Instance:

```
https://app.snowflake.com/hugqjik/ya03647/#/homepage
iceberglab
Iceberglab2024!
```

Create External Volume `iceberg_lab_vol`, for AWS S3 we can use this guide: https://docs.snowflake.com/en/user-guide/tables-iceberg-configure-external-volume-s3

Bucket: jumpstart-iceberg-snowflake

Policy: jumpstart-iceberg-policy 

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:DeleteObject",
                "s3:DeleteObjectVersion"
            ],
            "Resource": "arn:aws:s3:::jumpstart-iceberg-snowflake/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": "arn:aws:s3:::jumpstart-iceberg-snowflake",
            "Condition": {
                "StringLike": {
                    "s3:prefix": [
                        "*"
                    ]
                }
            }
        }
    ]
}
```

Role: jumpstart-iceberg-role



```sql
USE ROLE accountadmin;

CREATE OR REPLACE EXTERNAL VOLUME iceberg_lab_vol
   STORAGE_LOCATIONS =
      (
         (
            NAME = 'iceberg-lab'
            STORAGE_PROVIDER = 'S3'
            STORAGE_BASE_URL = 's3://jumpstart-iceberg-snowflake'
            STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::180795190369:role/jumpstart-iceberg-role'
            STORAGE_AWS_EXTERNAL_ID = 'iceberg_table_external_id'
         )
      );

GRANT ALL ON EXTERNAL VOLUME iceberg_lab_vol TO ROLE iceberg_lab WITH GRANT OPTION;
```

Retrieve deatils in Snowlfake:

```sql
DESC EXTERNAL VOLUME iceberg_lab_vol;
```

It will tell us snowflake user ARN: 

```json
"STORAGE_AWS_IAM_USER_ARN":"arn:aws:iam::881490105466:user/a98t0000-s"
```

Verify the access:

```sql
SELECT SYSTEM$VERIFY_EXTERNAL_VOLUME('iceberg_lab_vol');
```

## Create a Snowflake-managed Iceberg Table

Iceberg Tables can either use Snowflake, AWS Glue, or object storage as the catalog. 

```sql
USE ROLE iceberg_lab;
USE DATABASE iceberg_lab;
USE SCHEMA iceberg_lab;
CREATE OR REPLACE ICEBERG TABLE customer_iceberg (
    c_custkey INTEGER,
    c_name STRING,
    c_address STRING,
    c_nationkey INTEGER,
    c_phone STRING,
    c_acctbal INTEGER,
    c_mktsegment STRING,
    c_comment STRING
)  
    CATALOG='SNOWFLAKE'
    EXTERNAL_VOLUME='iceberg_lab_vol'
    BASE_LOCATION='';
```

Ingest data:

```sql
INSERT INTO customer_iceberg
  SELECT * FROM snowflake_sample_data.tpch_sf1.customer;
```

It will insert 150000 rows into Iceberg format.

## Query Data with Apache Spark


```python
import os
os.environ['SPARK_HOME'] = '~/anaconda3/envs/iceberg-lab/lib/python3.12/site-packages/pyspark'
import findspark
findspark.init()
findspark.find()

os.environ['SNOWFLAKE_CATALOG_URI'] = "jdbc:snowflake://gj91678.eu-central-1.snowflakecomputing.com"
os.environ['SNOWFLAKE_ROLE'] = "ICEBERG_LAB"
os.environ['SNOWFLAKE_USERNAME'] = "ICEBERG_LAB"
os.environ['SNOWFLAKE_PASSWORD'] = "password"
# Environment variables for AWS
os.environ['PACKAGES'] = "org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.4.1,net.snowflake:snowflake-jdbc:3.14.2,software.amazon.awssdk:bundle:2.20.160,software.amazon.awssdk:url-connection-client:2.20.160"
os.environ['AWS_REGION'] = "eu-central-1"
os.environ['AWS_ACCESS_KEY_ID'] = "AKIASUGB3VRQ2VETAWJZ"
os.environ['AWS_SECRET_ACCESS_KEY'] = "secret"

```

```python
import pyspark
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName('iceberg_lab')\
    .config('spark.jars.packages', os.environ['PACKAGES'])\
    .config('spark.sql.extensions', 'org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions')\
    .config("spark.driver.allowMultipleContexts","true")\
    .getOrCreate()

```

```python
spark.conf.set("spark.sql.defaultCatalog", "snowflake_catalog")
spark.conf.set("spark.sql.catalog.snowflake_catalog", "org.apache.iceberg.spark.SparkCatalog")
spark.conf.set("spark.sql.catalog.snowflake_catalog.catalog-impl", "org.apache.iceberg.snowflake.SnowflakeCatalog")
spark.conf.set("spark.sql.catalog.snowflake_catalog.uri", os.environ['SNOWFLAKE_CATALOG_URI'])
spark.conf.set("spark.sql.catalog.snowflake_catalog.jdbc.role", os.environ['SNOWFLAKE_ROLE'])
spark.conf.set("spark.sql.catalog.snowflake_catalog.jdbc.user", os.environ['SNOWFLAKE_USERNAME'])
spark.conf.set("spark.sql.catalog.snowflake_catalog.jdbc.password", os.environ['SNOWFLAKE_PASSWORD'])
spark.conf.set("spark.sql.iceberg.vectorization.enabled", "false")

# aws
spark.conf.set("spark.sql.catalog.snowflake_catalog.io-impl", "org.apache.iceberg.aws.s3.S3FileIO")
spark.conf.set("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
spark.conf.set("spark.hadoop.fs.s3a.aws.credentials.provider", "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider")
spark.conf.set("spark.hadoop.fs.s3a.access.key", os.environ['AWS_ACCESS_KEY_ID'])
spark.conf.set("spark.hadoop.fs.s3a.secret.key", os.environ['AWS_SECRET_ACCESS_KEY'])
spark.conf.set("spark.hadoop.fs.s3a.endpoint", "s3.amazonaws.com")
spark.conf.set("spark.hadoop.fs.s3a.endpoint.region", os.environ['AWS_REGION'])

```

```python
spark.sql("SHOW NAMESPACES IN ICEBERG_LAB").show()
spark.sql("USE ICEBERG_LAB.ICEBERG_LAB")
spark.sql("SHOW TABLES").show()
df = spark.table("iceberg_lab.iceberg_lab.customer_iceberg")
df.show()
```


## Reference links
https://docs.snowflake.com/en/user-guide/tutorials/create-your-first-iceberg-table
https://quickstarts.snowflake.com/guide/getting_started_iceberg_tables/index.html#0
https://docs.snowflake.com/en/user-guide/tables-iceberg-create
https://quickstarts.snowflake.com/guide/data_lake_using_apache_iceberg_with_snowflake_and_aws_glue/index.html#0

## Resources
Free Trial Snowflake: https://signup.snowflake.com/
