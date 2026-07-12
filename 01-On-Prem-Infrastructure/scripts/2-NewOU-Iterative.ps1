#Variable Declarations

#Enviornment Variables
$Domain = "DC=company,DC=local"
$CorpOU = "OU=corporate,$Domain"
$UserOU = "OU=Users,$CorpOU"
$GroupOU = "OU=Groups,$CorpOU"

#Department Variables
$Dept = "Marketing"
$TargetOU = "OU=$Dept,$UserOU"
$Pass = ConvertTo-SecureString "Lab2026!DC" -AsPlainText -Force

#Create Marketing OU
New-ADOrganizationalUnit -Name "Marketing" -Path $UserOU

#Create Global Groups and Domain Local Groups
New-ADGroup -Name "$($Dept)_Staff_GG" -GroupScope Global -Path $GroupOU
New-ADGroup -Name "$($Dept)_Manager_GG" -GroupScope Global -Path $GroupOU
New-ADGroup -Name "$($Dept)_Files_RW" -GroupScope DomainLocal -Path $GroupOU
New-ADGroup -Name "$($Dept)_Manager_Files_RW" -GroupScope DomainLocal -Path $GroupOU

#Nesting Groups
Add-ADGroupMember -Identity "$($Dept)_Files_RW" -Members "$($Dept)_Staff_GG", "$($Dept)_Manager_GG" 
Add-ADGroupMember -Identity "$($Dept)_Manager_Files_RW" -Members "$($Dept)_Manager_GG"

#Create Array with User info
$UserToCreate = @(
@{First = "Alice"; Last = "Boss"; ID = "aboss"; Title = "Manager"; Mgr = $null }
@{First = "Maya"; Last = "Vance"; ID = "mvance"; Title = "Staff"; Mgr = "aboss"}
@{First = "Leo"; Last = "Sterling"; ID = "lsterling"; Title = "Staff"; Mgr = "aboss"}
)

#Use For Loop to automate User creation 
foreach ($User in $UserToCreate){

#User data
$UserParams = @{
SamAccountName = $User.ID
Name = "$($User.First) $($User.Last)"
GivenName = $User.First
Surname = $User.Last
DisplayName = "$($User.First) $($User.Last)"
Title = $User.Title
Description = "$($Dept)_$($User.Title)"
Department = $Dept
Manager = $User.Mgr
Path = $TargetOU
AccountPassword = $Pass
Enabled = $true
ChangePasswordAtLogon = $true
}
#Create Users
New-ADUser @UserParams

#Add user into appropriate Group
Add-ADGroupMember -Identity "$($Dept)_$($User.Title)_GG" -Members $User.ID
}
