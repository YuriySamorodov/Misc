function ConvertTo-MailEnabledUser () {
    #[cmdletbinding()]

    param (    
        [parameter(Mandatory = $true, Position=1)]
        [string]$Identity = '',
        [parameter(Mandatory = $true, Position=2)]
        [string]$ExternalEmailAddress =  ''
    )

    $ErrorPreference = 'Stop'
    try {
        $Mailbox = Get-Mailbox $Identity ; 
        $EmailAddresses = ($mailbox.EmailAddresses).ProxyAddressString
        $EmailAddresses += "X500:$($Mailbox.LegacyExchangeDN)"
        
        $DisableMailboxParameters = @{
            Identity = $Mailbox.Identity
            Confirm = $false
        }
        Disable-Mailbox @DisableMailboxParameters

        $EnableMEUParameters = @{
            Identity = $Mailbox.Identity
            PrimarySmtpAddress = $Mailbox.PrimarySmtpAddress
            ExternalEmailAddress = $ExternalEmailAddress
            Confirm = $false
        }
        Enable-MailUser @EnableMEUParameters
        
        $SetMEUParameters = @{
            Identity = $Mailbox.Identity
            EmailAddressPolicyEnabled = $false
            EmailAddresses = $EmailAddresses
        }
        Set-MailUser @SetMEUParameters
    }
    catch {
        Write-Output "No $identity found"
    }
    finally{
        Write-Output "$identity converted"
    }
}
