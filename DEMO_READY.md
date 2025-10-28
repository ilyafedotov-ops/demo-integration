# D365 Integration Demo - Ready to Deploy

## 🎯 Your Demo Configuration

**Azure Subscription**: `9019cfb1-cb52-4c48-a0a8-727ad3933f34`  
**Azure Tenant**: `DE353337165` (demoentraid123.onmicrosoft.com)  
**Resource Group**: `rg-d365-demo`  
**Location**: `westeurope`

## 🚀 One-Command Deployment

### Option 1: Automated Setup (Recommended)
```bash
bash scripts/quick-setup.sh
```

### Option 2: PowerShell Setup
```powershell
.\scripts\quick-setup.ps1
```

## 📋 What Gets Deployed

### Core Infrastructure
- **Azure API Management** (Consumption tier) with JWT validation
- **Logic Apps** (Consumption) with D365 F&O integration
- **Azure Functions** (PowerShell) on Flex Consumption
- **Service Bus** (Standard) with inbound queue
- **ADLS Gen2** storage for data landing
- **Application Insights** for monitoring
- **Key Vault** (RBAC mode) for secrets

### Security & Access
- **Azure AD App Registration** with API scope
- **Managed Identity** throughout all services
- **RBAC** assignments for Service Bus and Storage
- **JWT validation** with rate limiting

## 🔄 Data Flow

```
[Client] ──(JWT)──> [APIM] ──> [Logic App] ──> [D365 F&O] ──> [Service Bus] ──> [Function] ──> [ADLS Gen2]
```

## 🧪 Testing

After deployment, test with:

```bash
# Run comprehensive tests
bash scripts/test-demo.sh
```

Or PowerShell:
```powershell
.\scripts\test-demo.ps1 -TenantId "DE353337165" -ClientId "<APP_ID>" -ClientSecret "<CLIENT_SECRET>"
```

## 📊 Sample Test Data

Use this vendor payload for testing:

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

## 🔍 Monitoring

Set up alerts:
```powershell
.\scripts\setup-monitoring.ps1
```

## 🧹 Cleanup

When done with the demo:
```bash
bash scripts/cleanup.sh
```

## 📚 Documentation

Complete documentation available in `README.md` including:
- Architecture overview
- Step-by-step setup guide
- Testing procedures
- Troubleshooting guide
- CI/CD pipeline setup

## 🎯 Demo Highlights

This demo showcases:
- ✅ **Enterprise Security**: JWT validation, managed identity, RBAC
- ✅ **D365 Integration**: Real OData calls with mock fallback
- ✅ **Event-Driven Architecture**: Service Bus messaging
- ✅ **Infrastructure-as-Code**: Complete Bicep deployment
- ✅ **Observability**: Application Insights and monitoring
- ✅ **CI/CD Ready**: GitHub Actions pipeline included

Perfect for demonstrating Azure and Dynamics 365 Finance integration capabilities!
