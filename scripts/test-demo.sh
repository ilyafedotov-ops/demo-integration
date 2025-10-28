# Test Script for D365 Demo
# This script performs end-to-end testing of the deployed demo

#!/usr/bin/env bash
set -e

# Configuration
RESOURCE_GROUP="rg-d365-demo"
APIM_NAME=""
FUNC_NAME=""
LOGIC_APP_NAME=""
TENANT_ID=""
CLIENT_ID=""
CLIENT_SECRET=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting D365 Demo Smoke Tests...${NC}"

# Get resource names
echo "Getting resource names..."
APIM_NAME=$(az apim list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv)
FUNC_NAME=$(az functionapp list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv)
LOGIC_APP_NAME=$(az logic workflow list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv)

echo "APIM: $APIM_NAME"
echo "Function: $FUNC_NAME"
echo "Logic App: $LOGIC_APP_NAME"

# Test 1: Logic App Direct Call
echo -e "\n${YELLOW}Test 1: Logic App Direct Call${NC}"
LOGIC_APP_URL=$(az logic workflow show --resource-group $RESOURCE_GROUP --name $LOGIC_APP_NAME --query "accessEndpoint" -o tsv)

VENDOR_PAYLOAD='{
  "VendorAccount": "V-TEST-001",
  "Name": "Test Vendor GmbH",
  "Currency": "EUR",
  "CountryRegionId": "DE",
  "Address": {
    "Street": "Teststrasse 1",
    "City": "Berlin",
    "PostalCode": "10115"
  },
  "Email": "test@vendor.de",
  "Phone": "+49 30 123456"
}'

RESPONSE=$(curl -s -w "%{http_code}" -X POST "$LOGIC_APP_URL" \
  -H "Content-Type: application/json" \
  -d "$VENDOR_PAYLOAD")

HTTP_CODE="${RESPONSE: -3}"
BODY="${RESPONSE%???}"

if [ "$HTTP_CODE" = "202" ]; then
  echo -e "${GREEN}✓ Logic App test passed (HTTP $HTTP_CODE)${NC}"
  echo "Response: $BODY"
else
  echo -e "${RED}✗ Logic App test failed (HTTP $HTTP_CODE)${NC}"
  echo "Response: $BODY"
fi

# Test 2: Function Direct Call
echo -e "\n${YELLOW}Test 2: Function Direct Call${NC}"
FUNC_KEY=$(az functionapp keys list --resource-group $RESOURCE_GROUP --name $FUNC_NAME --query "functionKeys.default" -o tsv)
FUNC_URL="https://$FUNC_NAME.azurewebsites.net/api/HttpIngest?code=$FUNC_KEY"

RESPONSE=$(curl -s -w "%{http_code}" -X POST "$FUNC_URL" \
  -H "Content-Type: application/json" \
  -d "$VENDOR_PAYLOAD")

HTTP_CODE="${RESPONSE: -3}"
BODY="${RESPONSE%???}"

if [ "$HTTP_CODE" = "202" ]; then
  echo -e "${GREEN}✓ Function test passed (HTTP $HTTP_CODE)${NC}"
  echo "Response: $BODY"
else
  echo -e "${RED}✗ Function test failed (HTTP $HTTP_CODE)${NC}"
  echo "Response: $BODY"
fi

# Test 3: APIM Call (if JWT credentials provided)
if [ -n "$TENANT_ID" ] && [ -n "$CLIENT_ID" ] && [ -n "$CLIENT_SECRET" ]; then
  echo -e "\n${YELLOW}Test 3: APIM Call with JWT${NC}"
  
  # Get JWT token
  TOKEN_RESPONSE=$(curl -s -X POST "https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&scope=api://$CLIENT_ID/.default&grant_type=client_credentials")
  
  JWT_TOKEN=$(echo $TOKEN_RESPONSE | jq -r '.access_token')
  
  if [ "$JWT_TOKEN" != "null" ] && [ -n "$JWT_TOKEN" ]; then
    APIM_URL=$(az apim show --resource-group $RESOURCE_GROUP --name $APIM_NAME --query "gatewayRegionalUrl" -o tsv)
    
    RESPONSE=$(curl -s -w "%{http_code}" -X POST "$APIM_URL/vendor-ingest/vendors" \
      -H "Authorization: Bearer $JWT_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$VENDOR_PAYLOAD")
    
    HTTP_CODE="${RESPONSE: -3}"
    BODY="${RESPONSE%???}"
    
    if [ "$HTTP_CODE" = "202" ]; then
      echo -e "${GREEN}✓ APIM test passed (HTTP $HTTP_CODE)${NC}"
      echo "Response: $BODY"
    else
      echo -e "${RED}✗ APIM test failed (HTTP $HTTP_CODE)${NC}"
      echo "Response: $BODY"
    fi
  else
    echo -e "${RED}✗ Failed to obtain JWT token${NC}"
  fi
else
  echo -e "\n${YELLOW}Test 3: APIM Call - Skipped (no JWT credentials)${NC}"
fi

# Test 4: Check Service Bus Queue
echo -e "\n${YELLOW}Test 4: Service Bus Queue Status${NC}"
SB_NAMESPACE=$(az servicebus namespace list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv)
QUEUE_NAME="inbound"

ACTIVE_MESSAGES=$(az servicebus queue show --resource-group $RESOURCE_GROUP --namespace-name $SB_NAMESPACE --name $QUEUE_NAME --query "messageCountDetails.activeMessageCount" -o tsv)

echo "Service Bus Queue '$QUEUE_NAME' active messages: $ACTIVE_MESSAGES"

if [ "$ACTIVE_MESSAGES" -gt 0 ]; then
  echo -e "${GREEN}✓ Service Bus has messages (processing working)${NC}"
else
  echo -e "${YELLOW}! Service Bus queue is empty (may need time to process)${NC}"
fi

# Test 5: Check ADLS Gen2 Storage
echo -e "\n${YELLOW}Test 5: ADLS Gen2 Storage${NC}"
STORAGE_ACCOUNT=$(az storage account list --resource-group $RESOURCE_GROUP --query "[?contains(name, 'std')].name" -o tsv | head -1)

if [ -n "$STORAGE_ACCOUNT" ]; then
  CONTAINER_EXISTS=$(az storage container exists --account-name $STORAGE_ACCOUNT --name "landing" --query "exists" -o tsv)
  
  if [ "$CONTAINER_EXISTS" = "true" ]; then
    echo -e "${GREEN}✓ ADLS Gen2 container 'landing' exists${NC}"
    
    # List recent files
    TODAY=$(date +%Y/%m/%d)
    echo "Checking for files in vendors/$TODAY/"
    
    FILE_COUNT=$(az storage blob list --account-name $STORAGE_ACCOUNT --container-name "landing" --prefix "vendors/$TODAY/" --query "length(@)" -o tsv)
    
    if [ "$FILE_COUNT" -gt 0 ]; then
      echo -e "${GREEN}✓ Found $FILE_COUNT files in ADLS Gen2${NC}"
    else
      echo -e "${YELLOW}! No files found in ADLS Gen2 (may need time to process)${NC}"
    fi
  else
    echo -e "${RED}✗ ADLS Gen2 container 'landing' not found${NC}"
  fi
else
  echo -e "${RED}✗ ADLS Gen2 storage account not found${NC}"
fi

echo -e "\n${YELLOW}Smoke tests completed!${NC}"
echo "Check Application Insights for detailed logs and metrics."
