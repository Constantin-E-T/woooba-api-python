#!/bin/bash

# Set API base URL
BASE_URL="https://woooba-api-python.serverplus.org"
SUCCESS=0
FAILURE=0
TESTS_RUN=0

# Function to run a test and validate the response
run_test() {
  local test_name="$1"
  local command="$2"
  local expected_status="$3"
  local validation_command="$4"
  
  echo "Running test: $test_name"
  TESTS_RUN=$((TESTS_RUN + 1))
  
  # Run the command and capture output and status
  response=$(eval "$command" 2>&1)
  status=$?
  
  # Check if command executed successfully
  if [ $status -ne 0 ]; then
    echo "❌ Test failed: Command execution error"
    echo "   Command: $command"
    echo "   Error: $response"
    FAILURE=$((FAILURE + 1))
    return 1
  fi
  
  # If expected status is provided, validate it
  if [ -n "$expected_status" ]; then
    http_status=$(echo "$response" | grep -o "HTTP/[0-9.]* [0-9]*" | awk '{print $2}')
    if [ "$http_status" != "$expected_status" ]; then
      echo "❌ Test failed: Expected status $expected_status, got $http_status"
      FAILURE=$((FAILURE + 1))
      return 1
    fi
  fi
  
  # If validation command is provided, run it
  if [ -n "$validation_command" ]; then
    validation=$(echo "$response" | eval "$validation_command")
    if [ $? -ne 0 ] || [ "$validation" != "true" ]; then
      echo "❌ Test failed: Validation failed"
      echo "   Validation command: $validation_command"
      echo "   Response: $response"
      FAILURE=$((FAILURE + 1))
      return 1
    fi
  fi
  
  echo "✅ Test passed"
  SUCCESS=$((SUCCESS + 1))
  return 0
}

echo "========== WOOOBA API Automated Tests =========="

# Test 1: Health Check
run_test "Health Check" \
  "curl -s -X GET \"${BASE_URL}/api/health/\"" \
  "200" \
  "jq -r '.status' | grep -q 'healthy' && echo true"

# Test 2: Create a task
create_response=$(curl -s -X POST "${BASE_URL}/tasks/v1/" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Automated Test Task",
    "description": "Created during automated testing",
    "completed": false
  }')
TASK_ID=$(echo "$create_response" | jq -r '.id')

run_test "Create Task" \
  "echo '$create_response'" \
  "" \
  "jq -e '.title == \"Automated Test Task\"' > /dev/null && echo true"

# Test 3: Get the created task
run_test "Get Task" \
  "curl -s -X GET \"${BASE_URL}/tasks/v1/${TASK_ID}/\"" \
  "" \
  "jq -e '.id == $TASK_ID' > /dev/null && echo true"

# Test 4: Update the task
run_test "Update Task" \
  "curl -s -X PUT \"${BASE_URL}/tasks/v1/${TASK_ID}/\" \
    -H \"Content-Type: application/json\" \
    -d '{
      \"title\": \"Updated Automated Test Task\",
      \"description\": \"Updated during automated testing\",
      \"completed\": true
    }'" \
  "" \
  "jq -e '.completed == true' > /dev/null && echo true"

# Test 5: Verify the update was saved
run_test "Verify Update" \
  "curl -s -X GET \"${BASE_URL}/tasks/v1/${TASK_ID}/\"" \
  "" \
  "jq -e '.title == \"Updated Automated Test Task\" and .completed == true' > /dev/null && echo true"

# Test 6: Delete the task
run_test "Delete Task" \
  "curl -s -X DELETE \"${BASE_URL}/tasks/v1/${TASK_ID}/\" -v" \
  "204" \
  "grep -q 'HTTP/2 204' && echo true"

# Test 7: Verify deletion
run_test "Verify Deletion" \
  "curl -s -X GET \"${BASE_URL}/tasks/v1/${TASK_ID}/\" -v" \
  "404" \
  "grep -q 'HTTP/2 404' && echo true"

# Test 8: Bulk create for performance testing
echo "Creating 10 tasks for performance testing..."
for i in {1..10}; do
  curl -s -X POST "${BASE_URL}/tasks/v1/" \
    -H "Content-Type: application/json" \
    -d "{
      \"title\": \"Performance Test Task $i\",
      \"description\": \"Created during performance testing\",
      \"completed\": false
    }" > /dev/null
done

# Test 9: Check response time with multiple tasks
run_test "Response Time" \
  "time curl -s -X GET \"${BASE_URL}/tasks/v1/\"" \
  "" \
  "jq 'length > 5' > /dev/null && echo true"

# Print summary
echo "========== Test Summary =========="
echo "Tests run: $TESTS_RUN"
echo "Passed: $SUCCESS"
echo "Failed: $FAILURE"

if [ $FAILURE -eq 0 ]; then
  echo "All tests passed! 🎉"
  exit 0
else
  echo "Some tests failed. 😞"
  exit 1
fi