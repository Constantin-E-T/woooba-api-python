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

echo "========== WOOOBA Support API Automated Tests =========="

# Test 1: Create a conversation
create_conv_response=$(curl -s -X POST "${BASE_URL}/support/v1/conversations/" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Automated Test Conversation",
    "contact_email": "test@example.com",
    "contact_name": "Test User",
    "session_key": "test-session-'$(date +%s)'"
  }')
CONV_ID=$(echo "$create_conv_response" | jq -r '.id')

run_test "Create Conversation" \
  "echo '$create_conv_response'" \
  "" \
  "jq -e '.title == \"Automated Test Conversation\"' > /dev/null && echo true"

# Test 2: Get the created conversation
run_test "Get Conversation" \
  "curl -s -X GET \"${BASE_URL}/support/v1/conversations/${CONV_ID}/\"" \
  "" \
  "jq -e '.id == \"$CONV_ID\"' > /dev/null && echo true"

# Test 3: Create a message in the conversation
create_msg_response=$(curl -s -X POST "${BASE_URL}/support/v1/conversations/${CONV_ID}/messages/" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "This is a test message from automated testing",
    "sender_name": "Test User",
    "is_from_staff": false
  }')
MSG_ID=$(echo "$create_msg_response" | jq -r '.id')

run_test "Create Message" \
  "echo '$create_msg_response'" \
  "" \
  "jq -e '.content | contains(\"test message\")' > /dev/null && echo true"

# Test 4: Get the created message
run_test "Get Message" \
  "curl -s -X GET \"${BASE_URL}/support/v1/conversations/${CONV_ID}/messages/${MSG_ID}/\"" \
  "" \
  "jq -e '.id == \"$MSG_ID\"' > /dev/null && echo true"

# Test 5: Update the message
run_test "Update Message" \
  "curl -s -X PUT \"${BASE_URL}/support/v1/conversations/${CONV_ID}/messages/${MSG_ID}/\" \
    -H \"Content-Type: application/json\" \
    -d '{
      \"content\": \"Updated test message from automated testing\",
      \"sender_name\": \"Test User\",
      \"is_from_staff\": false
    }'" \
  "" \
  "jq -e '.content | contains(\"Updated test message\")' > /dev/null && echo true"

# Test 6: Create a staff response
staff_msg_response=$(curl -s -X POST "${BASE_URL}/support/v1/conversations/${CONV_ID}/add_message/" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "This is a staff response to your question",
    "sender_name": "Support Staff",
    "is_from_staff": true
  }')
STAFF_MSG_ID=$(echo "$staff_msg_response" | jq -r '.id')

run_test "Create Staff Message" \
  "echo '$staff_msg_response'" \
  "" \
  "jq -e '.is_from_staff == true' > /dev/null && echo true"

# Test 7: Check that conversation lists all messages
run_test "Conversation Contains Messages" \
  "curl -s -X GET \"${BASE_URL}/support/v1/conversations/${CONV_ID}/\"" \
  "" \
  "jq -e '.messages | length >= 2' > /dev/null && echo true"

# Create a temporary file for attachment testing
TEMP_FILE="/tmp/test_attachment_$(date +%s).txt"
echo "This is a test attachment file for the support API." > $TEMP_FILE

# Test 8: Upload attachment to message
ATTACH_RESPONSE=$(curl -s -X POST "${BASE_URL}/support/v1/conversations/${CONV_ID}/messages/${MSG_ID}/attachments/" \
  -F "file=@${TEMP_FILE}")
ATTACH_ID=$(echo "$ATTACH_RESPONSE" | jq -r '.id')

run_test "Upload Attachment" \
  "echo '$ATTACH_RESPONSE'" \
  "" \
  "jq -e '.filename | contains(\"test_attachment\")' > /dev/null && echo true"

# Test 9: Get attachment
run_test "Get Attachment" \
  "curl -s -X GET \"${BASE_URL}/support/v1/conversations/${CONV_ID}/messages/${MSG_ID}/attachments/${ATTACH_ID}/\"" \
  "" \
  "jq -e '.id == \"$ATTACH_ID\"' > /dev/null && echo true"

# Test 10: Delete attachment
run_test "Delete Attachment" \
  "curl -s -X DELETE \"${BASE_URL}/support/v1/conversations/${CONV_ID}/messages/${MSG_ID}/attachments/${ATTACH_ID}/\" -v" \
  "204" \
  "grep -q 'HTTP/[0-9.]* 204' && echo true"

# Test 11: Verify attachment deletion
run_test "Verify Attachment Deletion" \
  "curl -s -X GET \"${BASE_URL}/support/v1/conversations/${CONV_ID}/messages/${MSG_ID}/attachments/${ATTACH_ID}/\" -v" \
  "404" \
  "grep -q 'HTTP/[0-9.]* 404' && echo true"

# Test 12: Delete messages
run_test "Delete User Message" \
  "curl -s -X DELETE \"${BASE_URL}/support/v1/conversations/${CONV_ID}/messages/${MSG_ID}/\" -v" \
  "204" \
  "grep -q 'HTTP/[0-9.]* 204' && echo true"

run_test "Delete Staff Message" \
  "curl -s -X DELETE \"${BASE_URL}/support/v1/conversations/${CONV_ID}/messages/${STAFF_MSG_ID}/\" -v" \
  "204" \
  "grep -q 'HTTP/[0-9.]* 204' && echo true"

# Test 13: Delete conversation
run_test "Delete Conversation" \
  "curl -s -X DELETE \"${BASE_URL}/support/v1/conversations/${CONV_ID}/\" -v" \
  "204" \
  "grep -q 'HTTP/[0-9.]* 204' && echo true"

# Test 14: Verify conversation deletion
run_test "Verify Conversation Deletion" \
  "curl -s -X GET \"${BASE_URL}/support/v1/conversations/${CONV_ID}/\" -v" \
  "404" \
  "grep -q 'HTTP/[0-9.]* 404' && echo true"

# Clean up
rm -f $TEMP_FILE

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