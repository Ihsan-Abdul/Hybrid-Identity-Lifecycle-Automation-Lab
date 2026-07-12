
$LicenseID = "cbdc14ab-d96c-4c30-b9f4-6ada7cdc1d46"

#get users without license
$TargetUsers = Get-MgUser -Filter "assignedLicenses/`$count eq 0" -ConsistencyLevel eventual -CountVariable unlicensedCount

foreach ($User in $TargetUsers) {

try{

Update-MgUser -UserID $User.Id -UsageLocation "CA"
Set-MgUserLicense -UserID $User.Id -AddLicenses @{SkuId = $LicenseID} -RemoveLicenses @()

}
catch{

Write-Host "Failed to license user: $($User.UserprincipalName): $($_.Exception.Message)"
}

}