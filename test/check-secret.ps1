# Check if you have the correct client secret format

$providedSecret = "88b59cca-16c3-4386-91dd-a27be9b833e7"

Write-Host "Checking your client secret format..." -ForegroundColor Yellow
Write-Host ""

if ($providedSecret -match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') {
    Write-Host "X INCORRECT FORMAT!" -ForegroundColor Red
    Write-Host ""
    Write-Host "You provided what looks like a Secret ID (GUID), not the secret VALUE." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "The client secret VALUE should look like:" -ForegroundColor Cyan
    Write-Host "  Xyz~1Abc2Def3Ghi4Jkl5Mno6Pqr7Stu8Vwx9Yz0" -ForegroundColor White
    Write-Host "  or"
    Write-Host "  abc123def456ghi789jkl012mno345pqr678stu" -ForegroundColor White
    Write-Host ""
    Write-Host "How to get the correct value:" -ForegroundColor Yellow
    Write-Host "==============================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option 1: Create a NEW client secret (RECOMMENDED)" -ForegroundColor Green
    Write-Host "  1. Go to https://portal.azure.com"
    Write-Host "  2. Azure Active Directory > App registrations"
    Write-Host "  3. Click 'D365-Demo-API'"
    Write-Host "  4. Left menu: 'Certificates & secrets'"
    Write-Host "  5. Click '+ New client secret'"
    Write-Host "  6. Description: 'JWT Testing'"
    Write-Host "  7. Expires: '6 months'"
    Write-Host "  8. Click 'Add'"
    Write-Host "  9. IMMEDIATELY copy the VALUE (shown in the 'Value' column)"
    Write-Host "     - This is shown ONLY ONCE!"
    Write-Host "     - Do NOT copy the 'Secret ID' column"
    Write-Host ""
    Write-Host "Option 2: If you already created a secret and saved the value" -ForegroundColor Cyan
    Write-Host "  - Find where you saved it"
    Write-Host "  - It should be a long alphanumeric string, possibly with special chars"
    Write-Host ""
    Write-Host "Then run the test again:" -ForegroundColor Yellow
    Write-Host '  .\test-jwt-simple.ps1 -SubscriptionKey "YOUR_SUBSCRIPTION_KEY_HERE" -ClientSecret "THE-ACTUAL-SECRET-VALUE"'
    Write-Host ""
} else {
    Write-Host "+ Format looks correct!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your secret appears to be in the right format." -ForegroundColor Cyan
    Write-Host "Length: $($providedSecret.Length) characters"
    Write-Host ""
    Write-Host "If authentication still fails, the secret might be:" -ForegroundColor Yellow
    Write-Host "  - Expired"
    Write-Host "  - From a different app"
    Write-Host "  - Not yet propagated (wait 1-2 minutes)"
    Write-Host ""
    Write-Host "You can try creating a fresh client secret to be sure."
}
