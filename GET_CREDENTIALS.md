# How to Get Credentials for JWT Testing

## 1. Get APIM Subscription Key

### Via Azure Portal:
1. Go to https://portal.azure.com
2. Navigate to **API Management services** → `demo-apim-nfittwqa7bkom`
3. In the left menu, click **Subscriptions**
4. Find **Demo Test Subscription**
5. Click the **...** (three dots) → **Show/hide keys**
6. Copy the **Primary key**

### Via Azure CLI:
```powershell
az rest --method post `
  --url "https://management.azure.com/subscriptions/9019cfb1-cb52-4c48-a0a8-727ad3933f34/resourceGroups/rg-d365-demo-v2/providers/Microsoft.ApiManagement/service/demo-apim-nfittwqa7bkom/subscriptions/demo-test-subscription/listSecrets?api-version=2022-08-01" `
  --query "primaryKey" -o tsv
```

**Expected format**: Long alphanumeric string (e.g., `abc123def456...`)

---

## 2. Create Azure AD Client Secret

### Via Azure Portal:
1. Go to https://portal.azure.com
2. Navigate to **Azure Active Directory** → **App registrations**
3. Find and click **D365-Demo-API**
4. In the left menu, click **Certificates & secrets**
5. Click **+ New client secret**
6. Configure:
   - **Description**: `JWT Testing`
   - **Expires**: 6 months (or as needed)
7. Click **Add**
8. **IMPORTANT**: Copy the **Value** immediately (not the Secret ID)
   - This is shown only once and cannot be retrieved later
   - Store it securely

### Expected format:
```
Value: abc~1Def2Ghi3Jkl4Mno5Pqr6Stu7Vwx8Yz9
```

**Note**: If the secret is already created and you don't have the value saved:
1. Delete the old secret
2. Create a new one
3. Copy the value immediately

---

## 3. Run the JWT Test

Once you have both credentials:

```powershell
.\test-jwt-simple.ps1 `
  -SubscriptionKey "YOUR-APIM-SUBSCRIPTION-KEY" `
  -ClientSecret "YOUR-CLIENT-SECRET-VALUE"
```

### Example:
```powershell
.\test-jwt-simple.ps1 `
  -SubscriptionKey "abc123def456ghi789..." `
  -ClientSecret "Xyz~1Abc2Def3..."
```

---

## Expected Output

If successful, you should see:

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
  Request Details:
    URL: https://demo-apim-nfittwqa7bkom.azure-api.net/vendor-ingest/vendors
    Method: POST
    Headers:
      - Authorization: Bearer [token]
      - Ocp-Apim-Subscription-Key: [key]
      - Content-Type: application/json
    Payload: Vendor V-JWT-TEST-1234

  + SUCCESS! Request accepted by APIM

Response:
  Message ID: abc-123-def-456
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

## Troubleshooting

### Error: "Failed to get token"
- **Cause**: Client secret invalid or expired
- **Fix**: Create a new client secret in Azure AD

### Error: Status Code 401
- **Cause**: JWT validation failed or subscription key invalid
- **Check**:
  - Token audience matches: `api://4c0ab76e-6afb-48f1-bdb5-7a3ad3e00e0d`
  - Subscription key is correct
  - Token hasn't expired

### Error: Status Code 403
- **Cause**: Valid credentials but no permissions
- **Fix**: Check subscription is active in APIM

### Error: Status Code 404
- **Cause**: API endpoint not found
- **Fix**: Verify APIM API deployment

---

## Quick Credential Check

### Validate Subscription Key:
```powershell
$key = "YOUR-KEY"
Write-Host "Subscription Key: ${key.Substring(0,10)}..." -ForegroundColor Green
```

### Validate Client Secret Format:
```powershell
$secret = "YOUR-SECRET"
if ($secret.Length -gt 20) {
    Write-Host "Client Secret: ${secret.Substring(0,5)}... (length: $($secret.Length))" -ForegroundColor Green
} else {
    Write-Host "Client Secret seems too short!" -ForegroundColor Red
}
```

---

## Security Notes

- **Never commit secrets to version control**
- **Use Azure Key Vault for production**
- **Rotate secrets regularly**
- **Client secrets expire** - set calendar reminders
- **Store subscription keys securely**

---

## Next Steps After Successful Test

1. ✅ JWT Authentication verified
2. ✅ APIM gateway working
3. ✅ End-to-end flow confirmed
4. → Document the test results
5. → Set up monitoring alerts
6. → Plan for production deployment

