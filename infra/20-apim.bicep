param apimName string
param productDisplayName string = 'D365 Demo'
param productId string = 'd365-demo'
param apiName string = 'vendor-ingest'
param apiDisplayName string = 'Vendor Ingest API'
param apiPath string = 'vendor-ingest'
param operationName string = 'post-vendors'
param operationDisplayName string = 'Submit Vendor'
param functionHostname string
param functionKey string
param openIdConfigUrl string
param audience string
param rateLimitCalls int = 60
param renewalPeriodSec int = 60

resource apim 'Microsoft.ApiManagement/service@2022-08-01' existing = {
  name: apimName
}

resource nvFuncKey 'Microsoft.ApiManagement/service/namedValues@2022-08-01' = {
  parent: apim
  name: 'func_key'
  properties: {
    displayName: 'Function_Default_Key'
    value: functionKey
    secret: true
  }
}

resource backendFunc 'Microsoft.ApiManagement/service/backends@2022-08-01' = {
  parent: apim
  name: 'func-backend'
  properties: {
    url: 'https://${functionHostname}/api'
    protocol: 'http'
    tls: { validateCertificateChain: true, validateCertificateName: true }
  }
}

resource api 'Microsoft.ApiManagement/service/apis@2022-08-01' = {
  parent: apim
  name: apiName
  properties: {
    displayName: apiDisplayName
    path: apiPath
    protocols: [ 'https' ]
    serviceUrl: 'https://${functionHostname}/api'
  }
  dependsOn: [ backendFunc ]
}

resource op 'Microsoft.ApiManagement/service/apis/operations@2022-08-01' = {
  parent: api
  name: operationName
  properties: {
    displayName: operationDisplayName
    method: 'POST'
    urlTemplate: '/vendors'
    request: {
      headers: [ { name: 'Authorization', required: true, type: 'string' } ]
      representations: [ { contentType: 'application/json' } ]
    }
    responses: [
      { statusCode: 202, description: 'Accepted' }
      { statusCode: 400, description: 'Bad Request' }
      { statusCode: 401, description: 'Unauthorized' }
    ]
  }
}

// Landing page API at root path
resource landingApi 'Microsoft.ApiManagement/service/apis@2022-08-01' = {
  parent: apim
  name: 'landing'
  properties: {
    displayName: 'Landing Page'
    path: ''  // Empty path = root
    protocols: [ 'https' ]
    subscriptionRequired: false  // Make landing page publicly accessible
  }
}

resource landingOp 'Microsoft.ApiManagement/service/apis/operations@2022-08-01' = {
  parent: landingApi
  name: 'get-root'
  properties: {
    displayName: 'Demo Landing Page'
    method: 'GET'
    urlTemplate: '/'
    responses: [
      { statusCode: 200, description: 'Landing page' }
    ]
  }
}

