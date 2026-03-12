-- init/init-db.sql
-- Create multiple databases
CREATE DATABASE airbyte;
CREATE DATABASE payments_raw;
CREATE DATABASE payments;

-- Connect to payments database
\c payments;

-- Create UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create processors table
CREATE TABLE processors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    api_version VARCHAR(50),
    environment VARCHAR(20) NOT NULL,
    base_url VARCHAR(255),
    webhook_url VARCHAR(255),
    api_key_hint VARCHAR(20),
    account_id VARCHAR(255),
    supported_currencies TEXT[],
    supported_payment_methods TEXT[],
    supports_partial_capture BOOLEAN DEFAULT false,
    supports_partial_refund BOOLEAN DEFAULT true,
    supports_recurring BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    configuration JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create merchants table
CREATE TABLE merchants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    processor_id UUID NOT NULL REFERENCES processors(id),
    external_merchant_id VARCHAR(255) NOT NULL,
    merchant_code VARCHAR(100) UNIQUE,
    legal_name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    business_type VARCHAR(50),
    mcc VARCHAR(4),
    industry VARCHAR(100),
    website VARCHAR(255),
    country VARCHAR(2) NOT NULL,
    timezone VARCHAR(50),
    support_email VARCHAR(255),
    support_phone VARCHAR(50),
    default_currency VARCHAR(3),
    supported_currencies TEXT[],
    settlement_currency VARCHAR(3),
    status VARCHAR(50) NOT NULL,
    risk_profile VARCHAR(20),
    kyc_status VARCHAR(50),
    kyc_verified_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB,
    activated_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_processor_merchant UNIQUE(processor_id, external_merchant_id)
);

-- Create transactions table
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    processor_id UUID NOT NULL REFERENCES processors(id),
    merchant_id UUID NOT NULL REFERENCES merchants(id),
    transaction_id VARCHAR(255) NOT NULL,
    merchant_reference_number VARCHAR(255),
    transaction_type VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,
    amount BIGINT NOT NULL,
    currency VARCHAR(3) NOT NULL,
    payment_method_type VARCHAR(50),
    network VARCHAR(50),
    customer_id VARCHAR(255),
    customer_country VARCHAR(2),
    three_d_secure BOOLEAN,
    processor_transaction_response TEXT,
    gateway_rejection VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    three_d_secure_response VARCHAR(255),
    timezone VARCHAR(100),
    network_response VARCHAR(255),
    statement_descriptor VARCHAR(255),
    stored_credential VARCHAR(50),
    funding_type VARCHAR(50),
    avs_response VARCHAR(50),
    cvc_response VARCHAR(50),
    issuer_name VARCHAR(255),
    issuer_country VARCHAR(2),
    bin VARCHAR(8),
    card_product_id VARCHAR(100),
    card_category VARCHAR(50),
    payment_account_reference VARCHAR(255),
    liability_shift VARCHAR(50),
    device VARCHAR(255),
    industry_enchance_data VARCHAR(255),
    refunded VARCHAR(50),
    refund_reason VARCHAR(255),
    disputed VARCHAR(50),
    dispute_reason VARCHAR(255),
    marketplace_indicator VARCHAR(50),
    submerchant_name VARCHAR(255),
    fingerprint VARCHAR(255),
    mcc VARCHAR(4),
    CONSTRAINT unique_processor_transaction UNIQUE(processor_id, transaction_id)
);

-- Create indexes
CREATE INDEX idx_transactions_merchant_id ON transactions(merchant_id);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_type ON transactions(transaction_type);
CREATE INDEX idx_transactions_created_at ON transactions(created_at);
CREATE INDEX idx_transactions_merchant_reference ON transactions(merchant_reference_number);
CREATE INDEX idx_transactions_customer_country ON transactions(customer_country);

-- Connect to payments_raw database
\c payments_raw;

-- Create UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create schema for raw data
CREATE SCHEMA IF NOT EXISTS raw_data;

-- Create raw tables for CSV imports
CREATE TABLE raw_data.stripe_transactions (
    id VARCHAR(255),
    amount INTEGER,
    currency VARCHAR(3),
    status VARCHAR(50),
    payment_method_type VARCHAR(50),
    payment_method_brand VARCHAR(50),
    payment_method_last4 VARCHAR(4),
    customer_email VARCHAR(255),
    customer_country VARCHAR(2),
    merchant_id VARCHAR(255),
    created_at TIMESTAMP,
    metadata JSONB
);

CREATE TABLE raw_data.adyen_transactions (
    psp_reference VARCHAR(255),
    merchant_reference VARCHAR(255),
    amount_value INTEGER,
    amount_currency VARCHAR(3),
    result_code VARCHAR(50),
    payment_method VARCHAR(50),
    card_brand VARCHAR(50),
    card_last4 VARCHAR(4),
    shopper_email VARCHAR(255),
    shopper_country VARCHAR(2),
    merchant_account VARCHAR(255),
    creation_date TIMESTAMP,
    additional_data JSONB
);

CREATE TABLE raw_data.rapyd_transactions (
    transaction_id VARCHAR(255),
    order_id VARCHAR(255),
    amount INTEGER,
    currency VARCHAR(3),
    status VARCHAR(50),
    payment_method_type VARCHAR(50),
    card_brand VARCHAR(50),
    card_last4 VARCHAR(4),
    customer_email VARCHAR(255),
    customer_country VARCHAR(2),
    merchant_id VARCHAR(255),
    created_at TIMESTAMP,
    metadata JSONB
);

CREATE TABLE raw_data.checkout_transactions (
    payment_id VARCHAR(255),
    reference VARCHAR(255),
    amount INTEGER,
    currency VARCHAR(3),
    status VARCHAR(50),
    source_type VARCHAR(50),
    card_scheme VARCHAR(50),
    card_last4 VARCHAR(4),
    customer_email VARCHAR(255),
    billing_country VARCHAR(2),
    merchant_id VARCHAR(255),
    processed_on TIMESTAMP,
    metadata JSONB
);

CREATE TABLE raw_data.processors (
    id UUID,
    name VARCHAR(100),
    display_name VARCHAR(100),
    environment VARCHAR(20),
    is_active BOOLEAN
);

CREATE TABLE raw_data.merchants (
    id UUID,
    processor_id UUID,
    external_merchant_id VARCHAR(255),
    merchant_code VARCHAR(100),
    legal_name VARCHAR(255),
    display_name VARCHAR(255),
    country VARCHAR(2),
    status VARCHAR(50)
);
