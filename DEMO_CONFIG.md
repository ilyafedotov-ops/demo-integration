# Demo Configuration Summary

## 🎯 Demo Environment Details

**Azure Subscription**: `9019cfb1-cb52-4c48-a0a8-727ad3933f34`  
**Azure Tenant**: `DE353337165` (demoentraid123.onmicrosoft.com)  
**Admin Email**: `admin@demoentraid123.onmicrosoft.com`  
**Resource Group**: `rg-d365-demo`  
**Location**: `westeurope`

## 🚀 Quick Start Commands

### 1. Automated Setup
```bash
bash scripts/quick-setup.sh
```

### 2. Test Deployment
```bash
bash scripts/test-demo.sh
```

### 3. Setup Monitoring
```powershell
.\scripts\setup-monitoring.ps1
```

### 4. Cleanup When Done
```bash
bash scripts/cleanup.sh
```

## 📧 Alert Configuration

All monitoring alerts will be sent to: **admin@demoentraid123.onmicrosoft.com**

Alert types configured:
- Function App errors (>5 exceptions)
- Logic App failures (>3 failed runs)  
- APIM high response time (>5 seconds)
- Service Bus queue depth (>100 messages)

## 🔑 Credentials Generated

The setup script will generate:
- **App Registration Client ID**
- **Client Secret** 
- **JWT Audience**: `api://<CLIENT_ID>`

## 📊 Test Data

Use the sample vendor payload in `sample-vendor-payload.json` for testing all endpoints.

## 🎯 Demo Flow

1. **APIM** validates JWT and rate limits
2. **Logic App** orchestrates D365 F&O call
3. **Service Bus** queues the message
4. **Function** processes and stores in ADLS Gen2
5. **Monitoring** tracks all operations

Perfect for demonstrating enterprise integration patterns!
