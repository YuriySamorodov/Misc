#Example of your site collection: https://veeamsoftwarecorp.sharepoint.com/sites/Team.Sales.Partner.VMCEA.EMEA.Germany


function Add-SPOExternalBanner {
    param (
        [pscredential]$Credentials = '',
        [string]$siteUrl = ''
    )
    
$credentials = Get-Credential

# details of sites
[string[]] $sitesToProcess = $siteUrl #через запятую перечислять сайт-коллекции.

# details of custom action/SPFx extension
[guid]$spfxExtension_GlobalHeaderID = "7ad4348c-1367-461d-a343-842a95c616bb"
[string]$spfxExtName = "veeam-spo-announcements-bar"
[string]$spfxExtTitle = "veeam-spo-announcements-bar"
[string]$spfxExtDescription = "Adds a global header/footer to the site"
[string]$spfxExtLocation = "ClientSideExtension.ApplicationCustomizer"
[string]$spfxExtProperites = "{""siteUrl"":""$siteUrl"", ""listName"" : ""Announcements""}"

function Add-PnPCustomActionForSPFxExt ([string]$url, [Microsoft.SharePoint.Client.ClientContext]$clientContext) {
Write-Output "-- About to add custom action to: $url"

# NOTE - using direct CSOM here (rather than Add-PnPCustomAction) for now, due to https://github.com/SharePoint/PnP-PowerShell/issues/1048
$rootWeb = $clientContext.Web
$clientContext.ExecuteQuery()
$customActions = $rootWeb.UserCustomActions
$clientContext.Load($customActions)
$clientContext.ExecuteQuery()

$custAction = $customActions.Add()
$custAction.Name = $spfxExtName
$custAction.Title = $spfxExtTitle
$custAction.Description = $spfxExtDescription
$custAction.Location = $spfxExtLocation
$custAction.ClientSideComponentId = $spfxExtension_GlobalHeaderID
$custAction.ClientSideComponentProperties = $spfxExtProperites

$custAction.Update()
$clientContext.ExecuteQuery()

Write-Output "-- Successfully added extension"
Write-Output "Processed: $url"
}

function Remove-CustomActionForSPFxExt ([string]$extensionName, [string]$url, [Microsoft.SharePoint.Client.ClientContext]$clientContext) {
Write-Output "-- About to remove custom action with name '$($extensionName)' from: $url"

$actionsToRemove = Get-PnPCustomAction -Web $clientContext.Web | Where-Object {$_.Location -eq "ClientSideExtension.ApplicationCustomizer" -and $_.Name -eq $extensionName }
Write-Output "-- Found $($actionsToRemove.Count) extensions with name $extensionName on this web." 
foreach ($action in $actionsToRemove) {
Remove-PnPCustomAction -Identity $action.Id
Write-Output "-- Successfully removed extension $extensionName from web $url." 
}

Write-Output "Processed: $url"
}

# -- end functions --

foreach ($site in $sitesToProcess) {
$authenticated = $false
$ctx = $null
try {
Connect-PnPOnline -Url $site -Credentials $credentials
Write-Output ""
Write-Output "Authenticated to: $site"
$ctx = Get-PnPContext
}
catch {
Write-Error "Failed to authenticate to $site"
Write-Error $_.Exception
}

if ($ctx) {
# TODO - comment in/out method calls here as you need..
Add-PnPCustomActionForSPFxExt $site $ctx
# Remove-CustomActionForSPFxExt $spfxExtName $site $ctx
Get-PnPCustomAction -Web $ctx.Web | Where-Object {$_.Location -eq "ClientSideExtension.ApplicationCustomizer" }
}
}
}