#Joiner info
param(
[string]$Dept = "Marketing",
[string]$FirstName = "Elena",
[string]$LastName = "Mark",
[string]$UserID = "emark",
[string]$Title = "$($Dept) Staff"

)


$TargetOU = "OU=$Dept,OU=Users,OU=Corporate,DC=company,DC=local"
$Password = ConvertTo-SecureString "Lab2026!DC" -AsPlainText -Force

#New Hire info
$NewUser = @{
First = $FirstName;
Last = $LastName;
ID = $UserID;
Title = $Title
}


try{
#Check if user exists
if(Get-ADUser -Filter "SamAccountName -eq '$UserID'") {
Write-Warning "User $($NewUser.ID) already exists"
return
} 

#Define Splatting Table
else {
$NewUser = @{
SamAccountName = $UserID
DisplayName = "$($FirstName) $($LastName)"
Name = "$($FirstName) $($LastName)"
GivenName = $FirstName
Surname = $LastName
Description = $Title
Path = $TargetOU
AccountPassword = $Password
Enabled = $true
ChangePasswordAtLogon = $true
ErrorAction = "Stop"
}

#Create the User 
New-ADUser @NewUser
Write-Host "Created $($UserID)"

#Add into group
Add-ADGroupMember -Identity "$($Dept)_Staff_GG" -Members $UserID -ErrorAction Stop
Write-Host "Added $($UserID) into $($Dept)_Staff_GG"
}
}

#Exit if User additon fails
catch {
Write-Error "Failed: $($_.Exception.Message)"
return
}