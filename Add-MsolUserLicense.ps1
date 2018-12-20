function Add-MsolUserLicense {
 
    param (
        [object[]]$Identity,
        [string[]]$GroupName,
        [string[]]$LicenseName = 'Stream',
        [string[]]$LogName = 'Stream'
    )
 
    if ($Licenses.Count -gt 1){
        $Licenses = $Licenses -join "|"
    }
 
    

    for ($g = 0 ; $g -lt $GroupName.Count ; $g++ ) {
        $group = Get-MsolGroup -SearchString $GroupName[$g]
        [array]$users = Get-MsolGroupMember -GroupObjectId $group.ObjectId -All
        [array]$users = $users | Get-MsolUser
 
        for ( $i = 0 ; $i -lt 1 ; $i++  ) {
            [array]$Licenses = $users[$i].Licenses
            for ( $l = 0 ; $l -lt $Licenses.Count ; $l++ ) {
                $Plans = $Licenses[$l].ServiceStatus
                $DisabledPlans = $Plans | Where-Object { $_.ProvisioningStatus -eq 'Disabled' } 
                $DisabledPlans = $DisabledPlans | Where-Object { $_.ServicePlan.ServiceName -notmatch $LicenseName }
                $DisabledPlans = ( $DisabledPlans ).ServicePlan.ServiceName
                $LO = New-MsolLicenseOptions -AccountSkuId $Licenses[$l].AccountSkuId -DisabledPlans $DisabledPlans
                $LogProperties = [ordered]@{
                    'Username' = $users[$i].UserPrincipalName
                    'AccountSku' = $Licenses[$l].AccountSkuId
                    'DisabledPlans' = $DisabledPlans -join ","
                }
                $Log = New-Object -TypeName PSObject -Property $LogProperties
                $Log | export-csv -NoTypeInformation ~\Downloads\TeamsEnablement.csv -Append
                Set-MsolUserLicense -UserPrincipalName $users[$i].UserPrincipalName -LicenseOptions $LO
            }
        }
    }
}