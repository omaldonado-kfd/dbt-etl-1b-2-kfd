WITH source AS (
    SELECT * FROM {{ source('raw_data', 'stripe_transactions') }}
),
processors AS (
    SELECT id as processor_id
    FROM {{ source('raw_data', 'processors') }}
    WHERE name = 'stripe'
),
merchants AS (
    SELECT id as merchant_id, external_merchant_id
    FROM {{ source('raw_data', 'merchants') }}
    WHERE processor_id = (SELECT processor_id FROM processors)
)
SELECT
    uuid_generate_v4() as id,
    p.processor_id,
    m.merchant_id,
    s.id as transaction_id,
    s.metadata->>'order_id' as merchant_reference_number,
    'payment' as transaction_type,
    CASE
        WHEN s.status = 'succeeded' THEN 'completed'
        WHEN s.status = 'pending' THEN 'processing'
        WHEN s.status = 'failed' THEN 'failed'
        ELSE s.status
    END as status,
    s.amount::BIGINT as amount,
    s.currency as currency,
    s.payment_method_type,
    s.payment_method_brand as network,
    NULL as customer_id,
    s.customer_country,
    NULL::BOOLEAN as three_d_secure,
    NULL as processor_transaction_response,
    NULL as gateway_rejection,
    s.created_at as created_at,
    NULL as three_d_secure_response,
    NULL as timezone,
    NULL as network_response,
    NULL as statement_descriptor,
    NULL as stored_credential,
    NULL as funding_type,
    NULL as avs_response,
    NULL as cvc_response,
    NULL as issuer_name,
    NULL as issuer_country,
    NULL as bin,
    NULL as card_product_id,
    NULL as card_category,
    NULL as payment_account_reference,
    NULL as liability_shift,
    NULL as device,
    NULL as industry_enchance_data,
    NULL as refunded,
    NULL as refund_reason,
    NULL as disputed,
    NULL as dispute_reason,
    NULL as marketplace_indicator,
    NULL as submerchant_name,
    NULL as fingerprint,
    NULL as mcc
FROM source s
CROSS JOIN processors p
LEFT JOIN merchants m ON s.merchant_id = m.external_merchant_id
