param (
    [Parameter(Mandatory=$True)][string]$WorkspaceName,
    [Parameter(Mandatory=$True)][string]$ResourceGroupName,
    [Parameter(Mandatory=$True)][string]$SubscriptionId,
    [Parameter(Mandatory=$True)][string]$OfficeUsername,
    [Parameter(Mandatory=$True)][string]$OfficeTennantId,
    [Parameter(Mandatory=$True)][string]$OfficeClientId,
    [Parameter(Mandatory=$True)][string]$OfficeClientSecret
)
$line='#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
$line
IF ($Subscription -eq $null)
    {Login-AzAccount -ErrorAction Stop}
$Subscription = (Select-AzSubscription -SubscriptionId $($SubscriptionId) -ErrorAction Stop)
$Subscription
$option = [System.StringSplitOptions]::RemoveEmptyEntries 
$Workspace = (Set-AzOperationalInsightsWorkspace -Name $($WorkspaceName) -ResourceGroupName $($ResourceGroupName) -ErrorAction Stop)
$Workspace
$WorkspaceLocation= $Workspace.Location
$OfficeClientSecret =[uri]::EscapeDataString($OfficeClientSecret)

# Client ID for Azure PowerShell
$clientId = "1950a258-227b-4e31-a9cf-717495945fc2"
# Set redirect URI for Azure PowerShell
$redirectUri = "urn:ietf:wg:oauth:2.0:oob"
$domain='login.microsoftonline.com'
$adTenant = $Subscription[0].Tenant.Id
$authority = "https://login.windows.net/$adTenant";
$ARMResource ="https://management.azure.com/";
$xms_client_tenant_Id ='55b65fb5-b825-43b5-8972-c8b6875867c1'

switch ($WorkspaceLocation) {
       "USGov Virginia" { 
                         $domain='login.microsoftonline.us';
                          $authority = "https://login.microsoftonline.us/$adTenant";
                          $ARMResource ="https://management.usgovcloudapi.net/"; break} # US Gov Virginia
       default {
                $domain='login.microsoftonline.com'; 
                $authority = "https://login.windows.net/$adTenant";
                $ARMResource ="https://management.azure.com/";break} 
                }

Function RESTAPI-Auth { 

$global:SubscriptionID = $Subscription.SubscriptionId
# Set Resource URI to Azure Service Management API
$resourceAppIdURIARM=$ARMResource;
# Authenticate and Acquire Token 
# Create Authentication Context tied to Azure AD Tenant
$authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
# Acquire token
$global:authResultARM = $authContext.AcquireTokenSilent($resourceAppIdURIARM, $clientId, $redirectUri, "Auto")
$authHeader = $global:authResultARM.CreateAuthorizationHeader()
$authHeader
}

Function Failure {
$line
$formatstring = "{0} : {1}`n{2}`n" +
                "    + CategoryInfo          : {3}`n" +
                "    + FullyQualifiedErrorId : {4}`n"
$fields = $_.InvocationInfo.MyCommand.Name,
          $_.ErrorDetails.Message,
          $_.InvocationInfo.PositionMessage,
          $_.CategoryInfo.ToString(),
          $_.FullyQualifiedErrorId

$formatstring -f $fields
$_.Exception.Response

$line
break
}

Function Connection-API
{
$authHeader = $global:authResultARM.CreateAuthorizationHeader()
$ResourceName = "https://manage.office.com"
$SubscriptionId   =  $Subscription[0].Subscription.Id

$line
$connectionAPIUrl = $ARMResource + 'subscriptions/' + $SubscriptionId + '/resourceGroups/' + $ResourceGroupName + '/providers/Microsoft.OperationalInsights/workspaces/' + $WorkspaceName + '/connections/office365connection_' + $SubscriptionId + $OfficeTennantId + '?api-version=2017-04-26-preview'
$connectionAPIUrl
$line

$xms_client_tenant_Id ='1da8f770-27f4-4351-8cb3-43ee54f14759'

$BodyString = "{
                'properties': {
                                'AuthProvider':'Office365',
                                'clientId': '" + $OfficeClientId + "',
                                'clientSecret': '" + $OfficeClientSecret + "',
                                'Username': '" + $OfficeUsername   + "',
                                'Url': 'https://$($domain)/" + $OfficeTennantId + "/oauth2/token',
                              },
                'etag': '*',
                'kind': 'Connection',
                'solution': 'Connection',
               }"

$params = @{
    ContentType = 'application/json'
    Headers = @{
    'Authorization'="$($authHeader)"
    'x-ms-client-tenant-id'=$xms_client_tenant_Id #Prod-'1da8f770-27f4-4351-8cb3-43ee54f14759'
    'Content-Type' = 'application/json'
    }
    Body = $BodyString
    Method = 'Put'
    URI = $connectionAPIUrl
}
$response = Invoke-WebRequest @params 
$response
$line

}

Function Office-Subscribe-Call{
try{
#----------------------------------------------------------------------------------------------------------------------------------------------
$authHeader = $global:authResultARM.CreateAuthorizationHeader()
$SubscriptionId   =  $Subscription[0].Subscription.Id
$OfficeAPIUrl = $ARMResource + 'subscriptions/' + $SubscriptionId + '/resourceGroups/' + $ResourceGroupName + '/providers/Microsoft.OperationalInsights/workspaces/' + $WorkspaceName + '/datasources/office365datasources_' + $SubscriptionId + $OfficeTennantId + '?api-version=2015-11-01-preview'

$OfficeBodyString = "{
                'properties': {
                                'AuthProvider':'Office365',
                                'office365TenantID': '" + $OfficeTennantId + "',
                                'connectionID': 'office365connection_" + $SubscriptionId + $OfficeTennantId + "',
                                'office365AdminUsername': '" + $OfficeUsername + "',
                                'contentTypes':'Audit.Exchange,Audit.AzureActiveDirectory,Audit.SharePoint'
                              },
                'etag': '*',
                'kind': 'Office365',
                'solution': 'Office365',
               }"

$Officeparams = @{
    ContentType = 'application/json'
    Headers = @{
    'Authorization'="$($authHeader)"
    'x-ms-client-tenant-id'=$xms_client_tenant_Id
    'Content-Type' = 'application/json'
    }
    Body = $OfficeBodyString
    Method = 'Put'
    URI = $OfficeAPIUrl
  }

$officeresponse = Invoke-WebRequest @Officeparams 
$officeresponse
}
catch{ Failure }
}

#GetDetails 
RESTAPI-Auth -ErrorAction Stop
Connection-API -ErrorAction Stop
Office-Subscribe-Call -ErrorAction Stop