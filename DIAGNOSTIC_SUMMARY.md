# SbProcessor Diagnostic Summary

## Current Status

**Problem**: All messages going to dead letter queue (11 messages)
**Function**: SbProcessor with enhanced logging deployed
**Last Test**: Message sent at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Configuration Verified ✅

1. **Managed Identity**: Enabled
   - Principal ID: `d0ef2b53-d2a0-4319-9be9-9a5a22d22fab`
   - Type: SystemAssigned

2. **Storage Account**: 
   - Name: `demodatanfittwqa` ✅
   - Container: `landing` (exists) ✅
   - App Setting: `DEMO_STORAGE_ACCOUNT=demodatanfittwqa` ✅

3. **RBAC Permissions**:
   - Storage Blob Data Contributor assigned to Function MI ✅
   - Assigned at: 2025-10-28T16:43:14Z

4. **Service Bus**:
   - Connection string configured ✅
   - Queue: `inbound` (Active)
   - Trigger binding: Configured correctly ✅

5. **Enhanced Logging**: Deployed
   - 6-step detailed logging
   - Error handling with full exception details
   - Token acquisition logging
   - Upload debugging

## What to Check in Azure Portal

### Step 1: View Dead Letter Messages

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to: **Service Bus Namespaces** → **demo-sb-nfittwqa7bkom** → **Queues** → **inbound**
3. Click **Service Bus Explorer** (left menu)
4. Select **Dead-letter** tab
5. Click **Peek from start**
6. Examine the first message and look for:
   - `DeadLetterReason`
   - `DeadLetterErrorDescription`
   - Message properties

**Common Dead Letter Reasons:**
- `MaxDeliveryCountExceeded` - Function failed 10 times
- `HeaderSizeExceeded` - Message too large
- `TTLExpiredException` - Message expired

### Step 2: Check Function Execution Logs

1. In Portal, go to: **Function App** → **demo-func-nfittwqa7bkom**
2. Click **Functions** → **SbProcessor**
3. Click **Monitor** tab
4. Look at recent invocations
5. Click on failed invocations to see:
   - Exception details
   - Step-by-step logs (STEP 1-6)
   - Error messages

**What to Look For:**
- Does STEP 1 complete? (Message parsing)
- Does STEP 2 complete? (Configuration loading)
- Does STEP 3 fail? (Token acquisition)
- Does STEP 6 fail? (Blob upload)

### Step 3: Check Application Insights

1. Go to: **Application Insights** → **demo-apim-nfittwqa7bkom**
2. Click **Logs** (left menu)
3. Run this query:

```kusto
traces
| where timestamp > ago(1h)
| where message contains "SbProcessor" or message contains "STEP" or message contains "ERROR"
| order by timestamp desc
| project timestamp, severityLevel, message
```

## Likely Root Causes

### 1. Managed Identity Token Failure
**Symptoms**: STEP 3 fails
**Reason**: MI endpoint not accessible or permissions delayed
**Solution**: 
```powershell
# Wait for RBAC propagation (can take up to 10 minutes)
# Or use connection string approach
```

### 2. Storage API Authentication Issue
**Symptoms**: STEP 6 fails with 401/403
**Reason**: Token audience mismatch or permission not propagated
**Solution**: Check error response in logs

### 3. PowerShell Runtime Issue
**Symptoms**: Function never logs anything
**Reason**: PowerShell module or runtime error
**Solution**: Check host.json and requirements.psd1

### 4. Message Format Issue
**Symptoms**: STEP 1 fails
**Reason**: JSON parsing error
**Solution**: Check message format in dead letter

## Next Actions

### Option A: Check Portal (Recommended)
1. Follow "Step 1" above to see dead letter reason
2. Follow "Step 2" to see function logs
3. Report findings

### Option B: Use Connection String Instead of MI

Update SbProcessor to use storage connection string:

```powershell
# Add app setting
az functionapp config appsettings set -g rg-d365-demo-v2 -n demo-func-nfittwqa7bkom --settings "AzureWebJobsStorage__accountName=demodatanfittwqa"

# Or use full connection string approach
```

### Option C: Purge Dead Letter and Test Fresh

```powershell
# Send new test message
.\test-e2e-final.ps1

# Immediately check logs in Portal (within 1 minute)
```

## Test Message Sent

A test message was sent with enhanced logging. The function should log:
- `============================================`
- `SbProcessor triggered at [timestamp]`
- `STEP 1: Parsing message...`
- `STEP 2: Reading configuration...`
- `STEP 3: Acquiring managed identity token...`
- `STEP 4: Building blob path...`
- `STEP 5: Serializing content...`
- `STEP 6: Uploading to blob storage...`

**If none of these logs appear**, the function host is failing before execution.

## Files Created

- `check-deadletter-messages.ps1` - Portal instructions
- `function-logs.zip` - Downloaded logs (may be incomplete)
- Updated `SbProcessor/run.ps1` - Enhanced logging version

## Summary

✅ All infrastructure configured correctly
✅ Enhanced logging deployed
❌ Messages going to dead letter
❓ Need to check Azure Portal logs to see exact failure point

**Next Step**: Check dead letter message details and function execution logs in Azure Portal to identify the exact error.
