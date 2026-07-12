#Dynamic variables to be inputted by user

param(
#ID of the person being moved
[Parameter(Mandatory=$true)]
[String]$ManagerID,

#ID of user reporting to them
[Parameter(Mandatory=$true)]
[string]$UserID,

#The new department user is moving to
[Parameter(Mandatory=$true)]
[string]$NewDept,

#Their new title
[Parameter(Mandatory=$true)]
[string]$NewTitle
)

$TargetOU = "OU=$NewDept,OU=Users,OU=Corporate,DC=company,OU=local"

try{

#check if user is already moved
$CheckUser = Get-ADUser -Identity $ManagerID -Properties Title

if($CheckUserID.Title -eq $NewTitle){
Write-Host "$ManagerID has already been moved to $NewTitle"
return
}
else{
#Update manager Properties
$ManagerUpdates = @{
Title = $NewTitle
Description = "$($Dept)_$($NewTitle)"
Manager = $null
ErrorAction = "Stop"
}
 Set-ADUser -Identity $ManagerID @ManagerUpdates 
 Get-ADUser -Identity $ManagerID | Move-ADObject -TargetPath $TargetOU -ErrorAction Sop

#Update any Users reporting to new Manager
$UserUpdates = @{
Manager = $ManagerID
ErrorAction = "Stop"
}
Set-ADUser -Identity $UserID @UserUpdates

#Update Group Permissons
Add-ADGroupMember -Identity $NewGroup -Members $ManagerID -ErrorAction Stop
Remove-ADGroup -Identity $OldGroup -Members $ManagerID -Confirm: $false -ErrorAction Stop 
}

}
catch{
#End script if any errors persist
Write-Error "$ManagerID failed to move: $($_.Exception.Message)"
return
}