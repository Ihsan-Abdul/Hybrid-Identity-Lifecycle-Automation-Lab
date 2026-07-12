#Inactive User Review

#Variable Config
$Today = Get-Date
$WarningThreshold = 30
$RiskThreshold = 60

#pull users from AD
Get-ADUser -Filter * -Properties LastLogonDate, Enabled, Title |
Select-Object Name, samAccountName,
@{Name = "Role"; Expression = {$_.Title}},
Enabled,
LastLogonDate,

#calculate inactivity
@{Name = "DaysInactive"; Expression = {
    if($null -ne $_.LastLogonDate) {($Today - $_.LastLogonDate).Days}
    else {$null}
}},

@{Name = "Status"; Expression = {
    if ($_.Enabled -eq $false) {"Account is Disabled"}
    elseif ($null -eq $_.LastLogonDate) {"No login recorded"}
    else {
        $ActualDays = ($Today - $_.LastLogonDate).Days
            
            if ($ActualDays -ge $RiskThreshold) {"Risk: Account inactive for more than $RiskThreshold Days"}
            elseif ($ActualDays -ge $WarningThreshold) {"Warning: Account inactive for more than $WarningThreshold Days"}
            else {"Active"}
            }

}} |

#Display results
Out-GridView -Title "Inactive User Audit"
Export-Csv -Path ".\reports\inactive-user-audit.csv" -NoTypeInformation



