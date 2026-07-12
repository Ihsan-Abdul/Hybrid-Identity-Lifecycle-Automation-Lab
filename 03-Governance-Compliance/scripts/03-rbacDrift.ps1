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

    if(-not ($Groups | Where-Object {$_ -like "*$Department*"})) {
    
        $AccessStatus = "Drift"
        $RecommendedAction = "Department mismatch: Review group membership"
    }
    else {
        if($Groups | Where-Object {$_ -like "*$Title*"}) {
        
            $AccessStatus = "No Drift"
            $RecommendedAction = "RBAC aligned"
        }

        else {
            $AccessStatus = "Drift"
            $RecommendedAction = "Title mismatch: Review role group"        
        }
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
$Results | Export-Csv -Path ".\reports\rbac-drift-audit.csv" -NoTypeInformation