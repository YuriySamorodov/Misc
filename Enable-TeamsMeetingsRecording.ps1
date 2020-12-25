<# Script Workflow
- connect to MSOnline service
- import users
- sort users
- disable Stream Trial license
- enable Stream E3 if not enabled
- add user to DSG.O365.Stream.VideoUploaders group
#>
$StreamTrialLicense = Get-MsolAccountSku | Where-Object { $_.AccountSkuId -match ":STREAM$" }
$EnterprisePack = Get-MsolAccountSku | Where-Object { $_.AccountSkuId -match ":ENTERPRISEPACK$" }

function connectMSOnline {
    param (
        [pscredential]$Credential
    )
    $Credential = Get-Credential
    Connect-Msolservice -Credential $Credential
}

connectMSOnline

function Enable-TeamsRecording {
    [CmdletBinding(SupportsShouldProcess=$True)]
    param (
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [alias('DisplayName','Name','UserPrincipalName')]
        $Identity
    )
    $ErrorActionPreference = 'Stop'
    $User = Get-MsolUser -SearchString $Identity
    $EnterprisePack = $user.Licenses | Where-Object { $_.AccountSkuId -match ":ENTERPRISEPACK$"}
    $Plans = $EnterprisePack.ServiceStatus
    $DisabledPlans = $Plans | Where-Object { $_.ProvisioningStatus -eq 'Disabled' }
    $DisabledPlans = $DisabledPlans | Where-Object { $_.ServicePlan.ServiceName -notmatch "TEAMS|STREAM" }
    $DisabledPlans = $DisabledPlans.ServicePlan.ServiceName
    $LicenseOptionProperties = @{
        AccountSkuId = $EnterprisePack.AccountSkuId
        DisabledPlans = $DisabledPlans
    }
    $LicenseOption = New-MsolLicenseOptions @LicenseOptionProperties
    if ($PSCmdlet.ShouldProcess($user.UserPrincipalName,'Enable meeting recording in Teams')){
        try {
            Set-MsolUserLicense -UserPrincipalName $User.UserPrincipalName -RemoveLicenses $StreamTrialLicense.AccountSkuId
            Write-Verbose "Disabled $($StreamTrialLicense.AccountSkuId) for $($user.UserPrincipalName)"
        }

        catch {}
        
        finally {
            Set-MsolUserLicense -UserPrincipalName $User.UserPrincipalName -LicenseOptions $LicenseOption
            Write-Verbose "Enabled MS Teams for $($user.UserPrincipalName)" 
        }
    }       
}