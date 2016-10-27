function New-Office365Session {

    param (

        [parameter(Mandatory = $false,Position=1)]
        [string]$UserName = '',
        [parameter(Mandatory = $false,Position=2)]
        [string]$Password =  ''

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


    $AdminCredential =  New-Object @AdminCredentialParameters

    $SessionParameters = [psobject] @{

        ConnectionURI = 'https://outlook.office365.com/powershell-liveid'
        ConfigurationName = 'Microsoft.Exchange'
        Authentication = 'Basic'
        AllowRedirection = $true    
        Credential = $AdminCredential

    }

    $session = New-PSSession @SessionParameters

    Import-PSSession $session -AllowClobber

    

}

