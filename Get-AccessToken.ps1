function Get-AccessToken { 
    <#

    .SYNOPSIS

    Created by: https://ingogegenwarth.wordpress.com/
    Version:    1.0.0.0 42 ("What do you get if you multiply six by nine?")
    Changed:    10.09.2020

    .LINK
    https://docs.microsoft.com/en-us/azure/active-directory/develop/
    https://techcommunity.microsoft.com/t5/Azure-Active-Directory-Identity/Simplifying-our-Azure-AD-Authentication-Flows/ba-p/243928
    https://docs.microsoft.com/en-us/azure/architecture/multitenant-identity/client-assertion
    https://developer.microsoft.com/en-us/graph/docs/concepts/auth_v2_user
    https://tools.ietf.org/rfc/rfc6749.txt
    https://blogs.msdn.microsoft.com/aaddevsup/2018/04/18/query-string-is-not-allowed-in-redirect_uri-for-azure-ad/
    https://tools.ietf.org/html/rfc6819#section-5.2.3.5
    https://ingogegenwarth.wordpress.com/2019/03/07/oauth-get-accesstoken/

    .DESCRIPTION

    The purpose of the script is to retrieve an AcceesToken from AzureAD. There script supports several flows.

    .PARAMETER UserPrincipalName

    Username to prepopulate when using ADAL

    .PARAMETER ADALPath

    Path to Microsoft.IdentityModel.Clients.ActiveDirectory DLL

    .PARAMETER ClientId

    Application ID of the registered app

    .PARAMETER Resource

    The resource you want the AccessToken for. It is also known as the audience(aud) of a token.

    .PARAMETER RedirectUri

    This can be used for entering either "Sign-On URL" for "Web app/API" or "Redirect URI" for "Native" application.

    .PARAMETER PromptBehavior

    The ADAL's PromptBehavior. Always, Auto, Never or RefreshSession are valid values. Default is Auto.

    .PARAMETER TokenForResourceExists

    Switch to check whether a token for specific resource exists in your ADAL cache.

    .PARAMETER Certificate

    The certificate, which is used for Client Credentials flow.

    .PARAMETER Credential

    PS credential object for acquiring a token.

    .PARAMETER ClientSecret

    The secret, which is used for Client Credentials flow.

    .PARAMETER ClientIdOBO

    Application ID of the registered app in the On-Behalf-Of flow.

    .PARAMETER ClientSecretOBO

    The secret, which is used in the On-Behalf-Of flow.

    .PARAMETER ResourceOBO

    The resource/audience in the On-Behalf-Of flow.

    .PARAMETER Authority

    The authority from where you get the token.

    .PARAMETER ClearTokenCache

    Clear ADAL cache in order to retrieve a new token. ADAL checks whether you have a token or not before acquiring a new one. This can be helpful for debugging.

    .PARAMETER UseImplicitFlow

    Switch for implicit flow.

    .PARAMETER UseAuthCodeFlow

    Switch for AuthCode flow.

    .PARAMETER UseOnBehalfOfFlow

    Switch for OBO flow.

    .PARAMETER AuthPrompt

    When using either Implicit or AuthCode flow, you can set the prompt. login, select_account, consent, admin_consent and none are valid values. Default is none.

    .PARAMETER ParseToken

    Switch for parsing the AccessToken.

    .PARAMETER Tenant

    Required when using Implicit or AuthCode flow.

    .PARAMETER AccessToken

    If you want to parse an existing AccessToken, just provide the value of the token to this parameter.


    .NOTES
    #>

    [CmdletBinding()]
    Param
    (
        [System.String]
        $UserPrincipalName,

        [System.String]
        $ADALPath,

        [System.String]
        $ClientId,

        [System.Uri]
        $Resource,

        [System.Uri]
        $RedirectUri,

        [ValidateSet('Always','Auto','Never','RefreshSession')]
        [System.String]
        $PromptBehavior = 'Auto',

        [System.Management.Automation.SwitchParameter]
        $TokenForResourceExists,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,

        [System.Management.Automation.PsCredential]
        $Credential,

        [System.String]
        $ClientSecret,

        [System.String]
        $ClientIdOBO,

        [System.String]
        $ClientSecretOBO,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $CertificateOBO,

        [System.Uri]
        $ResourceOBO,

        [System.Uri]
        $Authority,

        [System.Management.Automation.SwitchParameter]
        $ClearTokenCache,

        [System.Management.Automation.SwitchParameter]
        $UseImplicitFlow,

        [System.Management.Automation.SwitchParameter]
        $UseAuthCodeFlow,

        [System.Management.Automation.SwitchParameter]
        $UseOnBehalfOfFlow,

        [ValidateSet('login','select_account','consent','admin_consent','none')]
        [System.String]
        $AuthPrompt = 'none',

        [System.Management.Automation.SwitchParameter]
        $ParseToken,

        [System.String]
        $Tenant,

        [System.String]
        $AccessToken,

        [System.Management.Automation.SwitchParameter]
        $Silent
    )

    Begin
    {

        If (-not $AccessToken)
        {
            try
            {
                If([System.String]::IsNullOrEmpty($ADALPath))
                {
                    #$ADALPath = [System.IO.Path]::Combine((Get-Module -Name ExchangeOnlineManagement -ListAvailable -Verbose:$false | select -First 1).ModuleBase,"Microsoft.IdentityModel.Clients.ActiveDirectory.dll")
                    $ADALPath = (Get-Module -Name ExchangeOnlineManagement -ListAvailable -Verbose:$false | select -First 1).FileList -match "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
                }
                Import-Module $ADALPath -Force
            }
            catch
            {
                #create object
                $returnValue = New-Object -TypeName PSObject
                #get all properties from last error
                $ErrorProperties = $Error[0] | Get-Member -MemberType Property
                #add existing properties to object
                foreach ($Property in $ErrorProperties)
                {
                    if ($Property.Name -eq 'InvocationInfo')
                    {
                        $returnValue | Add-Member -Type NoteProperty -Name 'InvocationInfo' -Value $($Error[0].InvocationInfo.PositionMessage)
                    }
                    else
                    {
                        $returnValue | Add-Member -Type NoteProperty -Name $($Property.Name) -Value $($Error[0].$($Property.Name))
                    }
                }
                #return object
                $returnValue
                break
            }

            # check for On-Behalf-Of flow (OBO)
            If (-not [System.String]::IsNullOrEmpty($ClientIdOBO))
            {
                [System.Boolean]$UseOnBehalfOfFlow = $true
            }
            # sanity check for a few parameters
            If (($UseOnBehalfOfFlow -and -not $ClientSecretOBO) -and ($UseOnBehalfOfFlow -and -not $CertificateOBO))
            {
                Write-Output "Cancle OBO request due to missing data (no ClientSecretOBO or CertificateOBO)..."
                break
            }

            If (($UseAuthCodeFlow -and -not $Tenant) -or ($UseImplicitFlow -and -not $Tenant))
            {
                Write-Output "Tenant is required for AuthCodeFlow/UseImplicitFlow..."
                break
            }
        }

        function Get-AADAuth
        {
            [CmdletBinding()]
            Param
            (
                [System.Uri]
                $Authority,

                [System.String]
                $Tenant,

                [System.String]
                $Client_ID,

                [ValidateSet("code","token")]
                [System.String]
                $Response_Type = 'code',

                [System.Uri]
                $Redirect_Uri,

                [ValidateSet("query","fragment")]
                [System.String]
                $Response_Mode,

                [System.String]
                $State,

                [System.String]
                $Resource,

                [System.String]
                $Scope,

                [ValidateSet("login","select_account","consent","admin_consent","none")]
                [System.String]
                $Prompt,

                [System.String]
                $Login_Hint,

                [System.String]
                $Domain_Hint,

                [ValidateSet("plain","S256")]
                [System.String]
                $Code_Challenge_Method,

                [System.String]
                $Code_Challenge,

                [System.Management.Automation.SwitchParameter]
                $V2
            )

            Begin
            {
                Add-Type -AssemblyName System.Web

                If ($V2)
                {
                    $OAuthSub = '/oauth2/v2.0/authorize?'
                }
                Else
                {
                    $OAuthSub = '/oauth2/authorize?'
                }

                #create autorithy Url
                $AuthUrl = $Authority.AbsoluteUri + $Tenant + $OAuthSub
                Write-Verbose -Message "AuthUrl:$($AuthUrl)"

                #create empty body variable
                $Body = @{}
                $Url_String = ''

                Function Show-OAuthWindow
                {
                    [CmdletBinding()]
                    param(
                        [System.Uri]
                        $Url,
        
                        [ValidateSet("query","fragment")]
                        [System.String]
                        $Response_Mode
                    )

                    Write-Verbose "Show-OAuthWindow Url:$($Url)"
                    Add-Type -AssemblyName System.Windows.Forms

                    $global:form = New-Object -TypeName System.Windows.Forms.Form -Property @{Width=440;Height=640}
                    $global:web  = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Width=420;Height=600;Url=($url ) }
                    $DocComp  = {
                        $Global:uri = $web.Url.AbsoluteUri
                        if ($Global:Uri -match "error=[^&]*|code=[^&]*|code=[^#]*|#access_token=*")
                        {
                            $form.Close()
                        }
                    }

                    $web.ScriptErrorsSuppressed = $true
                    $web.Add_DocumentCompleted($DocComp)
                    $form.Controls.Add($web)
                    $form.Add_Shown({$form.Activate()})
                    $form.ShowDialog() | Out-Null

                    switch ($Response_Mode)
                    {
                        "query"     {$UrlToBeParsed = $web.Url.Query}
                        "fragment"  {$UrlToBeParsed = $web.Url.Fragment}
                        "form_post" {$UrlToBeParsed = $web.Url.Fragment}
                    }

                    $queryOutput = [System.Web.HttpUtility]::ParseQueryString($UrlToBeParsed)
                    $global:result = $web
                    $output = @{}
                    foreach($key in $queryOutput.Keys){
                        $output["$key"] = $queryOutput[$key]
                    }
        
                    $output
                }
            }

            Process
            {
                $Params = $PSBoundParameters.GetEnumerator() | Where-Object -FilterScript {$_.key -inotmatch 'Verbose|v2|authority|tenant|Redirect_Uri'}
                foreach ($Param in $Params)
                {
                    Write-Verbose -Message "$($Param.Key)=$($Param.Value)"
                    $Url_String += "&" + $Param.Key + '=' + [System.Web.HttpUtility]::UrlEncode($Param.Value)
                }

                If ($Redirect_Uri)
                {
                    $Url_String += "&Redirect_Uri=$Redirect_Uri"
                }
                $Url_String = $Url_String.TrimStart("&")
                Write-Verbose "RedirectURI:$($Redirect_Uri)"
                Write-Verbose "URL:$($Url_String)"
                $Response = Show-OAuthWindow -Url $($AuthUrl + $Url_String) -Response_Mode $Response_Mode
            }

            End
            {
                If ($Response.Count -gt 0)
                {
                    $Response
                }
                Else
                {
                    Write-Verbose "Error occured"
                    Add-Type -AssemblyName System.Web
                    [System.Web.HttpUtility]::UrlDecode($result.Url.OriginalString)
                }
            }
        }

        #https://www.michev.info/Blog/Post/2140/decode-jwt-access-and-id-tokens-via-powershell
        function Parse-JWTtoken
        {

            [cmdletbinding()]
            param(
                [Parameter(
                Mandatory=$true)]
                [System.String]
                $token
            )

            #Validate as per https://tools.ietf.org/html/rfc7519
            #Access and ID tokens are fine, Refresh tokens will not work
            if (!$token.Contains(".") -or !$token.StartsWith("eyJ")){ Write-Error "Invalid token" -ErrorAction Stop }

            #Header
            $tokenheader = $token.Split(".")[0]
            #Fix padding as needed, keep adding "=" until string length modulus 4 reaches 0
            while ($tokenheader.Length % 4) { Write-Verbose "Invalid length for a Base-64 char array or string, adding ="; $tokenheader += "=" }
            Write-Verbose "Base64 encoded (padded) header:"
            Write-Verbose $tokenheader
            #Convert from Base64 encoded string to PSObject all at once
            Write-Verbose "Decoded header:"
            #[System.Text.Encoding]::ASCII.GetString([system.convert]::FromBase64String($tokenheader)) | ConvertFrom-Json | Out-Default

            #Payload
            $tokenPayload = $token.Split(".")[1]
            #Fix padding as needed, keep adding "=" until string length modulus 4 reaches 0
            while ($tokenPayload.Length % 4) { Write-Verbose "Invalid length for a Base-64 char array or string, adding ="; $tokenPayload += "=" }
            Write-Verbose "Base64 encoded (padded) payoad:"
            Write-Verbose $tokenPayload
            #Convert to Byte array
            $tokenByteArray = [System.Convert]::FromBase64String($tokenPayload)
            #Convert to string array
            $tokenArray = [System.Text.Encoding]::ASCII.GetString($tokenByteArray)
            Write-Verbose "Decoded array in JSON format:"
            Write-Verbose $tokenArray
            #Convert from JSON to PSObject
            $tokobj = $tokenArray | ConvertFrom-Json
            Write-Verbose "Decoded Payload:"

            return $tokobj
        }

    }

    Process
    {

        If ($AccessToken)
        {
            $tokenRequest = Parse-JWTtoken -token $AccessToken
        }
        Else
        {
            try
            {
                If ((-not $ClientSecret) -and (-not $UseOnBehalfOfFlow))
                {
                    Write-Verbose "Pimp resource.."
                    $Resource = $Resource.Scheme + [System.Uri]::SchemeDelimiter + $Resource.Host
                }

                If ($TokenForResourceExists)
                {
                    [System.Boolean]$result = $false
                    #get existing tokens
                    $TokenCache = ([Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache]::DefaultShared).ReadItems()
                    If($TokenCache.Count -gt 0)
                    {
                        ForEach($Token in $TokenCache)
                        {
                            If($Token.Resource -eq $resource)
                            {
                                $result = $true
                                break
                            }
                        }
                    }
                }
                ElseIf ($UseImplicitFlow)
                {
                    Write-Verbose "AcquireToken using ImplicitFlow"
                    #get AuthCode
                    $AuthTokenParams = @{}
                    $AuthTokenParams.Add('Authority',$($Authority.Scheme + "://" +$Authority.Authority))
                    $AuthTokenParams.Add('Tenant',$Tenant)
                    $AuthTokenParams.Add('Response_Mode','fragment')
                    $AuthTokenParams.Add('Client_ID',$ClientId)
                    $AuthTokenParams.Add('Resource',$Resource)
                    $AuthTokenParams.Add('Response_Type','token')
                    $AuthTokenParams.Add('Redirect_Uri',$RedirectUri)
                    $AuthTokenParams.Add('Prompt',$AuthPrompt)
        
                    $tokenRequest = Get-AADAuth @AuthTokenParams
        
                    If ( -not $tokenRequest.Contains("#access_token"))
                    {
                        Write-Host -fore red "Couldn't get Token. Error:"
                        $($tokenRequest["error_description"])
                        break
                    }
                }
                Else
                {
                    # clear TokenCache
                    If ($ClearTokenCache)
                    {
                        ([Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache]::DefaultShared).Clear()
                    }

                    # define AuthContext
                    $AuthContext = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext($Authority)

                    # create UserIdentifier
                    If (-not [System.String]::IsNullOrEmpty($UserPrincipalName))
                    {
                        $UserID = [Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier]::new($UserPrincipalName,'RequiredDisplayableId')
                    }

                    Write-Verbose "FileVersion:$((Get-Item $ADALPath).VersionInfo.FileVersion)"
                    If ((Get-Module -Name  Microsoft.IdentityModel.Clients.ActiveDirectory).Version.Major -lt 3)
                    {
                        Write-Verbose "Looks like ADALv2"
                        # define Adal PromptBehavior
                        $AdalPromptBehavior = [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::($PromptBehavior)
                        [System.Boolean]$higherV2 = $false
                        [System.String]$Acquire = 'AcquireToken'
                        [System.String]$AcquireByAuthCode = 'AcquireTokenByAuthorizationCode'
                    }
                    Else
                    {
                        Write-Verbose "Looks like ADALv3"
                        # define Adal PromptBehavior
                        $ADALPromptBehavior = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters -ArgumentList $PromptBehavior
                        [System.Boolean]$higherV2 = $true
                        [System.String]$Acquire = 'AcquireTokenAsync'
                        [System.String]$AcquireByAuthCode = 'AcquireTokenByAuthorizationCodeAsync'
                    }

                    If ($UseAuthCodeFlow)
                    {
                        #get AuthCode
                        $AuthCodeParams = @{}
                        $AuthCodeParams.Add('Authority',$($Authority.Scheme + "://" +$Authority.Authority))
                        $AuthCodeParams.Add('Tenant',$Tenant)
                        $AuthCodeParams.Add('Response_Mode','query')
                        $AuthCodeParams.Add('Client_ID',$ClientId)
                        $AuthCodeParams.Add('Resource',$Resource)
                        $AuthCodeParams.Add('Response_Type','code')
                        $AuthCodeParams.Add('Redirect_Uri',$RedirectUri)
                        $AuthCodeParams.Add('Prompt',$AuthPrompt)

                        $AuthCode = Get-AADAuth @AuthCodeParams
                        Write-Verbose "AuthCode:$($AuthCode["code"])"

                        If ( -not "System.Collections.Hashtable" -eq $AuthCode.GetType().FullName)
                        {
                            Write-Host -fore red "Couldn't get AuthCode. Error:"
                            $AuthCode
                            break
                        }
                        Elseif ($AuthCode.ContainsKey("error"))
                        {
                            Write-Host -fore red "Couldn't get AuthCode. Error:"
                            $($AuthCode["error_description"])
                            break
                        }
                        Else
                        {
                            Write-Verbose "AuthCode:$($AuthCode["code"])"
                        }
                    }

                    # Acquire token without any flow for give UserID
                    If (($UserID -and -not $UseOnBehalfOfFlow) -and ($UserID -and -not $ClientSecret) -and ($UserID -and -not $Credential))
                    {
                        Write-Verbose -Message "AcquireToken for User..."
                        # Get AccessToken
                        $tokenRequest = $AuthContext.$($Acquire)($resource,$clientId,$redirectUri,$ADALPromptBehavior,$UserID)
                    }
                    # Acquire token for given PSCredential
                    ElseIf ($Credential)
                    {
                        Write-Verbose -Message "AcquireToken using PSCredential..."
                        # Create Credential
                        If ($higherV2)
                        {
                            $cred = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.UserPasswordCredential($Credential.UserName, $Credential.Password)
                            # Get AccessToken
                            $tokenRequest =  [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContextIntegratedAuthExtensions]::AcquireTokenAsync($AuthContext, $resource, $ClientId, $cred)
                        }
                        Else
                        {
                            $cred = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.UserCredential($Credential.UserName, $Credential.Password)
                            # Get AccessToken
                            $tokenRequest = $AuthContext.$($Acquire)($resource, $ClientId, $cred)
                        }
                        
                    }
                    # Acquire token with certificate as ClientCredential
                    ElseIf ($Certificate)
                    {
                        Write-Verbose -Message "AcquireToken using Certificate..."
                        #Create ClientAssertion from certificate
                        $ClientAssertionCertificate=[Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate]::new($ClientId,$Certificate)
                        # Get AccessToken
                        # Using AuthCodeFlow and ClientCertificate
                        If ($UseAuthCodeFlow)
                        {
                            $tokenRequest = $AuthContext.$AcquireByAuthCode($AuthCode["code"], $RedirectUri, $ClientAssertionCertificate)
                        }
                        # only with ClientCertificate
                        Else
                        {
                            $tokenRequest = $AuthContext.AcquireTokenAsync($resource, $ClientAssertionCertificate)
                        }
                    }
                    ElseIf ($ClientSecret)
                    {
                        Write-Verbose -Message "AcquireToken using ClientCredential..."
                        #create ClientCredential
                        $ClientCredential = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential($ClientId,$ClientSecret)
                        # Get AccessToken
                        # Using AuthCodeFlow and ClientSecret(Password)
                        If ($UseAuthCodeFlow)
                        {
                            Write-Verbose -Message "AcquireToken using ClientCredential and AuthCodeFlow..."
                            $tokenRequest = $AuthContext.$AcquireByAuthCode($AuthCode["code"], $RedirectUri, $ClientCredential)
                        }
                        ElseIF ($Silent)
                        {
                            Write-Verbose -Message "AcquireTokenSilentAsync using ClientCredential"
                            $tokenRequest = $AuthContext.AcquireTokenSilentAsync($Resource, $ClientCredential,$UserID)
                        }
                        # only with ClientSecret(Password)
                        Else
                        {
                            $tokenRequest = $AuthContext.AcquireTokenAsync($Resource, $ClientCredential)
                        }
                    }
                    Else
                    {
                        # Get AccessToken
                        If ($higherV2)
                        {
                            $tokenRequest = $AuthContext.$($Acquire)($resource,$clientId,$redirectUri,$AdalPromptBehavior)
                        }
                        Else
                        {
                            $tokenRequest = $AuthContext.$($Acquire)($resource,$clientId,$redirectUri,[Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::$AdalPromptBehavior)
                        }
                    }
                }

                # acquire additional AccessToken using On-Behalf-Of flow using previous retrieved token
                If ($UseOnBehalfOfFlow)
                {
                    # workaround as it seems to take a bit until the object was updated
                    While ($tokenRequest.Status -eq 'WaitingForActivation')
                    {
                        Write-Verbose "Status is still WaitingForActivation. Sleeping for a second..."
                        sleep -Seconds 1
                    }

                    If (-not $tokenRequest.IsFaulted)
                    {
                        Write-Verbose "Starting On-Behalf-Of flow...with previously received token"
                        # create UserAssertation
                        If ($UseImplicitFlow)
                        {
                            $token = $tokenRequest["#access_token"]
                        }
                        Else
                        {
                            # workaround as it seems to take a bit until the object was updated
                            While ($tokenRequest.Status -eq 'WaitingForActivation')
                            {
                                Write-Verbose "Status is still WaitingForActivation. Sleeping for a second..."
                                sleep -Seconds 1
                            }
                            #$tokenRequest.Result
                            #pause
                            If (-not [System.String]::IsNullOrEmpty($tokenRequest.Result))
                            {
                                $token = $tokenRequest.Result.AccessToken
                            }
                            Else
                            {
                                $token = $tokenRequest.AccessToken
                            }
                        }

                        $userAssertion = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.UserAssertion($token,'urn:ietf:params:oauth:grant-type:jwt-bearer',$UserID)

                        If ($ClientSecretOBO)
                        {
                            Write-Verbose -Message "AcquireToken using ClientSecret..."
                            # create Clientcredential for OBO app
                            $ClientCredentialOBO = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential($ClientIdOBO,$ClientSecretOBO)
                        }
                        ElseIf ($CertificateOBO)
                        {
                            Write-Verbose -Message "AcquireToken using ClientCertificate..."
                            # create Clientcredential for OBO app
                            $ClientCredentialOBO = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential($ClientIdOBO,$CertificateOBO)
                        }
                        Else
                        {
                            Write-Output "Cancle OBO request due to missing data (no ClientSecretOBO or CertificateOBO)..."
                            break
                        }

                        $OBOTokenRequest = $AuthContext.AcquireTokenAsync($ResourceOBO, $ClientCredentialOBO,$userAssertion)
                        $OBORequest = $OBOTokenRequest
                    }
                }
            }
            catch
            {
                #create object
                $returnValue = New-Object -TypeName PSObject
                #get all properties from last error
                $ErrorProperties =$Error[0] | Get-Member -MemberType Property
                #add existing properties to object
                foreach ($Property in $ErrorProperties)
                {
                    if ($Property.Name -eq 'InvocationInfo')
                    {
                        $returnValue | Add-Member -Type NoteProperty -Name 'InvocationInfo' -Value $($Error[0].InvocationInfo.PositionMessage)
                    }
                    else {
                        $returnValue | Add-Member -Type NoteProperty -Name $($Property.Name) -Value $($Error[0].$($Property.Name))
                    }
                }
                Write-Verbose "Return exception..."
                #return object
                $returnValue
                break
            }
        }

    }

    End
    {

        If ($TokenForResourceExists)
        {
            $result
        }
        Else
        {
            # workaround as it seems to take a bit until the object was updated
            While ($tokenRequest.Status -eq 'WaitingForActivation')
            {
                Write-Verbose "Status is still WaitingForActivation. Sleeping for a second..."
                sleep -Seconds 1
            }

            If (-not [System.String]::IsNullOrEmpty($tokenRequest))
            {
                If ($UseImplicitFlow)
                {
                    $tokenRequest
                    If ($ParseToken)
                    {
                        Write-Verbose "Parsing AccessToken from ImplicitFlow"
                        Parse-JWTtoken $tokenRequest["#access_token"] -Verbose:$false
                    }
                }
                ElseIf ($tokenRequest.IsFaulted)
                {
                    # return result, when failed
                    Write-Verbose "Something went wrong: returning result of request..."
                    $tokenRequest
                    break
                }
                Else
                {
                    # return token
                    Write-Verbose "Return AccessToken..."
                    If (-not [System.String]::IsNullOrEmpty($tokenRequest.Result))
                    {
                        $tokenRequest.Result
                        If ($ParseToken)
                        {
                            Write-Verbose "Parsing AccessToken from result"
                            Parse-JWTtoken $tokenRequest.Result.AccessToken -Verbose:$false
                        }
                    }
                    Else
                    {
                        $tokenRequest
                        If ($ParseToken)
                        {
                            Write-Verbose "Parsing AccessToken"
                            Parse-JWTtoken $tokenRequest.AccessToken -Verbose:$false
                        }
                    }

                }
                If ($UseOnBehalfOfFlow)
                {
                    # workaround as it seems to take a bit until the object was updated
                    While ($OBORequest.Status -eq 'WaitingForActivation')
                    {
                        Write-Verbose "Status is still WaitingForActivation for OBO. Sleeping for a second..."
                        sleep -Seconds 1
                    }
                    If ($OBORequest.IsFaulted)
                    {
                        # return result, when failed
                        Write-Verbose "Something went wrong for OBO flow: returning result of request..."
                        $OBORequest
                    }
                    Else
                    {
                        # return OBO token
                        Write-Verbose "Return OBOAccessToken..."
                        If (-not [System.String]::IsNullOrEmpty($OBORequest.Result))
                        {
                            $OBORequest.Result
                            If ($ParseToken)
                            {
                                Write-Verbose "Parsing OBOAccessToken"
                                Parse-JWTtoken $OBORequest.Result.AccessToken -Verbose:$false
                            }
                        }
                        Else
                        {
                            $OBORequest
                            If ($ParseToken)
                            {
                                Write-Verbose "Parsing OBOAccessToken"
                                Parse-JWTtoken $OBORequest.AccessToken -Verbose:$false
                            }
                        }
                    }
                }
            }
        }

    }
}