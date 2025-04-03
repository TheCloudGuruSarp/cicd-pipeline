#!/bin/bash

# Smoke test script for microservice application

# Set default environment if not provided
ENV=${1:-dev}

# Validate environment
if [[ "$ENV" != "dev" && "$ENV" != "staging" && "$ENV" != "prod" ]]; then
  echo "Error: Environment must be one of: dev, staging, prod"
  exit 1
fi

echo "Running smoke tests for $ENV environment..."

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

# Function to test an endpoint
test_endpoint() {
  local endpoint=$1
  local expected_status=$2
  local description=$3
  
  echo "Testing $description..."
  
  # Use kubectl to run a curl command in the cluster
  status_code=$(kubectl run curl-test-$RANDOM --image=curlimages/curl:7.82.0 --restart=Never --rm -i --quiet -- \
    curl -s -o /dev/null -w "%{http_code}" "$SERVICE_URL$endpoint")
  
  if [ "$status_code" -eq "$expected_status" ]; then
    echo "✅ $description: Success (Status: $status_code)"
    return 0
  else
    echo "❌ $description: Failed (Expected: $expected_status, Got: $status_code)"
    return 1
  fi
}

# Run tests
failed=0

# Test health endpoint
test_endpoint "/health" 200 "Health check" || failed=1

# Test API endpoint
test_endpoint "/api" 200 "API root" || failed=1

# Test items endpoint
test_endpoint "/api/items" 200 "Get items" || failed=1

# Exit with status
if [ $failed -eq 0 ]; then
  echo "✅ All smoke tests passed!"
  exit 0
else
  echo "❌ Some smoke tests failed!"
  exit 1
fi