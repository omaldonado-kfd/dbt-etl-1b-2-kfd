# Payment ETL Demo

A complete ETL pipeline for processing payment transactions from multiple providers using Airbyte and DBT.

## Architecture

- **PostgreSQL**: Database for raw and transformed data
- **Airbyte**: Data ingestion and synchronization
- **DBT**: Data transformation and modeling
- **Docker Compose**: Container orchestration

## Quick Start

1. Start all services:
```bash
docker-compose up -d
Wait for services to be ready (2-3 minutes):
docker-compose ps
Run the demo:
docker exec -it dbt /scripts/run-demo.sh
Services
Airbyte UI: http://localhost:8000
PostgreSQL: localhost:5432
Username: postgres
Password: postgres
Databases: airbyte, payments_raw, payments
Data Flow
CSV files in
sample-data/
directory
Loaded into PostgreSQL
payments_raw
database
DBT transforms raw data into normalized tables
Final tables in
payments
database
Project Structure
.
├── docker-compose.yml      # Container orchestration
├── init/                   # Database initialization
├── sample-data/           # Sample CSV files
├── dbt/                   # DBT project
│   ├── models/           # SQL transformations
│   │   ├── staging/     # Staging models
│   │   └── marts/       # Final models
│   └── profiles.yml     # DBT configuration
└── scripts/              # Utility scripts
Sample Data
The demo includes sample transactions from:

Stripe
Adyen
Rapyd
Checkout.com
Viewing Results
After running the demo, query the transformed data:

-- Connect to database
docker exec -it postgres psql -U postgres -d payments

-- View transactions
SELECT * FROM transactions LIMIT 10;

-- Summary by processor
SELECT 
    p.display_name,
    COUNT(*) as count,
    SUM(t.amount) as total
FROM transactions t
JOIN processors p ON t.processor_id = p.id
GROUP BY p.display_name;
Customization
Add new CSV files to
sample-data/
Create corresponding staging models in
dbt/models/staging/
Update the transformation logic as needed
Run
dbt run
to apply changes
Troubleshooting
Check logs:
docker-compose logs [service-name]

Restart services:
docker-compose restart

Reset everything:
docker-compose down -v && docker-compose up -d
