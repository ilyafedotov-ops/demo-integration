# JWT Authentication Setup Guide

## Overview
This guide explains how to configure JWT authentication for the APIM API endpoint.

## Prerequisites
- Azure subscription with appropriate permissions
- Access to Azure Portal
- APIM instance deployed (`demo-apim-nfittwqa7bkom`)

## Step 1: Create Azure AD App Registration

### Via Azure Portal:
1. Navigate to **Azure Active Directory** > **App registrations**
2. Click **+ New registration**
3. Configure:
   - **Name**: `D365-Demo-API`
   - **Supported account types**: Accounts in this organizational directory only
   - **Redirect URI**: Leave empty
4. Click **Register**

### Record Important Values:
After creation, note:
- **Application (client) ID**: e.g., `12345678-1234-1234-1234-123456789abc`
- **Directory (tenant) ID**: `f8054917-dc24-4ea5-9363-fa27b4814bbe`

## Step 2: Expose an API

1. In your app registration, go to **Expose an API**
2. Click **+ Add a scope**
3. Accept the default Application ID URI or customize: `api://{client-id}`
4. Configure the scope:
   - **Scope name**: `access_as_user`
   - **Who can consent**: Admins and users
   - **Admin consent display name**: Access D365 Demo API
   - **Admin consent description**: Allow the application to access D365 Demo API
   - **User consent display name**: Access D365 Demo API  
   - **User consent description**: Allow the application to access D365 Demo API on your behalf
   - **State**: Enabled
5. Click **Add scope**

## Step 3: Configure APIM JWT Validation

### Get OpenID Configuration URL:
```
https://login.microsoftonline.com/{tenant-id}/v2.0/.well-known/openid-configuration
```
Replace `{tenant-id}` with: `f8054917-dc24-4ea5-9363-fa27b4814bbe`

### Deploy APIM Configuration:

Run this command with your App Registration details:

```powershell
$tenantId = "f8054917-dc24-4ea5-9363-fa27b4814bbe"
$clientId = "YOUR-APP-CLIENT-ID"  # From Step 1
$audience = "api://$clientId"
$openIdUrl = "https://login.microsoftonline.com/$tenantId/v2.0/.well-known/openid-configuration"

az deployment group create `
  --resource-group rg-d365-demo-v2 `
  --name apim-jwt-config `
  --template-file infra/20-apim.bicep `
  --parameters `
    apimName=demo-apim-nfittwqa7bkom `
    functionHostname=demo-func-nfittwqa7bkom.azurewebsites.net `
    functionKey=YOUR_FUNCTION_KEY_HERE `
    openIdConfigUrl=$openIdUrl `
    audience=$audience
```

## Step 4: Test JWT Authentication

### Get Access Token:

#### Using PowerShell (for testing):
```powershell
# You'll need client credentials flow for service-to-service
# First, create a client secret in your app registration:
# Azure AD > App registrations > Your app > Certificates & secrets > + New client secret

$tenantId = "f8054917-dc24-4ea5-9363-fa27b4814bbe"
$clientId = "YOUR-APP-CLIENT-ID"
$clientSecret = "YOUR-CLIENT-SECRET"
$scope = "api://$clientId/.default"

$body = @{
    client_id     = $clientId
    client_secret = $clientSecret
    scope         = $scope
    grant_type    = "client_credentials"
}

$tokenResponse = Invoke-RestMethod -Method Post `
    -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
    -Body $body `
    -ContentType "application/x-www-form-urlencoded"

$accessToken = $tokenResponse.access_token
Write-Host "Access Token: $accessToken"
```

### Test APIM Endpoint:

```powershell
$apimUrl = "https://demo-apim-nfittwqa7bkom.azure-api.net/vendor-ingest/vendors"

$vendorData = @{
    VendorAccount = "V-100050"
    Name = "Test Vendor via APIM"
    Currency = "USD"
    CountryRegionId = "US"
    Address = @{
        Street = "456 Test Blvd"
        City = "Seattle"
        PostalCode = "98101"
    }
    Email = "test@vendor.com"
    Phone = "+1234567890"
} | ConvertTo-Json

$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type" = "application/json"
    "Ocp-Apim-Subscription-Key" = "YOUR-SUBSCRIPTION-KEY"  # Get from APIM portal
}

$response = Invoke-RestMethod -Method Post -Uri $apimUrl -Headers $headers -Body $vendorData
Write-Host "Response: $($response | ConvertTo-Json)"
```

## Step 5: Get APIM Subscription Key

1. Navigate to **API Management** > `demo-apim-nfittwqa7bkom`
2. Go to **Subscriptions**
3. Find the subscription for "D365 Demo" product
4. Click "..." > **Show/hide keys**
5. Copy the **Primary key** or **Secondary key**

## Testing Without JWT (Development Only)

For testing purposes, you can temporarily disable JWT validation:

1. Go to APIM in Azure Portal
2. Navigate to **APIs** > **Vendor Ingest API**
3. Click on **All operations**
4. In **Inbound processing**, click **Code view** (`</>`)
5. Comment out the `<validate-jwt>` section:
```xml
<!--
<validate-jwt header-name="Authorization" ...>
  ...
</validate-jwt>
-->
```
6. Save

**Warning**: Only for development! Re-enable for production.

## Troubleshooting

### Common Issues:

#### 1. "401 Unauthorized"
- Verify token audience matches configured audience
- Check token expiration
- Ensure token is in format: `Bearer {token}`

#### 2. "Token signature validation failed"
- Verify OpenID config URL is correct
- Check tenant ID matches

#### 3. "Subscription key not found"
- Ensure `Ocp-Apim-Subscription-Key` header is included
- Verify subscription key is valid

### Verify Token:
Decode your JWT at [jwt.ms](https://jwt.ms) to verify:
- **aud** (audience) matches `api://{client-id}`
- **iss** (issuer) is `https://login.microsoftonline.com/{tenant-id}/v2.0`
- **exp** (expiration) is in the future

## Architecture Flow with JWT

```
Client
  └─> Get JWT Token from Azure AD
  └─> POST https://demo-apim-nfittwqa7bkom.azure-api.net/vendor-ingest/vendors
      Headers:
        - Authorization: Bearer {jwt-token}
        - Ocp-Apim-Subscription-Key: {subscription-key}
        - Content-Type: application/json
      Body: { vendor data }
      
APIM
  └─> Validate JWT (issuer, audience, signature, expiration)
  └─> Check rate limit
  └─> Forward to Function App (HttpIngest)
  
Function App
  └─> Validate & enrich payload
  └─> Queue to Service Bus
  └─> Return 202 Accepted

Service Bus
  └─> Trigger SbProcessor Function
  
SbProcessor Function
  └─> Process message
  └─> Land data in ADLS Gen2 (vendors/yyyy/MM/dd/)
```

## Next Steps

1. Create client secret for your app registration
2. Deploy APIM with JWT configuration
3. Test with generated access token
4. Implement token caching in client applications
5. Set up token refresh logic

## Resources

- [Azure AD App Registration](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
- [APIM JWT Validation](https://learn.microsoft.com/en-us/azure/api-management/api-management-access-restriction-policies#ValidateJWT)
- [OAuth 2.0 Client Credentials Flow](https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-client-creds-grant-flow)
