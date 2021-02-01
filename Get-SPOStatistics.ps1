$AppId = "37669c56-1d47-4f95-bcec-f02193354c35" #Veeam.GraphAPI.CallStat.Test
$TenantId = "ba07baab-431b-49ed-add7-cbc3542f5140"
$AppSecret = 's_rkvIn1oZ1cNceUBvJ2or1lrrIsb*:='

# Build the request to get the OAuth 2.0 access token
$uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
$body = @{
    client_id     = $AppId
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $AppSecret
    grant_type    = "client_credentials"}

# Request token
$tokenRequest = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing
# Unpack Access Token
$token = ($tokenRequest.Content | ConvertFrom-Json).access_token
$headers = @{Authorization = "Bearer $token"}
$ctype = "application/json"


# Get SharePoint files usage data
$SPOFilesReportsURI = "https://graph.microsoft.com/v1.0/reports/getSharePointSiteUsageDetail(period='D7')"
$Sites = (Invoke-RestMethod -Uri $SPOFilesReportsURI -Headers $Headers -Method Get -ContentType "application/json") -Replace "ï»¿", "" | ConvertFrom-Csv
