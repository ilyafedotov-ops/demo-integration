# Azure D365 Integration Demo

A production-ready demo showcasing Dynamics 365 Finance integration patterns using Azure API Management (JWT validation, rate limiting), Logic Apps for orchestration, Azure Functions (PowerShell) for event processing, Service Bus messaging, and ADLS Gen2 for data landing - all deployed via Bicep Infrastructure-as-Code.

## Architecture Overview

```
[Client] ──(OAuth2/JWT)──> [APIM]
   |  validate-jwt + rate-limit-by-key, KV-backed secrets
   v
[Logic App (Consumption)]
   |-- HTTP action to D365 F&O OData or Fin&Ops Connector
   |-- On success -> send to Service Bus (queue)
   v
[Service Bus Queue]  --->  [Azure Function (PowerShell)]
                                |-- transform + land to ADLS Gen2
                                |-- (or push into Fabric via Dataverse Link)
                                v
                          [ADLS Gen2] / [Fabric OneLake]
```

### Key Components

- **Azure API Management (Consumption)**: JWT validation, rate limiting, API governance
- **Logic Apps (Consumption)**: Orchestration with D365 F&O integration
- **Azure Functions (PowerShell)**: Event-driven processing with Service Bus triggers
- **Service Bus (Standard)**: Reliable messaging with dead letter queues
- **ADLS Gen2**: Data lake for landing transformed vendor data
- **Application Insights**: Observability and monitoring
- **Key Vault**: Secure secret management (RBAC mode)
- **Managed Identity**: Secure authentication throughout

## Prerequisites

1. **Azure CLI** installed and logged in (`az login`)
2. **Azure subscription** with appropriate permissions
3. **Azure AD App Registration** (see setup guide below)
4. **D365 F&O sandbox** (optional, mock endpoint provided)

## Quick Deploy

### Automated Setup (Recommended)

Use the pre-configured setup script with your Azure credentials:

#### Bash (macOS/Linux/WSL)
```bash
bash scripts/quick-setup.sh
```

#### PowerShell (Windows)
```powershell
.\scripts\quick-setup.ps1
```

This script will:
1. Create Azure AD app registration
2. Deploy all infrastructure
3. Configure APIM with JWT validation
4. Provide test credentials

### Manual Setup

If you prefer manual setup, follow these steps:

#### 1. Azure AD App Registration Setup

Create an Azure AD app registration for API authentication:

```bash
# Create app registration
az ad app create --display-name "D365 Demo API" --sign-in-audience AzureADMyOrg

# Get the app ID
APP_ID=$(az ad app list --display-name "D365 Demo API" --query "[0].appId" -o tsv)

# Create service principal
az ad sp create --id $APP_ID

# Expose API scope
az ad app update --id $APP_ID --set api.oauth2PermissionScopes[0]='{
  "adminConsentDescription": "Allow the application to access D365 Demo API",
  "adminConsentDisplayName": "Access D365 Demo API",
  "id": "'$(uuidgen)'",
  "isEnabled": true,
  "type": "User",
  "userConsentDescription": "Allow the application to access D365 Demo API on your behalf",
  "userConsentDisplayName": "Access D365 Demo API",
  "value": "access_as_user"
}'

# Create client secret
az ad app credential reset --id $APP_ID --append

# Get tenant ID
TENANT_ID="DE353337165"  # Pre-configured for demo
```

#### 2. Deploy Infrastructure

Edit the variables in `scripts/deploy-one-liner.sh`:

```bash
# Update these values in the script
TENANT_ID="DE353337165"
APP_ID="your-app-client-id"
D365_HOST="your-d365-host-url"  # Optional, leave empty for mock
D365_TOKEN="your-d365-access-token"  # Optional, leave empty for mock
```

Then run:

```bash
az login
az account set -s 9019cfb1-cb52-4c48-a0a8-727ad3933f34
bash scripts/deploy-one-liner.sh
```

#### PowerShell (Windows)

Edit the variables in `scripts/deploy-one-liner.ps1`:

```powershell
# Update these values in the script
$TENANT='DE353337165'
$APP='your-app-client-id'
$D365_HOST='your-d365-host-url'  # Optional, leave empty for mock
$D365_TOKEN='your-d365-access-token'  # Optional, leave empty for mock
```

Then run:

```powershell
az login
az account set -s 9019cfb1-cb52-4c48-a0a8-727ad3933f34
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-one-liner.ps1
```

## Testing the Demo

### 1. Logic App Direct Call

1. Navigate to the Logic App in Azure Portal
2. Open the workflow and click "Run trigger"
3. Use this sample vendor payload:

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

4. Expect `202` response with `{ "enqueued": true, "id": "..." }`

### 2. APIM Route (JWT Authentication)

1. Get APIM gateway URL:
```bash
az apim show -n <APIM_NAME> -g rg-d365-demo --query "gatewayRegionalUrl" -o tsv
```

2. Obtain a JWT token for your app registration audience `api://<APP_ID>`

