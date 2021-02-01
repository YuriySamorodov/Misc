$AdminUrl = 'https://veeamsoftwarecorp-admin.sharepoint.com'
$SystemItemCount = 271 #( Get-PnPList ).ItemCount | Measure -Sum
function Connect-PnPSite {
    [CmdletBinding()]
    param (
        $Url
    )
    $Params = [ordered]@{
        TenantAdminUrl = $AdminUrl
        Thumbprint = '3bc79c67f5d68abbdae90760c57d4e8cd3b2ea12'
        ReturnConnection = $true
        ClientId = '15460790-5201-4749-ac72-7812b8d8bffd';
        Tenant = 'ba07baab-431b-49ed-add7-cbc3542f5140'
    }
    Connect-PnPOnline @PSBoundParameters @Params
    $PnPConnection = Get-PnPConnection
}

$PnPConnectionAdmin = Connect-PnPSite -Url $AdminUrl 


$PnPTenantSites = Get-PnPTenantSite -Connection $PnPConnectionAdmin
$PnPTenantSitesExternal = $PnPTenantSites | where { $_.SharingCapability -ne 'Disabled'}


foreach ( $PnPSite in $PnPTenantSitesExternal ) {
    Write-Host "Connecting to $($PnPSite.Url)" -ForegroundColor Yellow
    $PnPConnectionSite = Connect-PnPSite -Url $PnPSite.Url 
    $PnPSite = Get-PnPSite -Connection $PnPConnectionSite -Includes RootWeb, UserCustomActions
    if ( $PnPSite.UserCustomActionsю.Count -gt 0  ) {
        $PnPSite
    }
}