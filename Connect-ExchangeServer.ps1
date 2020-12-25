function ConnectExchangeOnpremises () {

    param (
        $ComputerName = 'spbxcas01',
        $Authentication = 'NegotiateWithImplicitCredential'
    )

    function CreatePSSession {
        
        $OptionParameters = @{
            SkipCACheck = $true
            SkipCNCheck = $true
            SkipRevocationCheck = $true
        }
        $option = New-PSSessionOption @OptionParameters

        $Parts = @(
            'https:/'
            "$ComputerName"
            'PowerShell'
            '?SerializationLevel=Full'
        )
    
        $ConnectionURI = $Parts -join "/"

        $sessionParameters = @{
            Name = "$ComputerName"
            ConnectionUri = "$ConnectionURI"
            ConfigurationName = 'Microsoft.Exchange'
            EnableNetworkAccess = $true 
            AllowRedirection = $true
            SessionOption = $option
            Authentication = $Authentication
        }

        $script:session = New-PSSession @sessionParameters
        }

    function ImportPSSession {

        $ImportSessionParameters = @{
            Session = $script:session
            AllowClobber = $true
            DisableNameChecking = $true
        }
        Import-PSSession @ImportSessionParameters | Out-Null
    }

    $ErrorActionPreference = 'Stop'

    try {
        $PSSessions = Get-PSSession
        $PSSessions = $PSSessions | Where-Object { $_.ComputerName -eq $ComputerName }
        $PSSessions = $PSSessions | Where-Object { $_.State -eq 'Opened' }
        $PSSessions = $PSSessions | Where-Object { $_.ConfigurationName -eq 'Microsoft.Exchange' }
        $session = $PSessions[0]
    } catch {
        CreatePSSession
    } finally {
        ImportPSSession
    }

}