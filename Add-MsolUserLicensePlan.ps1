function Add-MsolUserLicensePlan {
 
    param (
        [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$UserPrincipalName,
        [string[]]$LicenseName = '',
        [string]$LogPath = 'Stream'
    )
 
    if ($LicenseName.Count -gt 1){
        $LicenseName = $LicenseName -join "|"
    }
    $user = Get-MsolUser -SearchString $UserPrincipalName
    [array]$Licenses = $user.Licenses
    for ( $i = 0 ; $i -lt $Licenses.Count ; $i++ ) {
        [array]$Plans = $Licenses[$i].ServiceStatus
        [array]$DisabledPlans = $Plans | Where-Object { $_.ProvisioningStatus -eq 'Disabled' } 
        [array]$DisabledPlans = $DisabledPlans | Where-Object { $_.ServicePlan.ServiceName -notmatch $LicenseName }
        $DisabledPlans = ( $DisabledPlans ).ServicePlan.ServiceName
        $EnabledPlansBeforeChange = $Plans | Where-Object { $_.ProvisioningStatus -ne 'Disabled'}
        $EnabledPlansBeforeChange = $EnabledPlansBeforeChange.ServicePlan.ServiceName
        $EnabledPlansAfterChange = $Plans | Where-Object { $_.ProvisioningStatus -ne 'Disabled' -or $_.ServicePlan.ServiceName -match $LicenseName }
        $EnabledPlansAfterChange = $EnabledPlansAfterChange.ServicePlan.ServiceName
        if ( $EnabledPlansAfterChange.Count -ne $EnabledPlansBeforeChange.Count ) {
            $LicensesChange = $true
        } 
        else { $LicensesChange = $false }

        $LO = New-MsolLicenseOptions -AccountSkuId $Licenses[$i].AccountSkuId -DisabledPlans $DisabledPlans
        $LogProperties = [ordered]@{
            'Date' = Get-Date -f "yyy-MM-dd HH:mm:ss"
            'Username' = $user.UserPrincipalName
            'AccountSku' = $Licenses[$i].AccountSkuId
            'PlansBeforeChange' = $EnabledPlansBeforeChange -join ","
            'PlansAfterChange' = $EnabledPlansAfterChange -join ","
            'DisabledPlans' = $DisabledPlans -join ","
            'LicensesChange' = $LicensesChange
        }
        $Log = New-Object -TypeName PSObject -Property $LogProperties
        $Log | export-csv -NoTypeInformation $LogPath -Append -Force
        Set-MsolUserLicense -UserPrincipalName $user.UserPrincipalName -LicenseOptions $LO
    }
}
