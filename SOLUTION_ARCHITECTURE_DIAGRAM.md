# D365 Integration Solution - Architecture Diagrams

This document contains comprehensive Mermaid diagrams illustrating the complete architecture, workflows, and data flows of the D365 Integration Demo solution.

---

## 1. High-Level Architecture Overview

```mermaid
graph TB
    subgraph "External"
        Client[Client Application]
        D365[D365 Finance & Operations<br/>OData API]
    end
    
    subgraph "Azure Active Directory"
        AAD[Azure AD<br/>Tenant: demoentraid123]
        AppReg[App Registration<br/>JWT Token Provider]
    end
    
    subgraph "Azure Resource Group: rg-d365-demo"
        subgraph "API Layer"
            APIM[API Management<br/>Consumption Tier<br/>JWT Validation + Rate Limiting]
        end
        
        subgraph "Orchestration Layer"
            LogicApp[Logic App<br/>Consumption<br/>Vendor Ingest Workflow]
        end
        
        subgraph "Processing Layer"
            FuncHttp[Azure Function<br/>HttpIngest<br/>HTTP Trigger]
            FuncSB[Azure Function<br/>SbProcessor<br/>Service Bus Trigger]
        end
        
        subgraph "Messaging Layer"
            SB[Service Bus<br/>Standard Tier<br/>Queue: inbound]
            SBQ[Queue: inbound]
            SBDL[Dead Letter Queue]
        end
        
        subgraph "Storage Layer"
            ADLS[ADLS Gen2<br/>Container: landing<br/>Folder: vendors/yyyy/MM/dd/]
            StApp[Storage Account<br/>Function Runtime]
        end
        
        subgraph "Security & Configuration"
            KV[Key Vault<br/>RBAC Mode<br/>Secrets Management]
            MI[Managed Identity<br/>System Assigned]
        end
        
        subgraph "Observability"
            AppInsights[Application Insights<br/>Telemetry & Monitoring]
            LogAnalytics[Log Analytics<br/>Workspace]
        end
    end
    
    %% Flow connections
    Client -->|1. Acquire JWT| AAD
    AAD -->|2. JWT Token| Client
    Client -->|3. POST /vendors<br/>Bearer Token| APIM
    APIM -->|4. Validate JWT<br/>Rate Limit| LogicApp
    LogicApp -->|5a. POST Vendor Data| D365
    D365 -->|5b. Success/Fail| LogicApp
    LogicApp -->|6. Enrich & Send| FuncHttp
    FuncHttp -->|7. Queue Message| SB
    SB -->|8. Trigger| FuncSB
    FuncSB -->|9. Transform & Store| ADLS
    
    %% Security connections
    MI -.->|RBAC: Data Contributor| ADLS
    MI -.->|RBAC: Sender/Receiver| SB
    APIM -.->|Read Secrets| KV
    FuncHttp -.->|Identity| MI
    FuncSB -.->|Identity| MI
    
    %% Monitoring connections
    APIM -.->|Logs & Metrics| AppInsights
    LogicApp -.->|Run History| AppInsights
    FuncHttp -.->|Traces| AppInsights
    FuncSB -.->|Traces| AppInsights
    AppInsights -.->|Store| LogAnalytics
    
    %% Error handling
    SB -.->|Failed Messages| SBDL
    
    style Client fill:#e1f5ff
    style APIM fill:#ff9800
    style LogicApp fill:#4caf50
    style FuncHttp fill:#2196f3
    style FuncSB fill:#2196f3
    style SB fill:#9c27b0
    style ADLS fill:#00bcd4
    style AAD fill:#ff5722
    style D365 fill:#795548
    style MI fill:#ffc107
    style KV fill:#607d8b
```

---

## 2. Detailed Data Flow - End-to-End

