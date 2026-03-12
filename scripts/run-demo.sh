#!/bin/bash

echo "Starting Payment ETL Demo..."

# 1. Load CSVs into PostgreSQL raw tables
echo "Loading sample data into raw tables..."
docker exec -it postgres psql -U postgres -d payments_raw -c "
COPY raw_data.stripe_transactions FROM '/sample-data/stripe_transactions.csv' WITH CSV HEADER;
COPY raw_data.adyen_transactions FROM '/sample-data/adyen_transactions.csv' WITH CSV HEADER;
COPY raw_data.rapyd_transactions FROM '/sample-data/rapyd_transactions.csv' WITH CSV HEADER;
COPY raw_data.checkout_transactions FROM '/sample-data/checkout_transactions.csv' WITH CSV HEADER;
COPY raw_data.processors FROM '/sample-data/processors.csv' WITH CSV HEADER;
COPY raw_data.merchants FROM '/sample-data/merchants.csv' WITH CSV HEADER;
"

# 2. Run DBT transformations
echo "Running DBT transformations..."
docker exec -it dbt dbt run

# 3. Run DBT tests
echo "Running DBT tests..."
docker exec -it dbt dbt test

# 4. Display results
echo "Displaying results..."
docker exec -it postgres psql -U postgres -d payments -c "
SELECT 
    p.display_name as processor,
    COUNT(*) as transaction_count,
    SUM(t.amount) as total_amount,
    AVG(t.amount) as avg_amount,
    COUNT(DISTINCT t.merchant_id) as merchant_count
FROM transactions t
JOIN processors p ON t.processor_id = p.id
GROUP BY p.display_name
ORDER BY transaction_count DESC;
"

echo "Demo complete! Access Airbyte at http://localhost:8000"
