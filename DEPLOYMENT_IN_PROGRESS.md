# 🚀 D365 Integration Demo - Deployment In Progress

## Current Status: DEPLOYING ✅

**Subscription**: 9019cfb1-cb52-4c48-a0a8-727ad3933f34  
**Resource Group**: rg-d365-demo-v2  
**User**: ILYAFEDOTOV@demoentraid123.onmicrosoft.com  
**Deployment Name**: 00-foundation-simple  
**Status**: Running

## What's Being Deployed

### Core Services
- ✅ Resource Group created
- ⏳ Log Analytics Workspace
- ⏳ Application Insights
- ⏳ Key Vault (RBAC mode)
- ⏳ Storage Account (ADLS Gen2 for data)
- ⏳ Storage Account (Function runtime)
- ⏳ Service Bus (Standard) with "inbound" queue
- ⏳ API Management (Consumption tier)
- ⏳ Function App (PowerShell, Consumption plan)

### Security Configuration
- ⏳ Managed Identity for Function App
- ⏳ RBAC: Service Bus Data Sender
- ⏳ RBAC: Service Bus Data Receiver
- ⏳ RBAC: Storage Blob Data Contributor

## Issues Fixed

1. ✅ **Storage account name length**: Shortened to fit 24-character limit
2. ✅ **APIM SKU capacity**: Added capacity: 0 for Consumption tier
3. ✅ **Function App configuration**: Using Consumption plan (Y1) instead of Flex
4. ✅ **Role assignment conflicts**: Using fresh resource group with unique GUIDs
5. ✅ **principalType**: Added to RBAC assignments to avoid conflicts

## Check Deployment Status

```powershell
az deployment group show --resource-group rg-d365-demo-v2 --name 00-foundation-simple --query "properties.provisioningState" -o tsv
```

## Next Steps (After Deployment Completes)

1. **Deploy Functions**: Package and upload PowerShell functions
2. **Create Azure AD App**: Register app for JWT validation
3. **Deploy Logic App**: Configure D365 F&O integration workflow
4. **Deploy APIM Configuration**: Add JWT policies and rate limiting
5. **Test End-to-End**: Run test scripts

## Estimated Time

**Total deployment time**: 15-20 minutes

- APIM (Consumption): ~10 minutes
- Other resources: ~5-10 minutes

## Monitor Progress

Watch the deployment logs:
```powershell
az deployment group list --resource-group rg-d365-demo-v2 --output table
```