```mermaid
sequenceDiagram
    participant Client
    participant AAD as Azure AD
    participant APIM as API Management
    participant LA as Logic App
    participant D365 as D365 F&O
    participant FuncHTTP as Function<br/>HttpIngest
    participant SB as Service Bus<br/>Queue
    participant FuncSB as Function<br/>SbProcessor
    participant ADLS as ADLS Gen2
    participant AI as App Insights
    
    Note over Client,ADLS: Authentication Phase
    Client->>AAD: 1. Request JWT Token<br/>(Client Credentials Flow)
    Note right of AAD: Tenant: demoentraid123<br/>Audience: api://{client-id}
    AAD->>Client: 2. JWT Token (access_token)
    
    Note over Client,ADLS: API Request Phase
    Client->>APIM: 3. POST /vendor-ingest/vendors<br/>Authorization: Bearer {JWT}<br/>Subscription-Key: {key}
    APIM->>APIM: 4. Validate JWT<br/>- Check signature<br/>- Check expiration<br/>- Check audience
    APIM->>APIM: 5. Rate Limit Check<br/>(60 calls/60 sec)
    
    alt JWT Valid & Rate OK
        APIM->>LA: 6. Forward Request<br/>(Add Function Key)
        
        Note over LA,D365: Logic App Orchestration
        LA->>LA: 7. Parse JSON<br/>Validate Schema
        LA->>LA: 8. Enrich Message<br/>- Add metadata<br/>- Add messageId<br/>- Add timestamp
        
        par D365 Call (Optional)
            LA->>D365: 9. POST /data/Vendors<br/>OData Request
            alt D365 Available
                D365->>LA: 10. 200 OK / 201 Created
            else D365 Mock/Unavailable
                D365->>LA: 10. Error / Timeout
            end
        end
        
        Note over LA,SB: Enqueue to Service Bus
        LA->>FuncHTTP: 11. POST /api/HttpIngest<br/>Enriched Payload
        FuncHTTP->>FuncHTTP: 12. Validate Required Fields<br/>- VendorAccount<br/>- Name<br/>- Currency<br/>- CountryRegionId
        
        alt Validation Success
            FuncHTTP->>SB: 13. Send Message<br/>(JSON Serialized)
            FuncHTTP->>LA: 14. 202 Accepted<br/>{enqueued: true, id: guid}
            LA->>Client: 15. 202 Accepted<br/>{enqueued: true, id: guid}
            
            Note over SB,ADLS: Async Processing
            SB->>FuncSB: 16. Trigger (Message Available)
            FuncSB->>FuncSB: 17. Parse Message<br/>ConvertFrom-Json
            FuncSB->>FuncSB: 18. Build Blob Path<br/>vendors/yyyy/MM/dd/<br/>{vendor}-{ticks}.json
            FuncSB->>FuncSB: 19. Serialize Content<br/>UTF-8 Encoding
            FuncSB->>ADLS: 20. PUT Blob<br/>(Shared Key Auth)
            ADLS->>FuncSB: 21. 201 Created
            
            FuncSB->>AI: 22. Log Success
            
        else Validation Failure
            FuncHTTP->>LA: 14. 400 Bad Request<br/>{error: "Invalid", missing: [...]}
            LA->>Client: 15. 400 Bad Request
        end
        
    else JWT Invalid or Rate Exceeded
        APIM->>Client: Error Response<br/>401 Unauthorized or<br/>429 Too Many Requests
    end
    
    Note over Client,ADLS: Monitoring
    APIM->>AI: Logs & Metrics
    LA->>AI: Run History
    FuncHTTP->>AI: Traces & Exceptions
    FuncSB->>AI: Traces & Exceptions
```

---

## 3. Authentication & Authorization Flow

