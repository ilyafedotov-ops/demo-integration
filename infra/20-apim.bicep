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

resource opLanding 'Microsoft.ApiManagement/service/apis/operations@2022-08-01' = {
  parent: api
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

resource opLandingPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2022-08-01' = {
  parent: opLanding
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: '<policies><inbound><base /><return-response><set-status code="200" reason="OK" /><set-header name="Content-Type" exists-action="override"><value>text/html; charset=utf-8</value></set-header><set-body>&lt;!DOCTYPE html&gt;&lt;html lang="en"&gt;&lt;head&gt;&lt;meta charset="utf-8" /&gt;&lt;title&gt;D365 Integration Demo&lt;/title&gt;&lt;style&gt;body{font-family:Segoe UI,Arial,sans-serif;margin:40px;max-width:720px;line-height:1.5;color:#1a1a1a;background:#f7f9fc;}h1{color:#0f6cbd;}code{background:#eef3fa;padding:2px 4px;border-radius:4px;}&lt;/style&gt;&lt;/head&gt;&lt;body&gt;&lt;h1&gt;D365 Integration Demo&lt;/h1&gt;&lt;p&gt;This API Management gateway is running and secured with JWT.&lt;/p&gt;&lt;p&gt;Submit vendor data by sending a &lt;code&gt;POST&lt;/code&gt; request to:&lt;/p&gt;&lt;pre&gt;POST /vendor-ingest/vendors&lt;/pre&gt;&lt;p&gt;Include:&lt;/p&gt;&lt;ul&gt;&lt;li&gt;A valid Azure AD access token in the &lt;code&gt;Authorization: Bearer&lt;/code&gt; header&lt;/li&gt;&lt;li&gt;An active subscription key in the &lt;code&gt;Ocp-Apim-Subscription-Key&lt;/code&gt; header&lt;/li&gt;&lt;/ul&gt;&lt;p&gt;See the repository &lt;code&gt;test-jwt-simple.ps1&lt;/code&gt; script for an end-to-end example.&lt;/p&gt;&lt;/body&gt;&lt;/html&gt;</set-body></return-response></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>'
  }
  dependsOn: [ opLanding ]
}

resource servicePolicy 'Microsoft.ApiManagement/service/policies@2022-08-01' = {
  parent: apim
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: '<policies><inbound><base /><choose><when condition="@(context.Request.OriginalUrl.Path == \"/\")"><return-response><set-status code="200" reason="OK" /><set-header name="Content-Type" exists-action="override"><value>text/html; charset=utf-8</value></set-header><set-body>&lt;!DOCTYPE html&gt;&lt;html lang=&quot;en&quot;&gt;&lt;head&gt;&lt;meta charset=&quot;utf-8&quot; /&gt;&lt;title&gt;D365 Integration Demo&lt;/title&gt;&lt;style&gt;body{font-family:Segoe UI,Arial,sans-serif;margin:40px;max-width:720px;line-height:1.5;color:#1a1a1a;background:#f7f9fc;}h1{color:#0f6cbd;}code{background:#eef3fa;padding:2px 4px;border-radius:4px;}&lt;/style&gt;&lt;/head&gt;&lt;body&gt;&lt;h1&gt;D365 Integration Demo&lt;/h1&gt;&lt;p&gt;Welcome! This API Management gateway is live.&lt;/p&gt;&lt;p&gt;To submit vendor data send a &lt;code&gt;POST&lt;/code&gt; request to &lt;code&gt;/vendor-ingest/vendors&lt;/code&gt; with:&lt;/p&gt;&lt;ul&gt;&lt;li&gt;Authorization header: &lt;code&gt;Bearer &lt;JWT&gt;&lt;/code&gt;&lt;/li&gt;&lt;li&gt;Ocp-Apim-Subscription-Key header&lt;/li&gt;&lt;/ul&gt;&lt;p&gt;Use the repository script &lt;code&gt;test-jwt-simple.ps1&lt;/code&gt; for an automated test.&lt;/p&gt;&lt;/body&gt;&lt;/html&gt;</set-body></return-response></when></choose></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>'
  }
  dependsOn: [ nvFuncKey ]
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
