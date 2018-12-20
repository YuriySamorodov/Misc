<# Script Workflow
- connect to MSOnline service
- import users
- sort users
- disable Stream Trial license
- enable Stream E3 if not enabled
- add user to DSG.O365.Stream.VideoUploaders group
#>

function connectMSOnline {
    param (
        [pscredential]$Credential
    )
    $Credential = Get-Credential
    Connect-Msolservice -Credential $Credential
}

connectMSOnline

function enableTeamsMeetingRecording {
    param (
        
    )
    
    #remove Stream Trial License VeeamSoftwareCorp:STREAM
    $StreamTrialLicense = Get-MsolAccountSku | Where-Object { $_.AccountSkuId -match ":STREAM$" }
    $EnterprisePack = Get-MsolAccountSku | Where-Object { $_.AccountSkuId -match ":ENTERPRISEPACK$" }
    $Plans = $EnterprisePack.ServiceStatus
    $DisabledPlans = $Plans | Where-Object { $_.ProvisioningStatus -eq 'Disabled' }
    $DisabledPlans = $DisabledPlans | Where-Object { $_.ServicePlan.ServiceName -notmatch "STREAM" }
    $LicenseOptionProperties = @{
        AccountSkuId = $EnterprisePack.AccountSkuId
        DisabledPlans = $DisabledPlans
    }
    $LicenseOption = New-MsolLicenseOptions @LicenseOptionProperties
    
    $SetMsolUserLicenseProperties = @{
        UserPrincipalName = 'yuriy.samorodov@veeam.com'
        RemoveLicenses = $StreamTrialLicense
        LicenseOptions = $LicenseOption
    }
    #Set-MsolUserLicense @SetMsolUserLicenseProperties
    Set-MsolUserLicense -UserPrincipalName 'yuriy.samorodov@veeam.com' -RemoveLicenses $StreamTrialLicense -LicenseOptions $LicenseOption
    
}