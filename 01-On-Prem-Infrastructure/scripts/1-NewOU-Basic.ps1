#Create Marketing OU
New-ADOrganizationalUnit -Name "Marketing" -Path "OU=Users,OU=Corporate,DC=company,DC=local"

#Create Global groups
New-ADGroup -Name "Marketing_Staff_GG" -GroupScope Global -Path "OU=Groups,OU=Corporate,DC=company,DC=local"
New-ADGroup -Name "Marketing_Manager_GG" -GroupScope Global -Path "OU=Groups,OU=Corporate,DC=company,DC=local"


#Create Domain Local Groups
New-ADGroup -Name "Marketing_Files" -GroupScope DomainLocal -Path "OU=Groups,OU=Corporate,DC=company,DC=local"
New-ADGroup -Name "Marketing_Manager_Files" -GroupScope DomainLocal -Path "OU=Groups,OU=Corporate,DC=company,DC=local"

#Nesting Global Groups into Correct Domain Local Groups

#Staff only have access to "Marketing_Files" while Managers have access to both
Add-ADGroupMember -Identity "Marketing_Files" -Members "Marketing_Staff_GG", "Marketing_Manager_GG"

#Managers have access to both "Marketing_Files" and "Marketing_Manager_Files"
Add-ADGroupMember -Identity "Marketing_Manager_Files" -Members "Marketing_Manager_GG"

#Creating Users and Adding to Global Groups
$SecurePass = "Lab2026!DC" | ConvertTo-SecureString -AsPlainText -Force

#Managers (two)
New-ADUser -Name "Alice Boss" -SamAccountName "aboss" -Title "Marketing Manager" -Department "Marketing" `
-Path "OU=Marketing,OU=Users,OU=Corporate,DC=company,DC=local" `
-AccountPassword $SecurePass -Enabled $true -ChangePasswordAtLogon $true

Add-ADGroupMember -Identity "Marketing_Manager_GG" -Members "aboss"

New-ADUser -Name "Sam Clerk" -SamAccountName "sclerk" -Title "Marketing Manager" -Department "Marketing" `
-Path "OU=Marketing,OU=Users,OU=Corporate,DC=company,DC=local" `
-AccountPassword $SecurePass -Enabled $true -ChangePasswordAtLogon $true

Add-ADGroupMember -Identity "Marketing_Manager_GG" -Members "sclerk"

#Staff (two)
New-ADUser -Name "Maya Vance" -SamAccountName "mvance" `
-Title "Marketing Staff" -Department "Marketing" -Manager "sclerk" `
-Path "OU=Marketing,OU=Users,OU=Corporate,DC=company,DC=local" `
-AccountPassword $SecurePass -Enabled $true -ChangePasswordAtLogon $true
Add-ADGroupMember -Identity "Marketing_Staff_GG" -Members "mvance"

New-ADUser -Name "Leo Sterling" -SamAccountName "lsterling" `
-Title "Marketing Staff" -Department "Marketing" -Manager "aboss" `
-Path "OU=Marketing,OU=Users,OU=Corporate,DC=company,DC=local" `
-AccountPassword $SecurePass -Enabled $true -ChangePasswordAtLogon $true
Add-ADGroupMember -Identity "Marketing_Staff_GG" -Members "lsterling"
