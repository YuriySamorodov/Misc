foreach ( $row in $csv ) { 
    $mailbox = Get-Mailbox $row.IntermediaEmail ; 
    $( $mailbox.EmailAddresses | ForEach-Object { $_.ProxyAddressString } ) + "X500:$($mailbox.LegacyExchangeDN)"; 
    Disable-Mailbox -Identity $mailbox.Identity -Confirm:$false ; 
    Enable-MailUser -Identity $mailbox.Identity -PrimarySmtpAddress $mailbox.PrimarySmtpAddress -ExternalEmailAddress $row.OnMicrosoftEmailAddress -Confirm:$false ; 
    Set-MailUser -Identity $mailbox.Identity -EmailAddressPolicyEnabled $false -EmailAddresses $EmailAddreses 
}