3. Call the API:
```bash
curl -X POST "https://<apim-gateway>.azure-api.net/vendor-ingest/vendors" \
  -H "Authorization: Bearer <your-jwt-token>" \
  -H "Content-Type: application/json" \
  -d '{
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
  }'
```

### 3. Verify Data Flow

1. **Service Bus**: Check queue `inbound` for message activity
2. **Storage (ADLS Gen2)**: Navigate to container `landing/vendors/yyyy/MM/dd/` to see JSON blobs
3. **Application Insights**: View traces and requests from Function executions

## D365 Finance Integration

### Real D365 F&O Connection

To connect to a real D365 F&O sandbox:

1. **Obtain Access Token**:
```bash
# Using client credentials flow
curl -X POST "https://login.microsoftonline.com/<TENANT_ID>/oauth2/v2.0/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=<APP_ID>&client_secret=<CLIENT_SECRET>&scope=https://<D365_HOST>/.default&grant_type=client_credentials"
```

2. **Update Logic App Parameters**:
   - Set `d365HostUrl` to your D365 F&O URL
   - Set `d365AccessToken` to the obtained access token

3. **Entity Endpoint**: The Logic App calls `https://<D365_HOST>/data/Vendors`

### Mock Integration

If no D365 sandbox is available, the Logic App uses mock endpoints:
- Mock URL: `https://mock-d365-endpoint.com/data/Vendors`
- Mock token: `Bearer mock-token`

## Customization Options

### APIM Policies
- Modify JWT validation in `infra/20-apim.bicep`
- Adjust rate limiting parameters
- Add additional policies (caching, transformation, etc.)

### Function Logic
- Extend `functions/SbProcessor/run.ps1` for data transformation
- Add error handling and retry logic
- Implement data validation rules

### Logic App Workflow
- Add more D365 entities (Customers, Products, etc.)
- Implement error handling and compensation logic
- Add approval workflows for sensitive data

### Networking
- Upgrade to APIM v2 Standard/Premium for VNet integration
- Implement private endpoints for secure connectivity
- Add Azure Front Door for global distribution

## Observability

### Application Insights
- Function execution traces
- Logic App run history
- APIM request/response logs
- Custom telemetry and metrics

### Monitoring Alerts
- Service Bus queue depth
- Function execution failures
- APIM throttling events
- Storage account access patterns

## Testing

### Automated Testing

Run comprehensive smoke tests to verify the deployment:

#### Bash
```bash
# Update the script with your credentials
bash scripts/test-demo.sh
```

#### PowerShell
```powershell
# Update the script with your credentials
.\scripts\test-demo.ps1 -TenantId "your-tenant-id" -ClientId "your-client-id" -ClientSecret "your-client-secret"
```

The test script will:
1. Test Logic App direct endpoint
2. Test Function direct endpoint  
3. Test APIM endpoint with JWT authentication
4. Check Service Bus queue status
5. Verify ADLS Gen2 data landing

### Monitoring Setup

Configure alerts and monitoring:

```powershell
# Alerts will be sent to admin@demoentraid123.onmicrosoft.com
.\scripts\setup-monitoring.ps1
```

This creates alerts for:
- Function App errors (>5 exceptions)
- Logic App failures (>3 failed runs)
- APIM high response time (>5 seconds)
- Service Bus queue depth (>100 messages)

## CI/CD Pipeline

The project includes a GitHub Actions workflow (`.github/workflows/deploy.yml`) for automated deployment:

1. **Triggers**: Push to main branch or pull requests
2. **Builds**: Packages Azure Functions
3. **Deploys**: Infrastructure via Bicep
4. **Tests**: Runs smoke tests
5. **Cleanup**: Removes resources on failure

### Required GitHub Secrets:
- `AZURE_CREDENTIALS`: Service principal credentials
- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID
- `AZURE_TENANT_ID`: Tenant ID for JWT validation
- `APP_REGISTRATION_CLIENT_ID`: App registration client ID
- `D365_HOST_URL`: D365 F&O URL (optional)
- `D365_ACCESS_TOKEN`: D365 access token (optional)

## Cleanup

### Quick Cleanup
```bash
bash scripts/cleanup.sh
```

### PowerShell Cleanup
```powershell
.\scripts\cleanup.ps1
```

### Manual Cleanup
```bash
az group delete -n rg-d365-demo --yes --no-wait
```

## Troubleshooting

### Common Issues

1. **Function deployment fails**: Check PowerShell module requirements
2. **APIM JWT validation fails**: Verify tenant ID and audience configuration
3. **Service Bus connection issues**: Confirm managed identity RBAC assignments
4. **Storage access denied**: Verify Storage Blob Data Contributor role assignment

### Debugging Steps

1. Check Function logs in Application Insights
2. Review Logic App run history
3. Examine APIM trace logs
4. Verify RBAC assignments in Azure Portal

## References

- [Azure API Management Policies](https://learn.microsoft.com/en-us/azure/api-management/api-management-policies)
- [Dynamics 365 Finance Connector](https://learn.microsoft.com/en-us/dynamics365/fin-ops-core/dev-itpro/data-entities/fin-ops-connector)
- [Azure Service Bus Triggers](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-service-bus-trigger)
- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
