{{ config(
    materialized='table',
    indexes=[
        {'columns': ['processor_id'], 'type': 'btree'},
        {'columns': ['merchant_id'], 'type': 'btree'},
        {'columns': ['status'], 'type': 'btree'},
        {'columns': ['created_at'], 'type': 'btree'}
    ]
) }}

WITH all_transactions AS (
    SELECT * FROM {{ ref('stg_stripe_transactions') }}
    UNION ALL
    SELECT * FROM {{ ref('stg_adyen_transactions') }}
    UNION ALL
    SELECT * FROM {{ ref('stg_rapyd_transactions') }}
    UNION ALL
    SELECT * FROM {{ ref('stg_checkout_transactions') }}
)
SELECT
    *,
    EXTRACT(YEAR FROM created_at) as year,
    EXTRACT(MONTH FROM created_at) as month,
    EXTRACT(DAY FROM created_at) as day
FROM all_transactions