```mermaid
graph LR
    subgraph "Client Side"
        App[Client Application]
        AppConfig[App Configuration<br/>Tenant ID<br/>Client ID<br/>Client Secret<br/>Scope]
    end
    
    subgraph "Azure Active Directory"
        TokenEndpoint[Token Endpoint<br/>https://login.microsoft<br/>online.com/{tenant}/<br/>oauth2/v2.0/token]
        AADValidation[Token Validation<br/>- Signature Check<br/>- Expiration Check<br/>- Audience Check]
    end
    
    subgraph "API Management"
        JWTPolicy[validate-jwt Policy<br/>- OpenID Config<br/>- Audience Validation<br/>- Require Bearer Scheme]
        RateLimit[rate-limit-by-key<br/>- 60 calls/60 sec<br/>- Per Subscription Key]
    end
    
    subgraph "Backend Services"
        FuncAuth[Function Authentication<br/>Function Key via Query]
        MIAuth[Managed Identity<br/>System Assigned]
    end
    
    subgraph "Azure Resources"
        SBAuth[Service Bus<br/>RBAC: Sender + Receiver]
        StorageAuth[ADLS Gen2<br/>RBAC: Blob Data Contributor<br/>OR Shared Key]
    end
    
    %% Authentication flow
    App -->|1. Get Config| AppConfig
    App -->|2. POST Client Credentials| TokenEndpoint
    TokenEndpoint -->|3. JWT Token| App
    App -->|4. Bearer Token| JWTPolicy
    JWTPolicy -->|5. Validate| AADValidation
    AADValidation -->|6. Valid| RateLimit
    RateLimit -->|7. Rate OK| FuncAuth
    FuncAuth -->|8. Authenticated| MIAuth
    
    %% Authorization flow
    MIAuth -->|RBAC Authorization| SBAuth
    MIAuth -->|RBAC Authorization| StorageAuth
    
    style TokenEndpoint fill:#ff5722
    style JWTPolicy fill:#ff9800
    style MIAuth fill:#ffc107
    style SBAuth fill:#9c27b0
    style StorageAuth fill:#00bcd4
```

---

## 4. Component-Level Architecture

```mermaid
graph TB
    subgraph "API Management Layer"
        APIMService[APIM Service<br/>Consumption Tier]
        APIMBackend[Backend: Function]
        APIMProduct[Product: D365 Demo<br/>Subscription Required]
        APIMApi[API: vendor-ingest<br/>Path: /vendor-ingest]
        APIMOp[Operation: POST /vendors]
        APIMPolicy[Policies:<br/>- validate-jwt<br/>- rate-limit-by-key<br/>- rewrite-uri<br/>- set-query-parameter]
    end
    
    subgraph "Logic App Workflow"
        LATrigger[Trigger:<br/>HTTP Request<br/>Method: POST]
        LAParseJSON[Action: Parse JSON<br/>Validate Schema]
        LAEnrich[Action: Compose<br/>Enrich Message]
        LAD365Call[Action: HTTP<br/>Call D365 OData]
        LAFuncCall[Action: HTTP<br/>Call Function HttpIngest]
        LAResponse[Action: Response<br/>202 Accepted]
    end
    
    subgraph "Function App - HttpIngest"
        FHBinding[Bindings:<br/>- HTTP Trigger<br/>- Service Bus Output]
        FHValidation[Logic:<br/>1. Parse JSON<br/>2. Validate Fields<br/>3. Enrich if needed]
        FHQueue[Output:<br/>Queue Message to SB]
        FHResponse[Response:<br/>202 Accepted]
    end
    
    subgraph "Function App - SbProcessor"
        FSBinding[Bindings:<br/>- Service Bus Trigger<br/>Queue: inbound]
        FSParse[Logic:<br/>1. Parse Message<br/>2. Build Blob Path<br/>3. Serialize Content]
        FSUpload[Output:<br/>Upload to ADLS<br/>REST API with<br/>Shared Key Auth]
        FSLog[Logging:<br/>Application Insights<br/>Detailed Traces]
    end
    
    subgraph "Service Bus"
        SBQueue[Queue: inbound<br/>Max Delivery: 10<br/>Dead Letter: Enabled]
        SBDeadLetter[Dead Letter Queue<br/>Failed Messages]
    end
    
    subgraph "Storage"
        ADLSContainer[Container: landing]
        ADLSFolder[Folder Structure:<br/>vendors/<br/>  yyyy/<br/>    MM/<br/>      dd/<br/>        {vendor}-{ticks}.json]
    end
    
    %% Connections
    APIMService --> APIMBackend
    APIMService --> APIMProduct
    APIMProduct --> APIMApi
    APIMApi --> APIMOp
    APIMOp --> APIMPolicy
    
    LATrigger --> LAParseJSON
    LAParseJSON --> LAEnrich
    LAEnrich --> LAD365Call
    LAD365Call --> LAFuncCall
    LAFuncCall --> LAResponse
    
    FHBinding --> FHValidation
    FHValidation --> FHQueue
    FHQueue --> FHResponse
    
    FSBinding --> FSParse
    FSParse --> FSUpload
    FSUpload --> FSLog
    
    SBQueue --> SBDeadLetter
    
    ADLSContainer --> ADLSFolder
    
    style APIMService fill:#ff9800
    style LATrigger fill:#4caf50
    style FHBinding fill:#2196f3
    style FSBinding fill:#2196f3
    style SBQueue fill:#9c27b0
    style ADLSContainer fill:#00bcd4
```