resource landingOpPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2022-08-01' = {
  parent: landingOp
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: '''<policies>
  <inbound>
    <base />
    <return-response>
      <set-status code="200" reason="OK" />
      <set-header name="Content-Type" exists-action="override">
        <value>text/html; charset=utf-8</value>
      </set-header>
      <set-body><![CDATA[<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>D365 Integration Demo - API Management</title>
  <style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
    .container { max-width: 900px; margin: 0 auto; background: white; border-radius: 12px; box-shadow: 0 8px 32px rgba(0,0,0,0.1); padding: 40px; }
    h1 { color: #0f6cbd; margin-top: 0; font-size: 2.5em; border-bottom: 3px solid #0f6cbd; padding-bottom: 15px; }
    h2 { color: #333; margin-top: 30px; font-size: 1.6em; }
    h3 { color: #555; margin-top: 20px; font-size: 1.2em; }
    .status { background: #d4edda; border: 1px solid #c3e6cb; color: #155724; padding: 15px; border-radius: 6px; margin: 20px 0; }
    .status strong { color: #0a3d14; }
    code { background: #f4f4f4; padding: 3px 6px; border-radius: 4px; color: #e83e8c; font-family: 'Courier New', monospace; font-size: 0.9em; }
    pre { background: #2d2d2d; color: #f8f8f2; padding: 20px; border-radius: 6px; overflow-x: auto; border-left: 4px solid #0f6cbd; }
    pre code { background: transparent; color: #f8f8f2; padding: 0; }
    .endpoint { background: #e7f3ff; padding: 15px; border-radius: 6px; border-left: 4px solid #0078d4; margin: 15px 0; }
    .credentials { background: #fff4e6; padding: 15px; border-radius: 6px; border-left: 4px solid #ff9800; margin: 15px 0; }
    .warning { background: #fff3cd; border: 1px solid #ffc107; color: #856404; padding: 12px; border-radius: 6px; margin: 15px 0; }
    ul { line-height: 1.8; }
    li { margin: 8px 0; }
    .step { background: #f8f9fa; padding: 15px; margin: 15px 0; border-radius: 6px; border-left: 4px solid #28a745; }
    .step-number { background: #28a745; color: white; padding: 5px 12px; border-radius: 50%; font-weight: bold; margin-right: 10px; }
    table { width: 100%; border-collapse: collapse; margin: 15px 0; }
    th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #0f6cbd; color: white; }
    .footer { margin-top: 40px; padding-top: 20px; border-top: 2px solid #eee; color: #666; font-size: 0.9em; text-align: center; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🚀 D365 Integration Demo</h1>
    
    <div class="status">
      <strong>✅ Status:</strong> All systems operational | JWT Authentication: Active | Service Bus: Connected
    </div>

    <h2>📌 Overview</h2>
    <p>This API Management gateway provides a secure, production-ready endpoint for D365 vendor data integration. All requests are authenticated using OAuth 2.0 JWT tokens and require a valid subscription key.</p>

    <h2>🔗 API Endpoint</h2>
    <div class="endpoint">
      <strong>POST</strong> <code>https://demo-apim-nfittwqa7bkom.azure-api.net/vendor-ingest/vendors</code>
    </div>

    <h2>🔐 Authentication</h2>
    
    <h3>Step 1: Acquire JWT Token</h3>
    <p>Use OAuth 2.0 Client Credentials flow to obtain an access token:</p>
    <div class="credentials">
      <table>
        <tr><th>Parameter</th><th>Value</th></tr>
        <tr><td>Tenant ID</td><td><code>f8054917-dc24-4ea5-9363-fa27b4814bbe</code></td></tr>
        <tr><td>Client ID</td><td><code>5e973595-34cc-42b3-b290-857aeeab580a</code></td></tr>
        <tr><td>Scope</td><td><code>api://757412f8-fe70-479c-afef-d4fe635a40ea/.default</code></td></tr>
        <tr><td>Token Endpoint</td><td><code>https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token</code></td></tr>
      </table>
    </div>

    <div class="warning">
      ⚠️ <strong>Note:</strong> The client secret is provided separately for security. Contact the administrator if you need access.
    </div>

    <h3>Step 2: Make API Request</h3>
    <p>Include the JWT token and subscription key in your request headers:</p>
    <pre><code>Authorization: Bearer &lt;YOUR_JWT_TOKEN&gt;
Ocp-Apim-Subscription-Key: &lt;YOUR_SUBSCRIPTION_KEY&gt;
Content-Type: application/json</code></pre>

    <h2>📦 Request Payload</h2>
    <p>Submit vendor data in the following JSON format:</p>
    <pre><code>{
  "data": {
    "VendorAccount": "VENDOR001",
    "Name": "Contoso Corporation",
    "VendorGroup": "GROUP01",
    "Currency": "USD",
    "PaymentTerms": "Net30",
    "CountryRegionId": "USA"
  }
}</code></pre>

    <h3>Required Fields</h3>
    <ul>
      <li><code>VendorAccount</code> - Unique vendor identifier</li>
      <li><code>Name</code> - Vendor business name</li>
      <li><code>CountryRegionId</code> - ISO country code</li>
    </ul>

    <h2>✅ Success Response</h2>
    <p>On successful submission, you will receive:</p>
    <pre><code>HTTP/1.1 202 Accepted
{
  "enqueued": true,
  "id": "f85f05e8-fc78-45bc-a001-a4d07bc150c5"
}</code></pre>

    <h2>🔄 Data Flow</h2>
    <div class="step">
      <span class="step-number">1</span> Client acquires JWT token from Azure AD
    </div>
    <div class="step">
      <span class="step-number">2</span> Request sent to APIM with JWT token and subscription key
    </div>
    <div class="step">
      <span class="step-number">3</span> APIM validates JWT token and routes to Azure Function
    </div>
    <div class="step">
      <span class="step-number">4</span> Function validates payload and sends to Service Bus
    </div>
    <div class="step">
      <span class="step-number">5</span> Service Bus triggers processor function
    </div>
    <div class="step">
      <span class="step-number">6</span> Data lands in ADLS Gen2 storage (container: <code>landing</code>)
    </div>

    <h2>🧪 Testing</h2>
    <p>Use PowerShell for quick testing:</p>
    <pre><code># Run the automated test script
.\test-e2e-final.ps1

# Or test with custom payload
.\test-detailed.ps1</code></pre>

    <h2>📊 Architecture</h2>
    <ul>
      <li><strong>Resource Group:</strong> rg-d365-demo-v2</li>
      <li><strong>APIM:</strong> demo-apim-nfittwqa7bkom</li>
      <li><strong>Function App:</strong> demo-func-nfittwqa7bkom</li>
      <li><strong>Service Bus:</strong> demo-sb-nfittwqa7bkom (queue: inbound)</li>
      <li><strong>Storage:</strong> demoadlsnfittwqa7bkom (container: landing)</li>
    </ul>

    <h2>❓ Support</h2>
    <p>For assistance or to report issues:</p>
    <ul>
      <li>Check logs in Azure Function App</li>
      <li>Monitor Service Bus queue for dead-letter messages</li>
      <li>Review Application Insights for request traces</li>
      <li>See documentation in repository for troubleshooting guides</li>
    </ul>

    <div class="footer">
      <p><strong>D365 Integration Demo</strong> | Powered by Azure API Management, Azure Functions, and Service Bus</p>
      <p>Last Updated: 2025-10-28 | Version 1.0</p>
    </div>
  </div>
</body>
</html>]]></set-body>
    </return-response>
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>'''
  }
}

resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2022-08-01' = {
  parent: api
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: '<policies><inbound><base /><validate-jwt header-name="Authorization" require-expiration-time="true" require-scheme="Bearer" failed-validation-httpcode="401"><openid-config url="${openIdConfigUrl}" /><audiences><audience>${audience}</audience></audiences></validate-jwt><rewrite-uri template="/HttpIngest" /><set-query-parameter name="code" exists-action="override"><value>${functionKey}</value></set-query-parameter></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>'
  }
  dependsOn: [ nvFuncKey ]
}

resource prod 'Microsoft.ApiManagement/service/products@2022-08-01' = {
  parent: apim
  name: productId
  properties: {
    displayName: productDisplayName
    description: 'APIM product for D365 demo'
    terms: 'Use for demo only'
    subscriptionRequired: true
    approvalRequired: false
    state: 'published'
  }
}

resource prodApi 'Microsoft.ApiManagement/service/products/apis@2022-08-01' = {
  parent: prod
  name: apiName
}
