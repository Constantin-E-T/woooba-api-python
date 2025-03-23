#!/bin/bash

# This script requires the psql client and appropriate connection permissions
DB_HOST="postgres-main.serverplus.org"
DB_PORT="5432"
DB_NAME="woooba__api"
DB_USER="postgres"

# Function to run SQL queries
run_query() {
  local query="$1"
  PGPASSWORD="73838c1da1b97bca" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$query"
}

echo "========== PostgreSQL Database Monitoring =========="

# Check database size
echo -e "\n[1] Database Size"
run_query "SELECT pg_size_pretty(pg_database_size('$DB_NAME')) AS database_size;"

# Check table sizes
echo -e "\n[2] Table Sizes"
run_query "SELECT table_name, pg_size_pretty(pg_total_relation_size(quote_ident(table_name))) as size
          FROM information_schema.tables
          WHERE table_schema = 'public'
          ORDER BY pg_total_relation_size(quote_ident(table_name)) DESC
          LIMIT 10;"

# Check number of connections
echo -e "\n[3] Current Connections"
run_query "SELECT count(*) as connections FROM pg_stat_activity WHERE datname = '$DB_NAME';"

# Check connection details
echo -e "\n[4] Connection Details"
run_query "SELECT client_addr, usename, state, query 
          FROM pg_stat_activity 
          WHERE datname = '$DB_NAME'
          ORDER BY query_start DESC LIMIT 10;"

# Check task table record count
echo -e "\n[5] Task Table Record Count"
run_query "SELECT COUNT(*) FROM tasks_task;"

# Check for slow queries
echo -e "\n[6] Recent Slow Queries (>100ms)"
run_query "SELECT query, calls, total_time, mean_time 
          FROM pg_stat_statements 
          WHERE mean_time > 100 
          AND dbid = (SELECT oid FROM pg_database WHERE datname = '$DB_NAME')
          ORDER BY mean_time DESC
          LIMIT 10;"

# Check for table bloat
echo -e "\n[7] Table Bloat (tables that might need vacuuming)"
run_query "SELECT schemaname, relname, n_dead_tup, n_live_tup, 
          round(n_dead_tup * 100.0 / (n_live_tup + n_dead_tup + 1)) as dead_percentage
          FROM pg_stat_user_tables 
          WHERE n_dead_tup > 100
          ORDER BY dead_percentage DESC
          LIMIT 10;"

# Cache hit ratio (how effectively the database is using memory)
echo -e "\n[8] Cache Hit Ratio"
run_query "SELECT sum(heap_blks_read) as heap_read, sum(heap_blks_hit) as heap_hit, 
          round(sum(heap_blks_hit) * 100.0 / (sum(heap_blks_hit) + sum(heap_blks_read) + 1)) as hit_ratio
          FROM pg_statio_user_tables;"

echo -e "\n========== Monitoring Complete =========="