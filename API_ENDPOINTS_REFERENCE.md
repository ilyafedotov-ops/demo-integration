# API Functions and Endpoints Reference

This document provides a complete reference of all API functions and endpoints in the D365 Integration Demo solution.

---

## Table of Contents

1. [Public API Endpoints (APIM)](#1-public-api-endpoints-apim)
2. [Logic App Endpoints](#2-logic-app-endpoints)
3. [Azure Function Endpoints](#3-azure-function-endpoints)
4. [Service Bus Triggered Functions](#4-service-bus-triggered-functions)
5. [Mock D365 Endpoints](#5-mock-d365-endpoints)

---

## 1. Public API Endpoints (APIM)

These are the **production-ready, secure endpoints** exposed through Azure API Management.

### 1.1 Landing Page (Root)

**Endpoint:**
```
GET https://{apim-gateway}.azure-api.net/
```

**Authentication:** None (Public)

**Description:** Returns an HTML landing page with API documentation, credentials, and usage examples.

**Response:**
- **Status:** 200 OK
- **Content-Type:** text/html
- **Body:** Full HTML page with API documentation

**Example:**
```bash
curl https://{your-apim-gateway}.azure-api.net/
```

---

### 1.2 Vendor Ingest API

**Endpoint:**
```
POST https://{apim-gateway}.azure-api.net/vendor-ingest/vendors
```

**Authentication:** 
- **JWT Token** (Bearer scheme) - Required
- **Subscription Key** (Ocp-Apim-Subscription-Key header) - Required

**Description:** Main production endpoint for submitting vendor data. Validates JWT token, applies rate limiting (60 calls/60 seconds), and routes to the backend Logic App.

**Headers:**
```http
Authorization: Bearer {JWT_TOKEN}
Ocp-Apim-Subscription-Key: {SUBSCRIPTION_KEY}
Content-Type: application/json
```

**Request Body:**
```json
{
  "VendorAccount": "V-100045",
  "Name": "Contoso Supplies GmbH",
  "Currency": "EUR",
  "CountryRegionId": "DE",
  "Address": {
    "Street": "Musterstrasse 12",
    "City": "Ulm",
    "PostalCode": "89073"
  },
  "Email": "ap@contoso-supplies.de",
  "Phone": "+49 731 555123"
}
```

**Required Fields:**
- `VendorAccount` (string)
- `Name` (string)
- `Currency` (string)
- `CountryRegionId` (string)

**Response:**
- **Status:** 202 Accepted
- **Body:**
```json
{
  "enqueued": true,
  "id": "f85f05e8-fc78-45bc-a001-a4d07bc150c5"
}
```

**Error Responses:**

| Status | Description |
|--------|-------------|
| 400 | Bad Request - Invalid payload or missing required fields |
| 401 | Unauthorized - Invalid or missing JWT token |
| 429 | Too Many Requests - Rate limit exceeded (60 calls/60 sec) |
| 500 | Internal Server Error - Backend service unavailable |

**Example:**
```bash
# Get JWT token first
TOKEN=$(curl -X POST "https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token" \
  -d "client_id={client_id}&client_secret={secret}&scope=api://{client_id}/.default&grant_type=client_credentials" \
  | jq -r '.access_token')

# Call API
curl -X POST "https://{your-apim-gateway}.azure-api.net/vendor-ingest/vendors" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Ocp-Apim-Subscription-Key: {subscription_key}" \
  -H "Content-Type: application/json" \
  -d '{
    "VendorAccount": "V-100045",
    "Name": "Contoso Supplies GmbH",
    "Currency": "EUR",
    "CountryRegionId": "DE"
  }'
```

**APIM Policies Applied:**
1. **validate-jwt** - Validates JWT signature, expiration, and audience
2. **rate-limit-by-key** - Limits to 60 calls per 60 seconds per subscription
3. **rewrite-uri** - Rewrites `/vendors` to `/HttpIngest` for backend function
4. **set-query-parameter** - Adds function key to query string

---

## 2. Logic App Endpoints

### 2.1 Vendor Ingest Workflow

**Endpoint:**
```
POST https://prod-{region}.logic.azure.com:443/workflows/{workflow-id}/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig={signature}
```

**Authentication:** SAS token (in URL signature)

**Description:** Logic App orchestration workflow that enriches vendor data, calls D365 F&O OData endpoint, and forwards to Azure Function for queuing.

**Request Body:**
```json
{
  "VendorAccount": "V-100045",
  "Name": "Contoso Supplies GmbH",
  "Currency": "EUR",
  "CountryRegionId": "DE",
  "Address": {
    "Street": "Musterstrasse 12",
    "City": "Ulm",
    "PostalCode": "89073"
  },
  "Email": "ap@contoso-supplies.de",
  "Phone": "+49 731 555123"
}
```

**Workflow Steps:**
1. **Parse_JSON** - Validates incoming schema
2. **Enrich_Message** - Adds metadata (source, messageId, timestamp)
3. **Call_D365_OData** - POST to D365 F&O `/data/Vendors` endpoint (runs in parallel with next step)
4. **Send_to_Function_HttpIngest** - Forwards enriched message to Azure Function
5. **Response_202** - Returns 202 Accepted with message ID

**Response:**
```json
{
  "enqueued": true,
  "id": "f85f05e8-fc78-45bc-a001-a4d07bc150c5"
}
```

**Example (PowerShell):**
```powershell
$logicAppUrl = "https://prod-westeurope.logic.azure.com:443/workflows/{id}/triggers/manual/paths/invoke?..."

$payload = @{
    VendorAccount = "V-100045"
    Name = "Contoso Supplies GmbH"
    Currency = "EUR"
    CountryRegionId = "DE"
} | ConvertTo-Json

Invoke-RestMethod -Uri $logicAppUrl -Method Post -Body $payload -ContentType "application/json"
```

---

## 3. Azure Function Endpoints

### 3.1 HttpIngest Function

**Endpoint:**
```
POST https://{function-app}.azurewebsites.net/api/HttpIngest?code={function_key}
```

**Authentication:** Function key (in query string or x-functions-key header)

**Trigger Type:** HTTP POST

**Description:** Receives vendor data, validates required fields, enriches message if needed, and queues to Service Bus for async processing.

**Request Body:**
```json
{
  "type": "vendor",
  "version": "1.0",
  "data": {
    "VendorAccount": "V-100045",
    "Name": "Contoso Supplies GmbH",
    "Currency": "EUR",
    "CountryRegionId": "DE",
    "Address": {
      "Street": "Musterstrasse 12",
      "City": "Ulm",
      "PostalCode": "89073"
    },
    "Email": "ap@contoso-supplies.de",
    "Phone": "+49 731 555123"
  },
  "meta": {
    "source": "logicapp",
    "receivedAtUtc": "2025-10-29T10:30:00.000Z",
    "messageId": "f85f05e8-fc78-45bc-a001-a4d07bc150c5"
  }
}
```

**Alternative Format** (direct call without Logic App):
```json
{
  "VendorAccount": "V-100045",
  "Name": "Contoso Supplies GmbH",
  "Currency": "EUR",
  "CountryRegionId": "DE"
}
```
*Function will auto-enrich with metadata if `meta` field is missing*

**Validation Logic:**
1. Parse JSON (handles both string and object input)
2. Check for `data` field (Logic App format) or use root fields
3. Validate required fields: `VendorAccount`, `Name`, `Currency`, `CountryRegionId`
4. If missing metadata, enrich with `type`, `version`, and `meta` fields
5. Serialize to JSON and send to Service Bus queue `inbound`

**Response (Success):**
```json
{
  "enqueued": true,
  "id": "f85f05e8-fc78-45bc-a001-a4d07bc150c5"
}
```
- **Status:** 202 Accepted

**Response (Validation Error):**
```json
{
  "error": "Invalid payload",
  "missing": ["VendorAccount", "Name"]
}
```
- **Status:** 400 Bad Request

**Output Bindings:**
- **Service Bus Queue:** `inbound` (JSON message)
- **HTTP Response:** 202 or 400

**Example (PowerShell):**
```powershell
$functionUrl = "https://{your-function-app}.azurewebsites.net/api/HttpIngest?code={function_key}"

$payload = @{
    VendorAccount = "V-100045"
    Name = "Contoso Supplies GmbH"
    Currency = "EUR"
    CountryRegionId = "DE"
} | ConvertTo-Json

Invoke-RestMethod -Uri $functionUrl -Method Post -Body $payload -ContentType "application/json"
```

---

## 4. Service Bus Triggered Functions

### 4.1 SbProcessor Function

**Trigger Type:** Service Bus Queue Trigger

**Queue:** `inbound`

**Authentication:** Managed Identity (RBAC: Service Bus Data Receiver)

**Description:** Automatically triggered when a message arrives in the Service Bus queue. Processes the message, transforms data, and uploads JSON file to ADLS Gen2.

**Input Message Format:**
```json
{
  "type": "vendor",
  "version": "1.0",
  "data": {
    "VendorAccount": "V-100045",
    "Name": "Contoso Supplies GmbH",
    "Currency": "EUR",
    "CountryRegionId": "DE",
    "Address": {
      "Street": "Musterstrasse 12",
      "City": "Ulm",
      "PostalCode": "89073"
    },
    "Email": "ap@contoso-supplies.de",
    "Phone": "+49 731 555123"
  },
  "meta": {
    "source": "logicapp",
    "receivedAtUtc": "2025-10-29T10:30:00.000Z",
    "messageId": "f85f05e8-fc78-45bc-a001-a4d07bc150c5"
  }
}
```

**Processing Logic:**
1. **Parse Message** - Deserialize JSON from Service Bus
2. **Read Configuration** - Get storage account name and container from env vars
3. **Get Connection String** - Try `DEMO_STORAGE_CONNECTION` or fallback to `AzureWebJobsStorage`
4. **Build Blob Path** - `vendors/{yyyy}/{MM}/{dd}/{VendorAccount}-{ticks}.json`
5. **Serialize Content** - Convert message to JSON with UTF-8 encoding
6. **Upload to ADLS Gen2** - Use REST API with Shared Key authentication
7. **Log Success** - Write traces to Application Insights

**Output:**
- **Blob Storage:** ADLS Gen2 container `landing`
- **Path Pattern:** `vendors/2025/10/29/V-100045-638666430123456789.json`
- **Content:** Full enriched message as JSON

**Error Handling:**
- **Parse Errors:** Message moved to dead letter queue
- **Storage Errors:** Logged to Application Insights, message retried (max 10 attempts)
- **Max Retries:** Message moved to dead letter queue after 10 failed delivery attempts

**Environment Variables:**
- `DEMO_STORAGE_ACCOUNT` - Target storage account name
- `DEMO_STORAGE_CONTAINER` - Target container (default: `landing`)
- `DEMO_STORAGE_CONNECTION` - Storage connection string (optional, fallback to `AzureWebJobsStorage`)
- `AzureWebJobsServiceBus__fullyQualifiedNamespace` - Service Bus namespace for MI auth

**Example Output File:**
```
Storage Account: demostdnfittwqa7bkom
Container: landing
Path: vendors/2025/10/29/V-100045-638666430123456789.json
Content: {full enriched message as JSON}
```

---

## 5. Mock D365 Endpoints

### 5.1 Mock D365 Vendors OData API

**Endpoint:**
```
GET/POST https://{function-app}.azurewebsites.net/api/data/Vendors
```

**Authentication:** Anonymous (for testing)

**Description:** Mock D365 Finance & Operations OData endpoint for testing when real D365 sandbox is not available.

---

#### 5.1.1 Create Vendor (POST)

**Method:** POST

**Request Body:**
```json
{
  "VendorAccount": "V-100045",
  "Name": "Contoso Supplies GmbH",
  "Currency": "EUR",
  "CountryRegionId": "DE",
  "Address": {
    "Street": "Musterstrasse 12",
    "City": "Ulm",
    "PostalCode": "89073"
  },
  "Email": "ap@contoso-supplies.de",
  "Phone": "+49 731 555123"
}
```

**Response:**
```json
{
  "@odata.context": "https://mock-d365.operations.dynamics.com/data/$metadata#Vendors/$entity",
  "VendorAccount": "V-100045",
  "Name": "Contoso Supplies GmbH",
  "Currency": "EUR",
  "CountryRegionId": "DE",
  "Address": {
    "Street": "Musterstrasse 12",
    "City": "Ulm",
    "PostalCode": "89073"
  },
  "Email": "ap@contoso-supplies.de",
  "Phone": "+49 731 555123",
  "VendorGroupId": "DEFAULT",
  "PaymentTerms": "Net30",
  "DefaultDimensionDisplayValue": "",
  "RecId": 1234567,
  "CreatedDateTime": "2025-10-29T10:30:00.000Z"
}
```

**Status:** 201 Created

**Headers:**
```
Content-Type: application/json; odata.metadata=minimal
OData-Version: 4.0
```

---

#### 5.1.2 List Vendors (GET)

**Method:** GET

**Response:**
```json
{
  "@odata.context": "https://mock-d365.operations.dynamics.com/data/$metadata#Vendors",
  "value": [
    {
      "VendorAccount": "V-100001",
      "Name": "Contoso Ltd",
      "Currency": "USD",
      "CountryRegionId": "US",
      "VendorGroupId": "DEFAULT",
      "RecId": 1000001
    },
    {
      "VendorAccount": "V-100002",
      "Name": "Fabrikam Inc",
      "Currency": "EUR",
      "CountryRegionId": "DE",
      "VendorGroupId": "DEFAULT",
      "RecId": 1000002
    },
    {
      "VendorAccount": "V-100003",
      "Name": "Northwind Traders",
      "Currency": "GBP",
      "CountryRegionId": "GB",
      "VendorGroupId": "DEFAULT",
      "RecId": 1000003
    }
  ]
}
```

**Status:** 200 OK

---

## API Flow Summary

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │ 1. POST /vendor-ingest/vendors (JWT + Subscription Key)
       ▼
┌─────────────────────────┐
│  APIM (Public Gateway)  │
│  - Validate JWT         │
│  - Rate Limit (60/min)  │
│  - Add Function Key     │
└──────┬──────────────────┘
       │ 2. Forward to Logic App
       ▼
┌─────────────────────────┐
│   Logic App Workflow    │
│  - Parse & Validate     │
│  - Enrich Metadata      │
│  - Call D365 (optional) │
└──────┬──────────────────┘
       │ 3. POST /api/HttpIngest
       ▼
┌─────────────────────────┐
│  Function: HttpIngest   │
│  - Validate Fields      │
│  - Queue to Service Bus │
└──────┬──────────────────┘
       │ 4. Message queued
       ▼
┌─────────────────────────┐
│   Service Bus Queue     │
│   Queue: inbound        │
└──────┬──────────────────┘
       │ 5. Trigger Function
       ▼
┌─────────────────────────┐
│  Function: SbProcessor  │
│  - Parse Message        │
│  - Transform Data       │
│  - Upload to ADLS Gen2  │
└──────┬──────────────────┘
       │ 6. Store JSON file
       ▼
┌─────────────────────────┐
│      ADLS Gen2          │
│  vendors/yyyy/MM/dd/    │
│  {vendor}-{ticks}.json  │
└─────────────────────────┘
```

---

## Testing the APIs

### Test Scripts Available

1. **test-apim-jwt.ps1** - Test APIM endpoint with JWT authentication
2. **test-logic-app.ps1** - Test Logic App direct endpoint
3. **test-function-direct.ps1** - Test HttpIngest function directly
4. **test-e2e-final.ps1** - Complete end-to-end test
5. **test-mock-d365.ps1** - Test mock D365 OData endpoint

### Quick Test Example

```powershell
# Test APIM endpoint (production)
.\test-e2e-final.ps1

# Test Logic App directly
.\test-logic-app.ps1

# Test Function directly
.\test-function-direct.ps1
```

---

## Authentication Summary

| Endpoint | Authentication Method |
|----------|----------------------|
| APIM `/vendor-ingest/vendors` | JWT Token (Bearer) + Subscription Key |
| Logic App | SAS Token (in URL) |
| Function `HttpIngest` | Function Key (query or header) |
| Function `SbProcessor` | Service Bus Trigger (MI + RBAC) |
| Mock D365 `/data/Vendors` | Anonymous (testing only) |

---

## Rate Limits

| Service | Limit | Scope |
|---------|-------|-------|
| APIM | 60 calls / 60 seconds | Per Subscription Key |
| Logic App | 5,000 runs / 5 minutes | Per workflow |
| Function HttpIngest | No limit (Consumption plan) | - |
| Service Bus | 1,000 messages/sec | Per namespace |

---

## Environment Configuration

### APIM Variables
- `{apim-gateway}` = `{your-apim-gateway}.azure-api.net`
- `{tenant}` = `{your-tenant-id}`
- `{client_id}` = `{your-client-id}`
- `{audience}` = `api://{your-audience-id}`

### Function App Variables
- `{function-app}` = `{your-function-app}.azurewebsites.net`

### Storage Variables
- Storage Account = `demostdnfittwqa7bkom` or `demoadlsnfittwqa7bkom`
- Container = `landing`
- Folder Pattern = `vendors/yyyy/MM/dd/`

---

## Support & Troubleshooting

- **Check logs:** Application Insights
- **Check queue:** Service Bus Explorer
- **Check storage:** Azure Storage Explorer
- **Diagnose issues:** `.\diagnose-app.ps1`
