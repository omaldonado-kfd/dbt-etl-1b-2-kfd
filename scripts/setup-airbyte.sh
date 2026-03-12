#!/bin/bash

echo "Setting up Airbyte connections..."

# Wait for Airbyte to be ready
sleep 30

# Note: Airbyte API setup would go here once services are running
# This is a placeholder for manual configuration instructions

echo "Please configure Airbyte manually at http://localhost:8000"
echo "1. Create a File source pointing to /sample-data"
echo "2. Create a Postgres destination pointing to payments_raw database"
echo "3. Set up sync for each CSV file to corresponding raw_data table"

echo "Airbyte setup instructions complete!"