---

## 5. Infrastructure as Code - Bicep Modules

```mermaid
graph TB
    subgraph "Bicep Deployment"
        Main[main.bicep<br/>or deploy scripts]
    end
    
    subgraph "00-foundation.bicep"
        Foundation[Foundation Resources]
        LAW[Log Analytics<br/>Workspace]
        APPI[Application Insights]
        KV2[Key Vault<br/>RBAC Mode]
        StData[Storage: Data Lake<br/>ADLS Gen2 Enabled]
        StApp[Storage: Function Runtime]
        SB2[Service Bus Namespace<br/>+ Queue: inbound]
        APIM2[APIM Service<br/>System Managed Identity]
        Func[Function App<br/>PowerShell Runtime<br/>System Managed Identity]
        Plan[App Service Plan<br/>Consumption]
        RBAC[RBAC Assignments:<br/>- Service Bus Sender<br/>- Service Bus Receiver<br/>- Blob Data Contributor]
    end
    
    subgraph "10-logicapp.bicep"
        LA2[Logic App<br/>Consumption]
        LADef[Workflow Definition<br/>from JSON file]
        LAParams[Parameters:<br/>- functionBaseUrl<br/>- functionKey<br/>- d365HostUrl<br/>- d365AccessToken]
    end
    
    subgraph "20-apim.bicep"
        APIMConf[APIM Configuration]
        APIMNamedValues[Named Values<br/>func_key]
        APIMBackend2[Backend: Function]
        APIMApi2[API Definition<br/>vendor-ingest]
        APIMOp2[Operation:<br/>POST /vendors]
        APIMApiPolicy[API Policy:<br/>- validate-jwt<br/>- rewrite-uri<br/>- set-query-parameter]
        APIMProduct2[Product:<br/>d365-demo]
        APIMProductApi[Product-API Link]
        APIMLanding[Landing Page API<br/>Root Path /]
    end
    
    subgraph "External Files"
        FuncCode[functions/<br/>- HttpIngest/run.ps1<br/>- SbProcessor/run.ps1<br/>- host.json<br/>- requirements.psd1]
        LAJson[logicapp/<br/>logicapp.vendor.ingest<br/>.definition.json]
    end
    
    %% Deployment flow
    Main --> Foundation
    Foundation --> LAW
    Foundation --> APPI
    Foundation --> KV2
    Foundation --> StData
    Foundation --> StApp
    Foundation --> SB2
    Foundation --> APIM2
    Foundation --> Plan
    Plan --> Func
    Func --> RBAC
    
    Main --> LA2
    LA2 --> LADef
    LADef --> LAParams
    LAJson -.->|Load Content| LADef
    
    Main --> APIMConf
    APIMConf --> APIMNamedValues
    APIMConf --> APIMBackend2
    APIMConf --> APIMApi2
    APIMApi2 --> APIMOp2
    APIMOp2 --> APIMApiPolicy
    APIMConf --> APIMProduct2
    APIMProduct2 --> APIMProductApi
    APIMConf --> APIMLanding
    
    FuncCode -.->|Deploy as Package| Func
    
    style Foundation fill:#4caf50
    style LA2 fill:#8bc34a
    style APIMConf fill:#ff9800
    style FuncCode fill:#03a9f4
    style LAJson fill:#03a9f4
```

---

## 6. Error Handling & Monitoring

