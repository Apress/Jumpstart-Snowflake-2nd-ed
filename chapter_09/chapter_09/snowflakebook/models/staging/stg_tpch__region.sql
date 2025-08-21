SELECT
    r_regionkey AS region_key,
    r_name AS region_name,
    r_comment AS comment,
    current_timestamp() AS dbt_loaded_at
FROM {{ source('tpch', 'region') }}
