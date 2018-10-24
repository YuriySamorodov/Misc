function New-Office365Session {

    param (    
        [parameter(Mandatory = $true, Position=1)]
        [string]$UserName = '',
        [parameter(Mandatory = $true, Position=2)]
        [string]$Pass =  '',
        [parameter(Mandatory = $false, Position=3)]
        [ValidateSet('AzureAD',
                     'Exchange',
                     'Compliance',
                     'SharePoint',
                     'Skype',
                     'All')]
        [string]$Module =  'Exchange',
        [parameter(Mandatory = $false, Position=4)]
        [ValidateSet('RPS',
                     'PSWS')]
        [string]$ProxyMethod = 'RPS',
        [parameter(Mandatory = $false, Position=5)]
        [string]$Account =  '',
        [parameter(Mandatory = $false, Position=6)]
        [switch]$Prefix = $false
    )

    $URIExchangeOnline = "https://ps.outlook.com/powershell-LiveID/?proxymethod=$($ProxyMethod)"
    $URICompliance = "https://ps.compliance.protection.outlook.com/powershell-LiveID/?proxymethod=$($ProxyMethod)"

    function Set-O365Credentials {
    
        $SecurePasswordParameters = [psobject] @{
            String = $Pass
            AsPlainText = $true
            Force = $true
        }
        $SecurePassword = ConvertTo-SecureString @SecurePasswordParameters
    
        $AdminCredentialParameters = [psobject] @{
            TypeName = 'System.Management.Automation.PSCredential'
            ArgumentList = ( $UserName , $SecurePassword ) 
        }
        $script:AdminCredential =  New-Object @AdminCredentialParameters
    
    }

    Set-O365Credentials
    
    function Connect-Exchange {
    
        if ( $Account -notmatch "." ) {
            $ConnectionURI = $URIExchangeOnline
        }
        else {
            $ConnectionURI = $URIExchangeOnline + "/?DelegatedOrg=$Account.onmicrosoft.com" 
        }

    
        $ExchangeSessionParameters = [psobject] @{
            ConnectionURI = $ConnectionURI
            ConfigurationName = 'Microsoft.Exchange'
            Authentication = 'Basic'
            AllowRedirection = $true    
            Credential = $AdminCredential
            #SessionOption = $IEConfig
            #AllowClobber = $true
        }
        $ExchangeSession = New-PSSession @ExchangeSessionParameters
        if ( $Prefix -eq $true ) {
            Import-PSSession $ExchangeSession -AllowClobber -Prefix "EXO" -DisableNameChecking | Out-Null
            } else {
                Import-PSSession $ExchangeSession -AllowClobber -DisableNameChecking | Out-Null
            }

    }

    function Connect-SecurityAndCompliance {

        $ComplianceSessionParameters = [psobject] @{
            ConnectionURI = $URICompliance
            ConfigurationName = 'Microsoft.Exchange'
            Authentication = 'Basic'
            AllowRedirection = $true    
            Credential = $AdminCredential
            SessionOption = $IEConfig
            #AllowClobber = $true
        }
        $ComplianceSession = New-PSSession @ComplianceSessionParameters
        if ( $switch -eq $true ) {
            Import-PSSession $ComplianceSession -AllowClobber -Prefix "SC" | Out-Null
            } else {
                Import-PSSession $ComplianceSession -AllowClobber | Out-Null
            }
    }

    function Connect-All {
        Connect-Exchange
        Connect-SecurityAndCompliance    
    }
    
    switch ($Module) {
        'All' { Connect-All }
        'Exchange' { Connect-Exchange  }
    }

}
