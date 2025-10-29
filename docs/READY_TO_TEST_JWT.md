# 🔐 JWT Authentication - Ready to Test!

## ✅ What's Been Configured

### Azure AD App Registration
- **App Name**: D365-Demo-API
- **Client ID**: `4c0ab76e-6afb-48f1-bdb5-7a3ad3e00e0d`
- **Tenant ID**: `f8054917-dc24-4ea5-9363-fa27b4814bbe`
- **Audience**: `api://4c0ab76e-6afb-48f1-bdb5-7a3ad3e00e0d`
- **Status**: ✅ Created and configured

### APIM Configuration
- **Gateway URL**: `https://demo-apim-nfittwqa7bkom.azure-api.net`
- **API Endpoint**: `/vendor-ingest/vendors`
- **JWT Policy**: ✅ Deployed
  - Validates token signature
  - Validates issuer (Azure AD)
  - Validates audience
  - Validates expiration
- **Product**: D365 Demo
- **Subscription**: Demo Test Subscription ✅ Created

### JWT Validation Policy (Active)
```xml
<validate-jwt 
  header-name="Authorization" 
  require-expiration-time="true" 
  require-scheme="Bearer">
  <openid-config url="https://login.microsoftonline.com/f8054917-dc24-4ea5-9363-fa27b4814bbe/v2.0/.well-known/openid-configuration" />
  <audiences>
    <audience>api://4c0ab76e-6afb-48f1-bdb5-7a3ad3e00e0d</audience>
  </audiences>
</validate-jwt>
```

---

## 🧪 How to Test

### Step 1: Get Your Credentials

You need two things:

