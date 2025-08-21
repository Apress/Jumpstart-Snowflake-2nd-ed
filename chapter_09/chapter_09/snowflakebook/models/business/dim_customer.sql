SELECT
    c.customer_key,
    c.customer_name,
    c.market_segment,
    c.customer_address,
    c.phone_number AS customer_phone,
    c.account_balance,
    n.nation_name,
    r.region_name,
    current_timestamp() AS dbt_loaded_at
FROM {{ ref('stg_tpch__customer') }} AS c
LEFT JOIN {{ ref('stg_tpch__nation') }} AS n ON c.nation_key = n.nation_key
LEFT JOIN {{ ref('stg_tpch__region') }} AS r ON n.region_key = r.region_key