```mermaid
graph TB
    subgraph "Error Sources"
        E1[APIM Errors<br/>- JWT Invalid<br/>- Rate Limit<br/>- Backend Timeout]
        E2[Logic App Errors<br/>- D365 Call Failed<br/>- Function Call Failed<br/>- Schema Validation]
        E3[Function Errors<br/>- Validation Failure<br/>- Service Bus Error<br/>- Storage Error]
        E4[Service Bus Errors<br/>- Max Delivery Count<br/>- Message Expired]
    end
    
    subgraph "Error Handling"
        H1[APIM Error Response<br/>- 401 Unauthorized<br/>- 429 Too Many Requests<br/>- 500 Internal Error]
        H2[Logic App<br/>Run History<br/>Failed Status]
        H3[Function Exception<br/>Logged to App Insights<br/>HTTP 400/500 Response]
        H4[Dead Letter Queue<br/>Failed Messages Preserved]
    end
    
    subgraph "Monitoring & Alerts"
        AI2[Application Insights<br/>- Request Telemetry<br/>- Exception Tracking<br/>- Custom Events<br/>- Performance Metrics]
        LAW2[Log Analytics<br/>- Query Logs<br/>- KQL Queries<br/>- 30 Days Retention]
        Alerts[Alert Rules<br/>- Function Errors >5<br/>- Logic App Fails >3<br/>- APIM Response >5s<br/>- SB Queue Depth >100]
        Email[Email Notification<br/>admin@demoentraid123<br/>.onmicrosoft.com]
    end
    
    subgraph "Diagnostics"
        D1[APIM Trace Logs<br/>Request/Response]
        D2[Logic App Run History<br/>Step-by-Step Details]
        D3[Function Logs<br/>Console Output<br/>Write-Host Traces]
        D4[Service Bus Metrics<br/>Queue Depth<br/>Dead Letter Count]
        D5[Storage Metrics<br/>Blob Operations<br/>Access Patterns]
    end
    
    %% Error flow
    E1 --> H1
    E2 --> H2
    E3 --> H3
    E4 --> H4
    
    %% Monitoring flow
    H1 --> AI2
    H2 --> AI2
    H3 --> AI2
    H4 --> D4
    
    AI2 --> LAW2
    LAW2 --> Alerts
    Alerts --> Email
    
    %% Diagnostics
    AI2 --> D1
    AI2 --> D2
    AI2 --> D3
    D4 --> AI2
    D5 --> AI2
    
    style E1 fill:#f44336
    style E2 fill:#f44336
    style E3 fill:#f44336
    style E4 fill:#f44336
    style AI2 fill:#00bcd4
    style Alerts fill:#ff9800
    style Email fill:#4caf50
```

---

## 7. Data Model & Message Schema

```mermaid
classDiagram
    class ClientRequest {
        +string VendorAccount*
        +string Name*
        +string Currency*
        +string CountryRegionId*
        +Address Address
        +string Email
        +string Phone
    }
    
    class Address {
        +string Street
        +string City
        +string PostalCode
    }
    
    class EnrichedMessage {
        +string type = "vendor"
        +string version = "1.0"
        +VendorData data
        +Metadata meta
    }
    
    class VendorData {
        +string VendorAccount
        +string Name
        +string Currency
        +string CountryRegionId
        +Address Address
        +string Email
        +string Phone
    }
    
    class Metadata {
        +string source
        +string receivedAtUtc
        +string messageId
    }
    
    class ServiceBusMessage {
        +string ContentType = "application/json"
        +EnrichedMessage Body
        +MessageProperties Properties
    }
    
    class BlobStorageFile {
        +string Container = "landing"
        +string Path = "vendors/yyyy/MM/dd/{vendor}-{ticks}.json"
        +EnrichedMessage Content
        +string ContentType = "application/json"
    }
    
    class D365Request {
        +string VendorAccount
        +string Name
        +string VendorGroup
        +string Currency
        +string PaymentTerms
        +string CountryRegionId
    }
    
    ClientRequest --> Address
    ClientRequest --> EnrichedMessage : Logic App Enriches
    EnrichedMessage --> VendorData
    EnrichedMessage --> Metadata
    VendorData --> Address
    EnrichedMessage --> ServiceBusMessage : Serialized to
    ServiceBusMessage --> BlobStorageFile : Processed into
    ClientRequest --> D365Request : Transformed for D365
    
    note for EnrichedMessage "Added by Logic App or HttpIngest Function"
    note for Metadata "messageId: GUID, receivedAtUtc: ISO 8601"
    note for BlobStorageFile "One file per vendor submission"
```

