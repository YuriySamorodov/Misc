function Connect-PnPSite {
    [CmdletBinding()]
    param (
        $Url
    )

    $Params = [ordered]@{
        TenantAdminUrl = $AdminUrl
        Thumbprint = '3bc79c67f5d68abbdae90760c57d4e8cd3b2ea12'
        ReturnConnection = $true
        ClientId = '15460790-5201-4749-ac72-7812b8d8bffd'
        Tenant = 'ba07baab-431b-49ed-add7-cbc3542f5140'
    }
    Connect-PnPOnline @PSBoundParameters @Params
}

Connect-PnPSite -Url $AdminUrl | Out-Null
$PnPConnection = Get-PnPConnection