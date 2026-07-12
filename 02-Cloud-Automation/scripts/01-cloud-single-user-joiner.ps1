#get user email from host

$UserEmail = Read-Host -Prompt "Enter Users Email"
$LicenseID = "cbdc14ab-d96c-4c30-b9f4-6ada7cdc1d46"

#Update location and add license
try {
Update-MgUser -UserId $UserEmail -UsageLocation "CA"
Set-MgUserLicense -UserId $UserEmail -AddLicenses @{SkuId = $LicenseID} -RemoveLicenses @()
}

#Exit with error message
catch {
Write-Host "Error: $($_.Exception.Message)"
}