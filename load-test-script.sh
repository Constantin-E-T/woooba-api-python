#!/bin/bash

BASE_URL="https://woooba-api-python.serverplus.org"
CONCURRENT_REQUESTS=10
TOTAL_REQUESTS=50

echo "========== WOOOBA API Load Test =========="
echo "Concurrent requests: $CONCURRENT_REQUESTS"
echo "Total requests: $TOTAL_REQUESTS"
echo "=================================="

# Create a temporary file for storing task IDs
TASK_IDS_FILE=$(mktemp)

# Function to create a task and store its ID
create_task() {
  local response=$(curl -s -X POST "${BASE_URL}/tasks/v1/" \
    -H "Content-Type: application/json" \
    -d "{
      \"title\": \"Load Test Task $(date +%s%N)\",
      \"description\": \"Created during load testing\",
      \"completed\": false
    }")
  
  local task_id=$(echo "$response" | jq -r '.id')
  if [ "$task_id" != "null" ]; then
    echo "$task_id" >> "$TASK_IDS_FILE"
  fi
}

# Function to read a random task
read_task() {
  # Get a random ID from existing tasks or just get all tasks if no ID available
  local ids=$(curl -s "${BASE_URL}/tasks/v1/" | jq -r '.[].id')
  if [ -n "$ids" ]; then
    local random_id=$(echo "$ids" | sort -R | head -1)
    curl -s "${BASE_URL}/tasks/v1/${random_id}/" > /dev/null
  else
    curl -s "${BASE_URL}/tasks/v1/" > /dev/null
  fi
}

# Function to update a random task
update_task() {
  # Get a random ID from our created tasks or from existing tasks
  local ids=""
  if [ -s "$TASK_IDS_FILE" ]; then
    ids=$(cat "$TASK_IDS_FILE" | sort -R | head -1)
  else
    ids=$(curl -s "${BASE_URL}/tasks/v1/" | jq -r '.[].id' | sort -R | head -1)
  fi
  
  if [ -n "$ids" ]; then
    local random_id=$(echo "$ids" | head -1)
    curl -s -X PATCH "${BASE_URL}/tasks/v1/${random_id}/" \
      -H "Content-Type: application/json" \
      -d "{
        \"title\": \"Updated Load Test Task $(date +%s%N)\"
      }" > /dev/null
  fi
}

# Function to delete a task
delete_task() {
  # Get a random ID from our created tasks
  if [ -s "$TASK_IDS_FILE" ]; then
    local ids=$(cat "$TASK_IDS_FILE")
    if [ -n "$ids" ]; then
      local random_id=$(echo "$ids" | sort -R | head -1)
      # Remove the ID from our file to avoid trying to delete it again
      grep -v "$random_id" "$TASK_IDS_FILE" > "${TASK_IDS_FILE}.tmp"
      mv "${TASK_IDS_FILE}.tmp" "$TASK_IDS_FILE"
      curl -s -X DELETE "${BASE_URL}/tasks/v1/${random_id}/" > /dev/null
    fi
  fi
}

# Array of operations to perform
operations=(create_task read_task update_task read_task)

# Start time
start_time=$(date +%s)

echo "Starting load test..."
for ((i=1; i<=$TOTAL_REQUESTS; i++)); do
  # Launch concurrent requests
  for ((j=1; j<=$CONCURRENT_REQUESTS; j++)); do
    # Select a random operation
    op_index=$((RANDOM % ${#operations[@]}))
    operation="${operations[$op_index]}"
    
    # Execute the operation in the background
    $operation &
    
    # Store the PID
    pids[$j]=$!
  done
  
  # Wait for all concurrent requests to complete
  for pid in ${pids[*]}; do
    wait $pid
  done
  
  # Progress report
  echo -ne "Completed batch $i/$((TOTAL_REQUESTS/CONCURRENT_REQUESTS))...\r"
done

# Clean up - delete all created tasks
echo -e "\nCleaning up..."
if [ -s "$TASK_IDS_FILE" ]; then
  for id in $(cat "$TASK_IDS_FILE"); do
    curl -s -X DELETE "${BASE_URL}/tasks/v1/${id}/" > /dev/null
  done
fi

# Calculate elapsed time
end_time=$(date +%s)
elapsed=$((end_time - start_time))

echo "========== Load Test Complete =========="
echo "Total time elapsed: $elapsed seconds"
echo "Total requests: $((TOTAL_REQUESTS * CONCURRENT_REQUESTS))"
echo "Average requests per second: $(bc <<< "scale=2; $((TOTAL_REQUESTS * CONCURRENT_REQUESTS)) / $elapsed")"
echo "=================================="

# Clean up temporary file
rm "$TASK_IDS_FILE"