---

## 8. Security Architecture

```mermaid
graph TB
    subgraph "Identity & Access Management"
        AAD2[Azure Active Directory<br/>Tenant: demoentraid123]
        AppReg2[App Registration<br/>Client ID + Secret]
        MI2[Managed Identity<br/>System Assigned<br/>- APIM<br/>- Function App]
    end
    
    subgraph "Secret Management"
        KV3[Key Vault<br/>RBAC Authorization]
        KVSecret1[Key Vault Secret:<br/>d365-token]
        KVSecret2[Key Vault Secret:<br/>function-key]
        KVSecret3[Named Value:<br/>func_key]
    end
    
    subgraph "Network Security"
        HTTPS[HTTPS Only<br/>TLS 1.2 Minimum]
        CORS[CORS Policies]
        Firewall[Storage Firewall<br/>No Public Blob Access]
    end
    
    subgraph "Authentication Methods"
        JWT[JWT Token<br/>Bearer Scheme<br/>OpenID Connect]
        SubKey[Subscription Key<br/>APIM Product]
        FuncKey[Function Key<br/>Query Parameter]
        SharedKey[Storage Shared Key<br/>HMAC SHA256]
        MIToken[MI Token<br/>OAuth 2.0]
    end
    
    subgraph "Authorization (RBAC)"
        RBAC2[Role Assignments]
        Role1[Service Bus Data Sender<br/>Function → Service Bus]
        Role2[Service Bus Data Receiver<br/>Function → Service Bus]
        Role3[Storage Blob<br/>Data Contributor<br/>Function → ADLS]
        Role4[Key Vault Secrets User<br/>APIM → Key Vault]
    end
    
    subgraph "Audit & Compliance"
        Logs[Diagnostic Logs<br/>All API Calls Logged]
        Retention[30 Days Retention<br/>Log Analytics]
        SoftDelete[Soft Delete<br/>7 Days<br/>Key Vault]
    end
    
    %% Connections
    AAD2 --> AppReg2
    AAD2 --> MI2
    MI2 --> RBAC2
    
    KV3 --> KVSecret1
    KV3 --> KVSecret2
    KV3 --> KVSecret3
    
    RBAC2 --> Role1
    RBAC2 --> Role2
    RBAC2 --> Role3
    RBAC2 --> Role4
    
    JWT -.-> AAD2
    SubKey -.-> KV3
    FuncKey -.-> KV3
    SharedKey -.-> KV3
    MIToken -.-> MI2
    
    Logs --> Retention
    KV3 --> SoftDelete
    
    style AAD2 fill:#ff5722
    style KV3 fill:#607d8b
    style MI2 fill:#ffc107
    style RBAC2 fill:#4caf50
    style JWT fill:#2196f3
```

---

## 9. Deployment Pipeline

