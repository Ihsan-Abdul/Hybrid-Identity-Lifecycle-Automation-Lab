#rbac drift detection- checks if a users access still aligns with their role

#Variable config
$AttributeDept = "Department"
$AttributeTitle = "Title"


$Results = foreach ($User in Get-ADUser -Filter * -Properties Department, Title, Memberof, Enabled){

    #skip disabled users
    if(-not $User.Enabled){continue}

    #Get attribute values
    $Department = $User.Department
    $Title = $User.Title

     #output missing users attribute(s) and skip
    if(-not $User.Department -or -not $User.Title) {

         $MissingAttributes = @()

        if(-not $Department) {$MissingAttributes += $AttributeDept}
        if(-not $Title) {$MissingAttributes += $AttributeTitle}

        Write-Host "$($User.samAccountName) - Missing: $($MissingAttributes)"
        continue
     }

    #get group names to check
    $Groups = foreach ($GroupDN in $User.Memberof){
    
        try{
            (Get-ADGroup $GroupDN).Name
        }
        catch {Write-Host "$($User.SamAccountName) - Error reading group: $($_.Exception.Message)"}
    
    }

    #Check groups based on departments
    $DeptGroups = $Groups | Where-Object {$_ -like "*$Department*"}

    #Check group matching title of user in the department
    $TitleGroups = $Groups | Where-Object {$_ -like "*$Title*"}

    #Check for other groups that dont match users title
    $UnexpectedGroups = $Groups | Where-Object {$_ -notlike "*$Title*"}

    if(-not $DeptGroups){
        $AccessStatus = "Access Drift"
        $RecommendedAction = "Review Access: Unauthorized department aligned group access"
    }
    elseif (-not $TitleGroups){
        $AccessStatus = "Drift"
        $RecommendedAction = "Review Access: Unauthorized role aligned group access"
    }
    elseif($UnexpectedGroups){
        $AccessStatus = "Access Drift"
        $RecommendedAction = "Unauthorized additional group found"
    }
    else {
        $AccessStatus = "No Access Drift"
        $RecommendedAction = "RBAC Aligned"
    }

    [PSCustomObject]@{
    Name = $User.Name
    samAccountName = $User.samAccountName
    Title = $Title
    Department = $Department
    AccessStatus = $AccessStatus 
    RecommendedAction = $RecommendedAction
    }
}

$Results | Out-GridView -Title "rbac drift"
$Results | Export-Csv -Path ".\reports\access-drift-audit.csv" -NoTypeInformation