SELECT
    o.order_key,
    o.customer_key,
    l.part_key AS product_key,
    o.order_date,
    o.order_status,
    o.total_price AS order_total,
    l.quantity,
    l.extended_price,
    l.discount,
    l.tax,
    (l.extended_price * (1 - l.discount) * (1 + l.tax)) AS final_price,
    l.ship_date,
    l.commit_date,
    l.receipt_date,
    current_timestamp() AS dbt_loaded_at
FROM {{ ref('stg_tpch__orders') }} AS o
LEFT JOIN {{ ref('stg_tpch__lineitem') }} AS l ON o.order_key = l.order_key
