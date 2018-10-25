
function Set-O365Credentials {

    param (
        $UserName,
        $Password
    )

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
    $script:AdminCredential =  New-Object @AdminCredentialParameters

}

function Connect-Exchange {

    param (
        $UserName,
        $Password
    )

    Set-O365Credentials -UserName $UserName -Password $Password

    $ExchangeSessionParameters = [psobject] @{
        ConnectionURI = 'https://ps.outlook.com/powershell-LiveID/?proxymethod=RPS'
        ConfigurationName = 'Microsoft.Exchange'
        Authentication = 'Basic'
        AllowRedirection = $true    
        Credential = $AdminCredential
    }
    $ExchangeSession = New-PSSession @ExchangeSessionParameters
    
    $ImportSessionParameters =[psobject] @{
        Session = $ExchangeSession
        DisableNameChecking = $true
        CommandName = @(
            'Search-UnifiedAuditLog'
            'Get-MessageTrace'
            'Get-MessageTraceDetail'
            'Get-MessageTrackingReport'
            'Get-Mailbox'
            )
        AllowClobber = $true
    }
    Import-PSSession @ImportSessionParameters  | Out-Null  
}
