function New-Office365Session {

    param (
        
        [parameter(Mandatory = $true, Position=1)]
        [string]$UserName = '',
        [parameter(Mandatory = $true, Position=2)]
        [string]$Password =  '',
        [parameter(Mandatory = $false, Position=3)]
        [string]$Account =  ''

    )


    if ( $Account -notmatch "." ) {
        
        $ConnectionURI = "https://ps.outlook.com/powershell-LiveID"

    }

    else {
        $ConnectionURI = "https://ps.outlook.com/powershell-LiveID?DelegatedOrg=$Account.onmicrosoft.com" 
    }

    $SecurePasswordParameters = [psobject] @{

        String = $Password
        AsPlainText = $true
        Force = $true

    }


    $SecurePassword = ConvertTo-SecureString @SecurePasswordParameters


    $AdminCredentialParameters = [psobject] @{

        TypeName = 'System.Management.Automation.PSCredential'
        ArgumentList = ( $UserName , $SecurePassword )
        
    }


    $AdminCredential =  New-Object @AdminCredentialParameters

    $ExchangeSessionParameters = [psobject] @{

        ConnectionURI = $ConnectionURI
        ConfigurationName = 'Microsoft.Exchange'
        Authentication = 'Basic'
        AllowRedirection = $true    
        Credential = $AdminCredential
        #AllowClobber = $true

    }

    $ExchangeSession = New-PSSession @ExchangeSessionParameters

    Import-PSSession $ExchangeSession -AllowClobber


    $ComplianceSessionParameters = [psobject] @{

        ConnectionURI = 'https://ps.compliance.protection.outlook.com/powershell-liveid/'
        ConfigurationName = 'Microsoft.Exchange'
        Authentication = 'Basic'
        AllowRedirection = $true    
        Credential = $AdminCredential
        #AllowClobber = $true

    }

    $ComplianceSession = New-PSSession @ComplianceSessionParameters

    Import-PSSession $ComplianceSession -AllowClobber
    

}
