SELECT
    p.part_key AS product_key,
    p.part_name AS product_name,
    p.manufacturer,
    p.brand,
    p.part_type AS product_type,
    p.container_type,
    p.retail_price,
    current_timestamp() AS dbt_loaded_at
FROM {{ ref('stg_tpch__part') }} AS p
