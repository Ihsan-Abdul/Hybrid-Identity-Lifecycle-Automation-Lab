param(
[Parameter(Mandatory=$true)]
[String]$UserID,

#New Manager for reporting staff
[Parameter(Mandatory=$false)]
[string]$NewManager
)

$TargetOU = "OU=DisabledUsers,OU=Corporate,DC=company,DC=local"
$User = Get-ADUser -Identity $UserID -Properties DistinguishedName, Enabled

#Check is user is already in the Disabled OU or if account is already false
if($User.DistinguishedName -like "*OU=DisabledUsers*" -or $User.Enabled -eq $false ){
Write-Host "$UserID is already Disabled or in the Disabled OU"
return
}

try{
#Remove User from Groups permissions
Get-ADPrincipalGroupMembership -Identity $UserID | Where-Object {$_.Name -ne "Domain Users" }| 
Remove-ADGroupMember -Members $UserID -Confirm:$false -ErrorAction Stop

#If role is Manager update any Reporting staff to a new manager
$Subordinate = Get-ADUser -Filter "Manager -eq '$($User.DistinguishedName)'"  
if($Subordinate){
$Subordinate | Set-ADUser -Manager $NewManager 
Write-Host "Re-assigned $($Subordinate.Count) to $NewManager"
}

#Disable Account
Disable-ADAccount -Identity $UserID -ErrorAction Stop

#Move to Disabled Users OU
Move-ADObject -Identity $User.DistinguishedName -TargetPath $TargetOU -ErrorAction Stop
Write-Host "Successfully Ofboarded $UserID" 
}

catch{
Write-Error "Unable to remove $UserID : $($_.Exception.Message)"
return
}