```mermaid
graph LR
    subgraph "Source Control"
        Repo[GitHub Repository<br/>Main Branch]
        PR[Pull Request]
        Merge[Merge to Main]
    end
    
    subgraph "CI/CD - GitHub Actions"
        Trigger[Workflow Trigger<br/>Push or PR]
        Checkout[Checkout Code]
        BuildFunc[Build Functions<br/>Package PowerShell]
        ValidateBicep[Validate Bicep<br/>Lint & Test]
        DeployInfra[Deploy Infrastructure<br/>Bicep Modules]
        DeployFunc[Deploy Function Code<br/>ZIP Deploy]
        DeployLA[Deploy Logic App<br/>Update Definition]
        ConfigAPIM[Configure APIM<br/>Policies & Products]
        SmokeTest[Run Smoke Tests<br/>test-demo.ps1]
        Cleanup[Cleanup on Failure]
    end
    
    subgraph "Azure Resources"
        RG[Resource Group<br/>rg-d365-demo]
        Resources[All Resources<br/>Created/Updated]
    end
    
    subgraph "Testing & Verification"
        Test1[Test APIM Endpoint<br/>JWT Authentication]
        Test2[Test Logic App<br/>Direct Invocation]
        Test3[Test Function<br/>HTTP Trigger]
        Test4[Verify Service Bus<br/>Queue Messages]
        Test5[Verify ADLS<br/>Blob Landing]
    end
    
    subgraph "Monitoring Setup"
        SetupAlerts[Configure Alerts<br/>setup-monitoring.ps1]
        AlertRules[Alert Rules Created<br/>4 Rules]
        ActionGroup[Action Group<br/>Email: admin@...]
    end
    
    %% Flow
    Repo --> PR
    PR --> Merge
    Merge --> Trigger
    
    Trigger --> Checkout
    Checkout --> BuildFunc
    BuildFunc --> ValidateBicep
    ValidateBicep --> DeployInfra
    DeployInfra --> RG
    RG --> Resources
    DeployInfra --> DeployFunc
    DeployFunc --> DeployLA
    DeployLA --> ConfigAPIM
    ConfigAPIM --> SmokeTest
    
    SmokeTest --> Test1
    SmokeTest --> Test2
    SmokeTest --> Test3
    SmokeTest --> Test4
    SmokeTest --> Test5
    
    Test5 -->|Success| SetupAlerts
    Test5 -->|Failure| Cleanup
    
    SetupAlerts --> AlertRules
    AlertRules --> ActionGroup
    
    style Trigger fill:#4caf50
    style DeployInfra fill:#2196f3
    style SmokeTest fill:#ff9800
    style Resources fill:#00bcd4
    style ActionGroup fill:#f44336
```

---

## 10. Testing Strategy

```mermaid
graph TB
    subgraph "Test Scenarios"
        T1[1. APIM JWT Test<br/>test-apim-jwt.ps1]
        T2[2. Logic App Direct Test<br/>test-logic-app.ps1]
        T3[3. Function Direct Test<br/>test-function-direct.ps1]
        T4[4. End-to-End Test<br/>test-e2e-final.ps1]
        T5[5. Service Bus Test<br/>check-deadletter.ps1]
        T6[6. Mock D365 Test<br/>test-mock-d365.ps1]
    end
    
    subgraph "Test Data"
        Payload[sample-vendor-payload.json]
        Creds[CREDENTIALS.txt]
        Config[config.env.example]
    end
    
    subgraph "Test Execution"
        GetToken[1. Acquire JWT Token<br/>OAuth2 Client Credentials]
        CallAPI[2. Call API Endpoint<br/>POST with Bearer Token]
        ValidateResponse[3. Validate Response<br/>202 Accepted]
        CheckQueue[4. Check Service Bus<br/>Message Count]
        CheckBlob[5. Check ADLS Gen2<br/>Blob Created]
        CheckLogs[6. Check App Insights<br/>Traces & Exceptions]
    end
    
    subgraph "Validation Points"
        V1[✓ JWT Token Valid<br/>✓ Token Not Expired]
        V2[✓ APIM Response 202<br/>✓ enqueued: true]
        V3[✓ Message in Queue<br/>✓ No Dead Letters]
        V4[✓ Blob File Created<br/>✓ Correct Path<br/>✓ Valid JSON]
        V5[✓ No Exceptions<br/>✓ All Traces Present]
    end
    
    subgraph "Test Results"
        Pass[All Tests Passed<br/>System Ready]
        Fail[Test Failed<br/>Check Diagnostics]
        Diagnose[Run Diagnostics<br/>diagnose-app.ps1]
    end
    
    %% Flow
    T1 --> GetToken
    T2 --> GetToken
    T3 --> CallAPI
    T4 --> GetToken
    
    Payload --> CallAPI
    Creds --> GetToken
    Config --> GetToken
    
    GetToken --> V1
    V1 --> CallAPI
    CallAPI --> ValidateResponse
    ValidateResponse --> V2
    V2 --> CheckQueue
    CheckQueue --> V3
    V3 --> CheckBlob
    CheckBlob --> V4
    V4 --> CheckLogs
    CheckLogs --> V5
    
    V5 -->|Success| Pass
    V5 -->|Failure| Fail
    Fail --> Diagnose
    
    T5 --> CheckQueue
    T6 --> CallAPI
    
    style Pass fill:#4caf50
    style Fail fill:#f44336
    style V1 fill:#8bc34a
    style V2 fill:#8bc34a
    style V3 fill:#8bc34a
    style V4 fill:#8bc34a
    style V5 fill:#8bc34a
```

