function Convertto-MailEnabledUser () {
    [cmdletbinding()]

    param (    
        [parameter(Mandatory = $true, Position=1)]
        [string]$Identity = '',
        [parameter(Mandatory = $true, Position=2)]
        [string]$ExternalEmailAddress =  ''
    )

    $Mailbox = Get-Mailbox $Identity ; 
    $ForeachEmailAddressParameters = @{
        InputObject = $Mailbox.EmailAddresses
        MemberName = ProxyAddressString
    }
    $EmailAddreses = ForEach-Object @ForeachEmailAddressParameters
    $EmailAddreses += "X500:$($Mailbox.LegacyExchangeDN)"
    
    DisableMailboxParameters = @{
        Identity = $Mailbox.Identity
        Confirm = $false
    }
    Disable-Mailbox @DisableMailboxParameters

    $EnableMEUParameters = @{
        Identity = $Mailbox.Identity
        PrimarySmtpAddress = $Mailbox.PrimarySmtpAddress
        $ExternalEmailAddress = $ExternalEmailAddress
        Confirm = $false
    }
    Enable-MailUser @EnableMEUParameters
    
    $SetMEUParameters = @{
        Identity = $Mailbox.Identity
        EmailAddressPolicyEnabled = $false
        EmailAddresses = $EmailAddreses
    }
    Set-MailUser @SetMEUParameters
}