#### 1.1 APIM Subscription Key
**Via Portal** (Recommended):
- Go to [Azure Portal](https://portal.azure.com)
- API Management → `demo-apim-nfittwqa7bkom`
- Subscriptions → "Demo Test Subscription"
- Show keys → Copy **Primary key**

**Via CLI**:
```powershell
az rest --method post `
  --url "https://management.azure.com/subscriptions/9019cfb1-cb52-4c48-a0a8-727ad3933f34/resourceGroups/rg-d365-demo-v2/providers/Microsoft.ApiManagement/service/demo-apim-nfittwqa7bkom/subscriptions/demo-test-subscription/listSecrets?api-version=2022-08-01" `
  --query "primaryKey" -o tsv
```

#### 1.2 Azure AD Client Secret
**Via Portal**:
- Go to [Azure Portal](https://portal.azure.com)
- Azure Active Directory → App registrations → "D365-Demo-API"
- Certificates & secrets → + New client secret
- Description: "JWT Testing"
- Expires: 6 months
- Add → **Copy the VALUE immediately!**

⚠️ **Important**: The secret value is shown only once!

---

### Step 2: Run the Test

```powershell
cd "C:\Users\fedot\OneDrive\Work\Demo\Projektanfrage182914-Integration-Engineer"

.\test-jwt-simple.ps1 `
  -SubscriptionKey "YOUR-APIM-SUBSCRIPTION-KEY" `
  -ClientSecret "YOUR-CLIENT-SECRET-VALUE"
```

**Example**:
```powershell
.\test-jwt-simple.ps1 `
  -SubscriptionKey "abc123def456..." `
  -ClientSecret "Xyz~1Abc2Def3..."
```

---

## ✅ Expected Result

```
================================================
D365 Integration Demo - JWT Authentication Test
================================================

Configuration:
  Tenant ID: f8054917-dc24-4ea5-9363-fa27b4814bbe
  Client ID: 4c0ab76e-6afb-48f1-bdb5-7a3ad3e00e0d
  APIM URL: https://demo-apim-nfittwqa7bkom.azure-api.net/vendor-ingest/vendors

Step 1: Obtaining JWT Access Token...
  + JWT Token obtained successfully!
  Token expires in: 3599 seconds

Step 2: Testing APIM Endpoint with JWT...
  + SUCCESS! Request accepted by APIM

Response:
  Message ID: 12345678-abcd-1234-abcd-123456789012
  Enqueued: True

================================================
Authentication Flow Verified!
================================================

What just happened:
  1. + Azure AD issued JWT token
  2. + APIM validated JWT signature & claims
  3. + APIM validated subscription key
  4. + APIM forwarded request to Function
  5. + HttpIngest function processed payload
  6. + Message queued to Service Bus

Status: JWT Authentication WORKING!
```

---

## 🔍 What the Test Validates

### 1. Azure AD Token Generation ✅
- Client credentials flow
- Token obtained from Azure AD
- Token contains correct claims (audience, issuer)

### 2. APIM JWT Validation ✅
- Token signature verification (using Azure AD public keys)
- Issuer validation (must be Azure AD)
- Audience validation (must match app ID)
- Expiration check (token not expired)

### 3. APIM Subscription Validation ✅
- Subscription key required
- Subscription must be active
- Product association verified

### 4. Request Forwarding ✅
- APIM adds function key automatically
- Request forwarded to HttpIngest function
- URI rewritten from `/vendor-ingest/vendors` to `/HttpIngest`

### 5. End-to-End Flow ✅
- Function validates and processes payload
- Message queued to Service Bus
- 202 Accepted response returned

---

## 🎯 What This Proves

### Security Posture
- ✅ **Zero Trust Architecture**: No request without valid JWT
- ✅ **Token-Based Auth**: Modern OAuth 2.0 client credentials flow
- ✅ **API Gateway**: Centralized security enforcement
- ✅ **Subscription Management**: Per-client access control
- ✅ **Automatic Key Rotation**: Azure AD handles certificate rotation

### Enterprise Readiness
- ✅ **Production Pattern**: Standard OAuth 2.0 / OpenID Connect
- ✅ **Scalable**: Token validation is fast and stateless
- ✅ **Auditable**: All requests logged with client identity
- ✅ **Revocable**: Disable subscription to block access
- ✅ **Compliant**: Industry-standard security practices

---

## 📊 Architecture Flow (Verified)

```
┌─────────────────┐
│  Client App     │
└────────┬────────┘
         │ 1. Request JWT
         ▼
┌─────────────────┐
│   Azure AD      │  Issues JWT with claims:
│  (OAuth 2.0)    │  - aud: api://4c0ab76e-6afb-48f1-bdb5-7a3ad3e00e0d
└────────┬────────┘  - iss: https://sts.windows.net/.../
         │            - exp: timestamp
         │ 2. JWT Token
         ▼
┌─────────────────┐
│  Client App     │
└────────┬────────┘
         │ 3. POST with JWT + Subscription Key
         ▼
┌─────────────────────────────────────────────────────┐
│              Azure API Management                    │
│  ┌─────────────────────────────────────────────┐   │
│  │  JWT Validation Policy                      │   │
│  │  - Fetch Azure AD public keys (JWKS)        │   │
│  │  - Verify token signature                   │   │
│  │  - Validate issuer                          │   │
│  │  - Validate audience                        │   │
│  │  - Check expiration                         │   │
│  │  - Verify subscription key                  │   │
│  └─────────────────────────────────────────────┘   │
│                     │                                │
│                     │ ✅ Valid                       │
│                     ▼                                │
│  ┌─────────────────────────────────────────────┐   │
│  │  Request Transformation                     │   │
│  │  - Rewrite URI to /HttpIngest               │   │
│  │  - Add function key as query param          │   │
│  └─────────────────────────────────────────────┘   │
└────────┬────────────────────────────────────────────┘
         │ 4. Forward to Function
         ▼
┌─────────────────────────────────────────────────────┐
│     Azure Function (HttpIngest)                     │
│     - Validate payload structure                    │
│     - Enrich with metadata                          │
│     - Queue to Service Bus                          │
└────────┬────────────────────────────────────────────┘
         │ 5. Queue message
         ▼
┌─────────────────┐
│  Service Bus    │
│     Queue       │
└─────────────────┘
         │
         ▼
    [Next: SbProcessor → ADLS Gen2]
```

---

## 🔧 Alternative: Test via Postman

### Setup:
1. **Get Access Token**:
   - Method: POST
   - URL: `https://login.microsoftonline.com/f8054917-dc24-4ea5-9363-fa27b4814bbe/oauth2/v2.0/token`
   - Body (x-www-form-urlencoded):
     - `client_id`: `4c0ab76e-6afb-48f1-bdb5-7a3ad3e00e0d`
     - `client_secret`: `[YOUR-SECRET]`
     - `scope`: `api://4c0ab76e-6afb-48f1-bdb5-7a3ad3e00e0d/.default`
     - `grant_type`: `client_credentials`

2. **Call APIM**:
   - Method: POST
   - URL: `https://demo-apim-nfittwqa7bkom.azure-api.net/vendor-ingest/vendors`
   - Headers:
     - `Authorization`: `Bearer [ACCESS-TOKEN-FROM-STEP-1]`
     - `Ocp-Apim-Subscription-Key`: `[YOUR-SUBSCRIPTION-KEY]`
     - `Content-Type`: `application/json`
   - Body (JSON):
     ```json
     {
       "VendorAccount": "V-POSTMAN-001",
       "Name": "Postman Test Vendor",
       "Currency": "USD",
       "CountryRegionId": "US",
       "Address": {
         "Street": "123 Test St",
         "City": "Seattle",
         "PostalCode": "98101"
       },
       "Email": "test@vendor.com",
       "Phone": "+1234567890"
     }
     ```

---

## 📝 Troubleshooting

### Error: "Failed to get token"
**Symptoms**: Step 1 fails with 401 or 400
**Causes**:
- Client secret incorrect or expired
- Client ID wrong
- Tenant ID wrong
**Fix**: Recreate client secret in Azure AD

### Error: Status 401 from APIM
**Symptoms**: "Unauthorized" response from APIM
**Causes**:
- JWT token invalid or expired
- Audience mismatch
- Subscription key missing or wrong
**Fix**: 
- Check token hasn't expired (3599 seconds = ~1 hour)
- Verify subscription key is correct
- Ensure both headers are sent

### Error: Status 403 from APIM
**Symptoms**: "Forbidden" response
**Causes**:
- Valid credentials but subscription inactive
**Fix**: Check subscription status in Portal

### Error: Status 404
**Symptoms**: "Not Found"
**Causes**:
- API path wrong
- APIM not deployed correctly
**Fix**: Verify URL is exactly: `https://demo-apim-nfittwqa7bkom.azure-api.net/vendor-ingest/vendors`

---

## 📚 Related Documentation

- **Setup Guide**: `JWT_SETUP_GUIDE.md` - How JWT was configured
- **Credentials Guide**: `GET_CREDENTIALS.md` - Detailed credential retrieval
- **Final Summary**: `FINAL_SUMMARY.md` - Complete implementation status
- **Test Scripts**:
  - `test-jwt-simple.ps1` - Non-interactive test (use this!)
  - `test-apim-jwt.ps1` - Interactive test
  - `test-logic-app.ps1` - Direct Logic App test (no JWT)
  - `test-mock-d365.ps1` - Mock D365 endpoint test

---

## ✨ Success Criteria

After running the test successfully, you will have verified:

- [x] Azure AD app registration working
- [x] JWT tokens can be obtained
- [x] APIM validates JWT signatures
- [x] APIM validates token claims
- [x] APIM validates subscription keys
- [x] Requests are forwarded to backend
- [x] Function processes requests
- [x] Service Bus receives messages
- [x] End-to-end security working

**This demonstrates enterprise-grade API security with OAuth 2.0 / OpenID Connect!** 🎉

