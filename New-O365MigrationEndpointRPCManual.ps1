$RPCProxyServer = 'west.exch025.serverdata.net'
$ExchangeServer = 'west.exch025.serverdata.net'
$UserName = 'Migration@homefixcr.com'
$EmailAddress = 'tryan@homefixcr.com'
$Pass = 'Password1'

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
    $AdminCredential =  New-Object @AdminCredentialParameters


$NewMigrationEndPoint = @{
    Name = $RPCProxyServer
    ExchangeOutlookAnywhere = $true
    RPCProxyServer = $RPCProxyServer
    ExchangeServer = $ExchangeServer
    Credentials = $AdminCredential
    EmailAddress = 
}
New-MigrationEndpoint @NewMigrationEndPoint -Name -PublicFolder