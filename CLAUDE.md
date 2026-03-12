# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Payment ETL pipeline using Airbyte for data ingestion and DBT for transformations. The system processes payment transactions from multiple payment processors (Stripe, Adyen, Rapyd, Checkout.com) into a unified data model.

## Architecture

**Data Flow:**
1. CSV files → PostgreSQL `payments_raw` database (raw_data schema)
2. DBT staging models normalize each processor's data format
3. DBT marts models union all transactions into final tables
4. Final data in PostgreSQL `payments` database

**Key Components:**
- **PostgreSQL**: Three databases (`airbyte`, `payments_raw`, `payments`)
- **Airbyte**: Data ingestion (UI at http://localhost:8000)
- **DBT**: Transformations using staging → marts pattern
- **Docker Compose**: Orchestrates all services

## Common Commands

### Running the Demo
```bash
# Start all services (first time or after down -v)
docker-compose up -d

# Wait for services to be ready (2-3 minutes), then run full demo
docker exec -it dbt /scripts/run-demo.sh
```

### DBT Development
```bash
# Run all DBT models
docker exec -it dbt dbt run

# Run specific model
docker exec -it dbt dbt run --select stg_stripe_transactions

# Run models downstream from a model
docker exec -it dbt dbt run --select stg_stripe_transactions+

# Run tests
docker exec -it dbt dbt test

# Run specific test
docker exec -it dbt dbt test --select stg_stripe_transactions

# Compile SQL to see what will run
docker exec -it dbt dbt compile

# Install DBT packages
docker exec -it dbt dbt deps

# Debug connection
docker exec -it dbt dbt debug
```

### Database Operations
```bash
# Connect to payments database
docker exec -it postgres psql -U postgres -d payments

# Connect to payments_raw database
docker exec -it postgres psql -U postgres -d payments_raw

# Load CSV data manually
docker exec -it postgres psql -U postgres -d payments_raw -c "
COPY raw_data.stripe_transactions FROM '/sample-data/stripe_transactions.csv' WITH CSV HEADER;
"

# View transaction summary
docker exec -it postgres psql -U postgres -d payments -c "
SELECT p.display_name, COUNT(*) as count, SUM(t.amount) as total
FROM transactions t
JOIN processors p ON t.processor_id = p.id
GROUP BY p.display_name;
"
```

### Container Management
```bash
# View logs for specific service
docker-compose logs -f dbt
docker-compose logs -f postgres

# Restart services
docker-compose restart

# Stop all services (preserves data)
docker-compose down

# Stop and remove all data
docker-compose down -v

# Check service status
docker-compose ps
```

## DBT Project Structure

**Project Name:** `payment_analytics`
**Profile:** `payment_analytics` (connects to `payments` database)

### Models Organization

**Staging Models** (`dbt/models/staging/`):
- Materialized as views in `staging` schema
- One model per payment processor: `stg_{processor}_transactions.sql`
- Normalizes processor-specific fields to common schema
- Each staging model:
  - Joins with processors table to get processor_id
  - Joins with merchants table to map external_merchant_id to internal merchant_id
  - Maps processor-specific status codes to standard statuses (completed, processing, failed)
  - Standardizes field names and types

**Marts Models** (`dbt/models/marts/`):
- Materialized as tables in `public` schema
- `transactions.sql`: UNIONs all staging models, adds date partitioning columns
- `merchants.sql`: Simple passthrough of staging merchants
- `processors.sql`: Simple passthrough of staging processors

**Sources** (`dbt/models/sources.yml`):
- Defined as `raw_data` source pointing to `payments_raw.raw_data` schema
- Tables: stripe_transactions, adyen_transactions, rapyd_transactions, checkout_transactions, processors, merchants

### Data Model

**Normalized Transaction Schema:**
All staging models transform to this common schema with these key fields:
- `id` (UUID): Generated via uuid_generate_v4()
- `processor_id`, `merchant_id`: Foreign keys
- `external_transaction_id`: Processor's transaction ID
- `external_reference`: Order/reference from metadata
- `status`: Standardized (completed, processing, failed)
- `amount`, `currency`: Transaction amounts in minor units (cents)
- `fee_amount`, `net_amount`: Calculated fees and net amounts
- `payment_method_type`, `payment_method_brand`, `payment_method_last4`: Payment details
- `customer_email`, `customer_country`: Customer info
- `initiated_at`, `completed_at`: Timestamps
- `metadata`: JSONB field for processor-specific data

## Database Schema Notes

The `payments` database schema is defined in `init/init-db.sql`:
- Uses UUID extension (`uuid-ossp`)
- Three main tables: processors, merchants, transactions
- Unique constraints prevent duplicate processor+transaction combinations
- GIN index on metadata JSONB field for fast queries

## Development Notes

**DBT Configuration:**
- dbt-postgres version 1.7.0
- Python 3.9 in Docker container
- Profiles in `dbt/profiles.yml` (connects to postgres:5432)
- Project config in `dbt/dbt_project.yml`

**When adding new payment processors:**
1. Add CSV sample data to `sample-data/`
2. Create raw table in `init/init-db.sql` under `raw_data` schema
3. Add source definition in `dbt/models/sources.yml`
4. Create staging model `dbt/models/staging/stg_{processor}_transactions.sql`
5. Add to UNION in `dbt/models/marts/transactions.sql`
6. Update `scripts/run-demo.sh` to load the CSV data

**Transaction amounts are stored in minor units** (e.g., cents for USD). All monetary calculations should preserve this.

**Status mapping pattern:**
Each processor has different status codes. Staging models use CASE statements to map to: `completed`, `processing`, `failed`.

**Fee calculations:**
Stripe example: `(amount * 0.029 + 30)` - adjust per processor's actual fee structure.
