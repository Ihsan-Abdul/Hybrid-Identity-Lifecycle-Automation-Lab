#Define Variables
$UserID = "lsterling"
$Dept = "Marketing"
$OldTitle = "Staff"
$NewTitle = "Manager"
$TargetOU = "OU=$Dept,OU=Users,OU=Corporate,DC=company,DC=local"

#Group Name
$OldGroup = "$($Dept)_Staff_GG"
$NewGroup = "$($Dept)_Manager_GG"

try {
#Check if user has already been moved
$CheckUser = Get-ADUser -Identity $UserID -Properties Title
If($CheckUser.Title -eq $NewTitle){
Write-Host "$UserID is already in $NewTitle. No move needed."
}
else{
#Update User Properties
$UserParams = @{
Title = $NewTitle
Description = "$($Dept)_$($NewTitle)"
Manager = $null
ErrorAction = "Stop"
}

Set-ADUser -Identity $UserID @UserParams 

#Update Group Permissons
Add-ADGroupMember -Identity $NewGroup -Members $UserID -ErrorAction Stop
Remove-ADGroup -Identity $OldGroup -Members $UserID -Confirm: $false -ErrorAction Stop
Write-Host "Successfully added $UserID to $NewGroup"
}
}
catch{

Write-Error "User move failed: $($_.Exception.Message)"
return
}