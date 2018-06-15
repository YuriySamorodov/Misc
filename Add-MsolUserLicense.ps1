$cred = Get-Credential
Connect-MsolService -Credential $cred

function Add-MsolUserLicense {

    param (
        [string[]]$GroupName,
        [string[]]$Licenses = 'Stream'
    )

    if ($Licenses.Count -gt 1){
        $Licenses = $Licenses -join "|"
    }

    for ($g = 0 ; $g -lt $GroupName.Count ; $g++ ) {
        $group = Get-MsolGroup -SearchString $GroupName[$g]
        $users = Get-MsolGroupMember -GroupObjectId $group.ObjectId -All
        $users = $users | Get-MsolUser

        for ( $i = 0 ; $i -lt $users.Count ; $i++  ) {
            $License = $users[$i].Licenses
            $Plans = $License | Select-Object -ExpandProperty ServiceStatus
            $DisabledPlans = $Plans | Where-Object { $_.ServicePlan.ServiceName -notmatch $Licenses -and $_.ProvisioningStatus -eq 'Disabled' } 
            $DisabledPlans = ( $DisabledPlans ).ServicePlan.ServiceName
            $LO = New-MsolLicenseOptions -AccountSkuId $License.AccountSkuId -DisabledPlans $DisabledPlans
            Set-MsolUserLicense -UserPrincipalName $users[$i].UserPrincipalName -LicenseOptions $LO
        }
    }
}
