#!/bin/bash
set -e

echo "Initializing Recursive CTE Database..."

# Create a function to run SQL files
run_sql_file() {
    local file="$1"
    echo "Running: $file"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$file"
}

# Wait for PostgreSQL to be ready
until pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"; do
    echo "Waiting for PostgreSQL to be ready..."
    sleep 2
done

echo "PostgreSQL is ready. Starting initialization..."

# Create a directory for logs
mkdir -p /workspace/logs

echo "Database initialization completed!"
echo "Logs are available in /workspace/logs/"
