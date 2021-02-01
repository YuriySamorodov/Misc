<# SharePoint Online External Sharing Chreck
Author: Yuriy Samorodov
#>

function Import-PnPModule ($Name) {
    if ( Get-Module -Name $Name -ListAvailable ) {
        Import-Module $Name
    } else { 
        $InstallModuleProperties = @{
            Name = $Name
            Scope = 'AllUsers'
            AllowPreRelease = $true
        }
        Install-Module @InstallModuleProperties}
}

Import-PnPModule -Name PnP.PowerShell

function Connect-PnPService {
    param (
        $Url,
        $ClientId = '15460790-5201-4749-ac72-7812b8d8bffd',
        $Thumbprint = 'EE242853A1DD12A93595012E003C35EA96C4E70E',
        $TenantId = 'ba07baab-431b-49ed-add7-cbc3542f5140'
    )
    $PnPConnectProperties = @{
        Url = $Url 
        ClientId = $ClientId
        Thumbprint = $Thumbprint
        Tenant = $TenantId
        ReturnConnection = $true
    }    
    Connect-PnPOnline @PnPConnectProperties
}

$PnPConnectionAdmin = Connect-PnPService -Url https://veeamsoftwarecorp-admin.sharepoint.com
$Sites = Get-PnPTenantSite
#Get SPO sites associated with Private Channels in Teams
$SitesPrivateChannels = $sites | Where-Object { $_.Template -eq 'TEAMCHANNEL#0' }
$SitesPrivateChannelsExternal = $SitesPrivateChannels | Where-Object { $_.SharingCapability -notmatch "Disabled"}
Disconnect-PnPOnline

for ($i = 0 ; $i -lt $SitesPrivateChannelsExternal.Count ; $i++ ) {
    $PnPConnection = Connect-PnPSe $srvice -Url $SitesPrivateChannelsExternal[$i].Url
    $web = Get-PnPWeb -Includes Created, UserCustomActions, Author, Configuration
    $OwnerUPN = $web.Author.LoginName.Split('\|')[2]
    $OwnerStateCheck = Get-PnPAADUser -Filter "startswith(UserPrincipalName,'$($OwnerUPN)' ) and AccountEnabled eq true" -Connection $PnPConnection
    $OwnerEnabled = if ($OwnerStateCheck) {
        $true
    } else {
        $false
    }
    #$ctx = Get-PnPContext
    $objProperties = [ordered]@{
        Url = $PnPConnection.url
        Title = $SitesPrivateChannelsExternal[$i].Title
        StorageQuota = $SitesPrivateChannelsExternal[$i].StorageMaximumLevel
        StorageUsage = $SitesPrivateChannelsExternal[$i].StorageUsage
        Created = $web.Created
        Owner = $SitesPrivateChannelsExternal[$i].Owner
        Author = $web.Author.Email
        OwnerEnabled = $OwnerEnabled
        Banner = $web.UserCustomActions
    }
    $obj = New-Object psobject -Property $objProperties
    Write-Output $obj
}