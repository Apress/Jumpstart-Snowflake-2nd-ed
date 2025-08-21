SELECT
    n_nationkey AS nation_key,
    n_name AS nation_name,
    n_regionkey AS region_key,
    n_comment AS comment,
    current_timestamp() AS dbt_loaded_at
FROM {{ source('tpch', 'nation') }}
