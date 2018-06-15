
$cred = Get-Credential
Connect-MsolService -Credential $cred
$group = Get-MsolGroup -SearchString "Team.SE.VeeamExpo2018"
$users = Get-MsolGroupMember -GroupObjectId $group.ObjectId 

for ( $i = 0 ; $i -lt $users.Count ; $i++  ) {
    $License = $users
    foreach ( $License in $users[$i].Licenses ) {
        $Plans = $License | Select-Object -ExpandProperty ServiceStatus
        $DisabledPlans = $Plans | Where-Object { $_.ServicePlan.ServiceName -eq $DisablePlans -or $_.ProvisioningStatus -eq 'Disabled' } 
        $DisabledPlans = ( $DisabledPlans ).ServicePlan.ServiceName
        $LO = New-MsolLicenseOptions -AccountSkuId $License.AccountSkuId -DisabledPlans $DisabledPlans
        Set-MsolUserLicense -UserPrincipalName $user.UserPrincipalName -LicenseOptions $LO
    }
}
