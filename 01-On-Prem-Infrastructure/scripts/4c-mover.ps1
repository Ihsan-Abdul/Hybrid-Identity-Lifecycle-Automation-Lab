#Dynamic variables to be inputted by user

param(
[Parameter(Mandatory=$true)]
[String]$UserID,

#The new department user is moving to
[Parameter(Mandatory=$true)]
[string]$NewDept,

#Their new title
[Parameter(Mandatory=$true)]
[string]$NewTitle,

#Their new group
[Parameter(Mandatory=$true)]
[string]$NewGroup,

#Their new group
[Parameter(Mandatory=$true)]
[string]$OldGroup,

#ID User Reports to
[Parameter(Mandatory=$false)]
[string]$ReportsToID,

#ID User(s) Reporting from
[Parameter(Mandatory=$false)]
[string]$ReportsFromID

)

$TargetOU = "OU=$NewDept,OU=Users,OU=Corporate,DC=company,DC=local"

try{

#check if user is already moved
$CheckUser = Get-ADUser -Identity $UserID -Properties Title

if($CheckUser.Title -eq $NewTitle){
Write-Host "$UserID has already been moved to $NewTitle"
return
}
else{
#Update Moving User Properties
$UserUpdates = @{
Title = $NewTitle
Department = $NewDept
Description = "$($NewDept)_$($NewTitle)"
ErrorAction = "Stop"
}

#if ReportsToID has a value
if($ReportsToID) {
$UserUpdates.Add("Manager", $ReportsToID)
}
else{
$UserUpdates.Add("Manager", $null)
}

#Set and or move $UserID
 Set-ADUser -Identity $UserID @UserUpdates 
 Get-ADUser -Identity $UserID | Move-ADObject -TargetPath $TargetOU -ErrorAction Stop
 Write-Host "$UserID has been moved to $NewDept as $NewTitle"

#If reports from has a value
if($ReportsFromID) {
$SubSplat = @{
Manager = $UserID
ErrorAction = "Stop"
}

#Set any updates to user reporting to $ManagerID
Set-ADUser -Identity $ReportsFromID @SubSplat
}

#Update Group Permissons
#Added the new group first to ensure user never has zero access during move
Add-ADGroupMember -Identity $NewGroup -Members $UserID -ErrorAction Stop
Remove-ADGroupMember -Identity $OldGroup -Members $UserID -Confirm:$false -ErrorAction Stop
Write-Host "$UserId has from $OldGroup to $NewGroup" 
}

}
catch{
#End script if any errors persist
Write-Error "$UserID failed to move: $($_.Exception.Message)"
return
}