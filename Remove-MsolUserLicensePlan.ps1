function Remove-MsolUserLicensePlan {
 
    param (
        [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$UserPrincipalName,
        [Parameter(Mandatory=$true,Position=1)]
        [string[]]$LicenseName,
        [string]$LogPath = ''
    )
 
    if ($LicenseName.Count -gt 1){
        $LicenseName = $LicenseName -join "|"
    }
    $user = Get-MsolUser -SearchString $UserPrincipalName
    [array]$Licenses = $user.Licenses
    $Licenses = $licenses | Where-Object { $_.AccountSkuId -match "ENTERPRISEPACK"}
    for ( $i = 0 ; $i -lt $Licenses.Count ; $i++ ) {
        <#AssignmentCheck. Required due to some licenses assigned via groups
        $ErrorActionPreference = 'Stop'
        $licenseGroup =  $Licenses[$i].GroupsAssigningLicense
        if ( $licenseGroup -ne $null) {
            try {
                # May break here some time in the future
                Get-MsolGroup -ObjectId $licenseGroup ;
                continue
            } 
            catch {
            }
        }
        #>
        $ErrorActionPreference = 'SilentlyContinue'
        $Plans = $Licenses[$i].ServiceStatus
        [array]$PlanToDisable = $Plans | Where-Object { $_.ServicePlan.ServiceName -match $LicenseName }
        [array]$DisabledPlans = $Plans | Where-Object { $_.ProvisioningStatus -eq 'Disabled' } 
        [array]$DisabledPlans = $DisabledPlans + $PlanToDisable
        $DisabledPlans = ( $DisabledPlans ).ServicePlan.ServiceName
        $EnabledPlansBeforeChange = $Plans | Where-Object { $_.ProvisioningStatus -ne 'Disabled'}
        $EnabledPlansBeforeChange = $EnabledPlansBeforeChange.ServicePlan.ServiceName
        $EnabledPlansAfterChange = $Plans | Where-Object { $_.ProvisioningStatus -ne 'Disabled' -and  $_.ServicePlan.ServiceName -notmatch $LicenseName }
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
        Write-Host "$($LogProperties.Date) - $($LogProperties.Username) - $($LogProperties.LicensesChange)"
    }
}
