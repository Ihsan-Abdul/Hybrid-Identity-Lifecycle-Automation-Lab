#Add a new hire into Marketing

#Variables
$Dept = "Marketing"
$TargetOU = "OU=$Dept,OU=Users,OU=Corporate,DC=company,DC=local"
$Password = ConvertTo-SecureString "Lab2026!DC" -AsPlainText -Force

#New Hire info
$NewUser = @{
First = "Sam";
Last = "Clerk";
ID = "sclerk";
Title = "$Dept Staff"
}


try{
#Check if user exists
if(Get-ADUser -Filter "SamAccountName -eq '$($NewUser.ID)'") {
Write-Warning "User $($NewUser.ID) already exists"
} 

#Define Splatting Table
else {
$UserParams = @{
SamAccountName = $NewUser.ID
DisplayName = "$($NewUser.First) $($NewUser.Last)"
Name = "$($NewUser.First) $($NewUser.Last)"
GivenName = $NewUser.First
Surname = $NewUser.Last
Description = $NewUser.Title
Path = $TargetOU
AccountPassword = $Password
Enabled = $true
ChangePasswordAtLogon = $true
ErrorAction = "Stop"
}

#Create the User 
New-ADUser @UserParams
Write-Host "Created $($NewUser.ID)"

#Add into group
Add-ADGroupMember -Identity "$($Dept)_Staff_GG" -Members $NewUser.ID -ErrorAction Stop
Write-Host "Added $($NewUser.ID) into $($Dept)_Staff_GG"
}
}

#Exit if User additon fails
catch {
Write-Error "Failed: $($_.Exception.Message)"
return
}