SELECT
    l_orderkey AS order_key,
    l_partkey AS part_key,
    l_suppkey AS supplier_key,
    l_linenumber AS line_number,
    l_quantity AS quantity,
    l_extendedprice AS extended_price,
    l_discount AS discount,
    l_tax AS tax,
    l_returnflag AS return_flag,
    l_linestatus AS line_status,
    l_shipdate AS ship_date,
    l_commitdate AS commit_date,
    l_receiptdate AS receipt_date,
    l_shipinstruct AS ship_instructions,
    l_shipmode AS ship_mode,
    l_comment AS comment,
    current_timestamp() AS dbt_loaded_at
FROM {{ source('tpch', 'lineitem') }}
