#!/bin/bash

# Integration test script for microservice application

# Set default environment if not provided
ENV=${1:-dev}

# Validate environment
if [[ "$ENV" != "dev" && "$ENV" != "staging" && "$ENV" != "prod" ]]; then
  echo "Error: Environment must be one of: dev, staging, prod"
  exit 1
fi

echo "Running integration tests for $ENV environment..."

# Get service URL based on environment
case "$ENV" in
  "dev")
    SERVICE_URL="http://microservice-app.microservices-dev.svc.cluster.local"
    ;;
  "staging")
    SERVICE_URL="http://microservice-app.microservices-staging.svc.cluster.local"
    ;;
  "prod")
    SERVICE_URL="http://microservice-app.microservices-prod.svc.cluster.local"
    ;;
esac

# Create a temporary pod for testing
echo "Creating test pod..."
kubectl run integration-test-$RANDOM \
  --image=curlimages/curl:7.82.0 \
  --restart=Never \
  --env="SERVICE_URL=$SERVICE_URL" \
  --command -- sleep 3600 &

# Wait for pod to be ready
echo "Waiting for test pod to be ready..."
sleep 10

# Get the pod name
TEST_POD=$(kubectl get pods -l run=integration-test --no-headers | awk '{print $1}' | head -n 1)

echo "Using test pod: $TEST_POD"

# Function to test an endpoint
test_endpoint() {
  local method=$1
  local endpoint=$2
  local data=$3
  local expected_status=$4
  local description=$5
  
  echo "Testing $description..."
  
  # Build curl command based on method
  local curl_cmd="curl -s -o /dev/null -w '%{http_code}' -X $method $SERVICE_URL$endpoint"
  
  # Add data for POST/PUT
  if [ -n "$data" ]; then
    curl_cmd="$curl_cmd -H 'Content-Type: application/json' -d '$data'"
  fi
  
  # Execute command in the pod
  status_code=$(kubectl exec $TEST_POD -- sh -c "$curl_cmd")
  
  if [ "$status_code" -eq "$expected_status" ]; then
    echo "u2705 $description: Success (Status: $status_code)"
    return 0
  else
    echo "u274c $description: Failed (Expected: $expected_status, Got: $status_code)"
    return 1
  fi
}

# Run tests
failed=0

# Test health endpoint
test_endpoint "GET" "/health" "" 200 "Health check" || failed=1

# Test API endpoints
test_endpoint "GET" "/api" "" 200 "API root" || failed=1
test_endpoint "GET" "/api/items" "" 200 "Get items" || failed=1

# Test creating an item
test_endpoint "POST" "/api/items" '{"name":"Test Item"}' 201 "Create item" || failed=1

# Test validation
test_endpoint "POST" "/api/items" '{"description":"Missing name"}' 400 "Validation check" || failed=1

# Clean up
echo "Cleaning up test pod..."
kubectl delete pod $TEST_POD

# Exit with status
if [ $failed -eq 0 ]; then
  echo "u2705 All integration tests passed!"
  exit 0
else
  echo "u274c Some integration tests failed!"
  exit 1
fi