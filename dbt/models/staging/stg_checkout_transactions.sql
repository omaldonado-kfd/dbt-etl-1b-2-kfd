WITH source AS (
    SELECT * FROM {{ source('raw_data', 'checkout_transactions') }}
),
processors AS (
    SELECT id as processor_id
    FROM {{ source('raw_data', 'processors') }}
    WHERE name = 'checkout'
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
    s.payment_id as transaction_id,
    s.reference as merchant_reference_number,
    'payment' as transaction_type,
    CASE
        WHEN s.status = 'Captured' THEN 'completed'
        WHEN s.status = 'Pending' THEN 'processing'
        WHEN s.status = 'Declined' THEN 'failed'
        ELSE LOWER(s.status)
    END as status,
    s.amount::BIGINT as amount,
    s.currency as currency,
    s.source_type as payment_method_type,
    s.card_scheme as network,
    NULL as customer_id,
    s.billing_country as customer_country,
    NULL::BOOLEAN as three_d_secure,
    NULL as processor_transaction_response,
    NULL as gateway_rejection,
    s.processed_on as created_at,
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
