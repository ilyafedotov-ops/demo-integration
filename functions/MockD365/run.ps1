param($Request, $TriggerMetadata)

Write-Host "Mock D365 OData endpoint called"
Write-Host "Method: $($Request.Method)"
Write-Host "Headers: $($Request.Headers | ConvertTo-Json)"

# Simulate D365 F&O OData response
if ($Request.Method -eq "POST") {
    # Create Vendor
    $vendor = $Request.Body
    
    Write-Host "Creating vendor: $($vendor.VendorAccount)"
    
    # Simulate D365 response with OData metadata
    $response = @{
        "@odata.context" = "https://mock-d365.operations.dynamics.com/data/`$metadata#Vendors/`$entity"
        VendorAccount = $vendor.VendorAccount
        Name = $vendor.Name
        Currency = $vendor.Currency
        CountryRegionId = $vendor.CountryRegionId
        Address = $vendor.Address
        Email = $vendor.Email
        Phone = $vendor.Phone
        VendorGroupId = "DEFAULT"
        PaymentTerms = "Net30"
        DefaultDimensionDisplayValue = ""
        RecId = Get-Random -Minimum 1000000 -Maximum 9999999
        CreatedDateTime = (Get-Date).ToUniversalTime().ToString("o")
    }
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = 201
        Headers = @{ 
            "Content-Type" = "application/json; odata.metadata=minimal"
            "OData-Version" = "4.0"
        }
        Body = ($response | ConvertTo-Json -Depth 10)
    })
    
} elseif ($Request.Method -eq "GET") {
    # List Vendors - return sample data
    $vendors = @(
        @{
            VendorAccount = "V-100001"
            Name = "Contoso Ltd"
            Currency = "USD"
            CountryRegionId = "US"
            VendorGroupId = "DEFAULT"
            RecId = 1000001
        },
        @{
            VendorAccount = "V-100002"
            Name = "Fabrikam Inc"
            Currency = "EUR"
            CountryRegionId = "DE"
            VendorGroupId = "DEFAULT"
            RecId = 1000002
        },
        @{
            VendorAccount = "V-100003"
            Name = "Northwind Traders"
            Currency = "GBP"
            CountryRegionId = "GB"
            VendorGroupId = "DEFAULT"
            RecId = 1000003
        }
    )
    
    $response = @{
        "@odata.context" = "https://mock-d365.operations.dynamics.com/data/`$metadata#Vendors"
        value = $vendors
    }
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = 200
        Headers = @{ 
            "Content-Type" = "application/json; odata.metadata=minimal"
            "OData-Version" = "4.0"
        }
        Body = ($response | ConvertTo-Json -Depth 10)
    })
}

Write-Host "Mock D365 response sent"
