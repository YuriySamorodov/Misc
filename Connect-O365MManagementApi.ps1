# Create app of type Web app / API in Azure AD, generate a Client Secret, and update the client id and client secret here
$ClientID = "35f84493-f126-4791-95da-92579f0ee984"
$ClientSecret = "IjJD/.fuJ:XENwBPfN>}+R;fCATwVGEca6s*N&Sl8"
$loginURL = "https://login.microsoftonline.com/"
$tenantdomain = "veeamsoftwarecorp.onmicrosoft.com"
# Get the tenant GUID from Properties | Directory ID under the Azure Active Directory section
$TenantGUID = "ba07baab-431b-49ed-add7-cbc3542f5140"
$resource = "https://manage.office.com"
# auth
$body = @{grant_type="client_credentials";resource=$resource;client_id=$ClientID;client_secret=$ClientSecret}
$oauth = Invoke-RestMethod -Method Post -Uri $loginURL/$tenantdomain/oauth2/token?api-version=1.0 -Body $body
$headerParams = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"}