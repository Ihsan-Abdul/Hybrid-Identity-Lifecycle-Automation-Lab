
# Inactive User Review + Privileged Access Review

# Variable Config
$Today = Get-Date
$WarningThreshold = 30
$RiskThreshold = 60

#Custom privileged group in this lab
$PrivilegedGroups = @(
    "IT_Admin_GG"
)

#Pull users from AD
$Users = Get-ADUser -Filter * -Properties LastLogonDate, Enabled, Title, MemberOf

$Results = foreach ($User in $Users) {

#Calculate inactivity once
$DaysInactive = if ($null -ne $User.LastLogonDate) {
    ($Today - $User.LastLogonDate).Days
    }
    else {
        $null
    }

#Check whether the user is a member of the privileged group
$PrivilegedMemberships = foreach ($GroupDN in $User.MemberOf) {
    try {
        $GroupName = (Get-ADGroup $GroupDN).Name
        if ($PrivilegedGroups -contains $GroupName) {
            $GroupName
            }
        }
        catch {
            # Ignore lookup failures
        }
    }

$PrivilegedMemberships = @($PrivilegedMemberships | Where-Object { $_ })
$IsPrivileged = $PrivilegedMemberships.Count -gt 0

#Assign status, risk, and recommended action
if (-not $User.Enabled) {
    $Status = "Account is disabled"
    $RiskLevel = "Low"
    $RecommendedAction = "Verify disabled account needed for retention"
    }
    elseif ($null -eq $DaysInactive) {
        $Status = "No login recorded"

    if ($IsPrivileged) {
        $RiskLevel = "High"
        $RecommendedAction = "Immediate privileged access review"
        }
    else {
        $RiskLevel = "Medium"
        $RecommendedAction = "Investigate missing logon activity"
        }
    }

    elseif ($DaysInactive -ge $RiskThreshold -and $IsPrivileged) {
        $Status = "Privileged account inactive beyond risk threshold"
        $RiskLevel = "High"
        $RecommendedAction = "Review immediately: remove privileged access or disable if no longer needed"
    }
    elseif ($DaysInactive -ge $RiskThreshold) {
        $Status = "Inactive beyond risk threshold"
        $RiskLevel = "High"
        $RecommendedAction = "Review account and consider disabling"
    }
    elseif ($DaysInactive -ge $WarningThreshold -and $IsPrivileged) {
        $Status = "Privileged account inactive beyond warning threshold"
        $RiskLevel = "High"
        $RecommendedAction = "Review privileged access is necessary"
    }
    elseif ($DaysInactive -ge $WarningThreshold) {
        $Status = "Inactive beyond warning threshold"
        $RiskLevel = "Medium"
        $RecommendedAction = "Review inactivity"
    }
    elseif ($IsPrivileged) {
        $Status = "Active privileged account"
        $RiskLevel = "Medium"
        $RecommendedAction = "Periodically review privileged access"
    }
    else {
        $Status = "Active"
        $RiskLevel = "Low"
        $RecommendedAction = "No action required"
    }

[PSCustomObject]@{
Name = $User.Name
SamAccountName = $User.SamAccountName
Role = $User.Title
Enabled = $User.Enabled
LastLogonDate = $User.LastLogonDate
DaysInactive = $DaysInactive
Privileged = $IsPrivileged
PrivilegedGroups = ($PrivilegedMemberships -join ", ")
Status = $Status
RiskLevel = $RiskLevel
RecommendedAction = $RecommendedAction
    }
}

# Export and display
$Results | Export-Csv -Path ".\reports\identity-risk-audit.csv" -NoTypeInformation
$Results | Out-GridView -Title "Identity Risk Audit"