---

## 11. Operational Workflows

```mermaid
stateDiagram-v2
    [*] --> Deployed: Infrastructure Deployed
    
    Deployed --> Configured: Configure Secrets & Keys
    Configured --> Ready: Test Endpoints
    
    Ready --> Processing: Receive API Request
    Processing --> Validating: JWT & Rate Limit Check
    
    Validating --> Orchestrating: Valid Request
    Validating --> Rejected: Invalid JWT or Rate Exceeded
    
    Orchestrating --> CallingD365: Logic App Triggered
    CallingD365 --> Enriching: D365 Response (Success/Fail)
    Enriching --> Queueing: Message Enriched
    
    Queueing --> Queued: Message in Service Bus
    Queued --> TriggeredProcessor: Service Bus Trigger
    
    TriggeredProcessor --> Parsing: Function Processes Message
    Parsing --> Validating2: Parse JSON
    Validating2 --> Transforming: Valid Message
    Validating2 --> DeadLetter: Invalid Message
    
    Transforming --> Uploading: Build Blob Path
    Uploading --> Completed: Upload to ADLS
    Uploading --> Retrying: Upload Failed
    
    Retrying --> Uploading: Retry Attempt
    Retrying --> DeadLetter: Max Retries Exceeded
    
    Completed --> Monitoring: Log Success
    DeadLetter --> Monitoring: Log Failure
    Rejected --> Monitoring: Log Rejection
    
    Monitoring --> AlertCheck: Check Thresholds
    AlertCheck --> AlertTriggered: Threshold Exceeded
    AlertCheck --> Ready: Within Limits
    
    AlertTriggered --> Investigation: Send Email Alert
    Investigation --> Remediation: Diagnose Issue
    Remediation --> Ready: Issue Resolved
    
    Ready --> [*]: System Operational
```

---

## Summary

This comprehensive diagram set covers:

1. **High-Level Architecture** - Overall system components and connections
2. **Detailed Data Flow** - Step-by-step sequence of operations
3. **Authentication Flow** - JWT and RBAC authorization
4. **Component Architecture** - Individual service configurations
5. **Infrastructure as Code** - Bicep deployment structure
6. **Error Handling** - Error sources and monitoring
7. **Data Model** - Message schemas and transformations
8. **Security Architecture** - Identity, secrets, and access control
9. **Deployment Pipeline** - CI/CD workflow
10. **Testing Strategy** - Comprehensive test scenarios
11. **Operational Workflows** - State transitions and operations

### Key Technologies

- **Azure API Management** (JWT validation, rate limiting)
- **Logic Apps** (Orchestration, D365 integration)
- **Azure Functions** (PowerShell, event-driven processing)
- **Service Bus** (Reliable messaging)
- **ADLS Gen2** (Data lake storage)
- **Application Insights** (Monitoring and observability)
- **Bicep** (Infrastructure as Code)
- **Azure Active Directory** (Authentication and authorization)

### Resource Naming Convention

- Prefix: `d365demo` or `demo`
- Suffix: `{uniqueString}` (8 characters)
- Resource Group: `rg-d365-demo`
- Location: `westeurope`

### Contact

- Admin Email: `admin@demoentraid123.onmicrosoft.com`
- Tenant: `demoentraid123.onmicrosoft.com`
- Subscription: `{your-subscription-id}`
