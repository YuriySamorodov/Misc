$csv = $csv ;

foreach ( $row in $csv ) {
       
    $RemoveDuplicatesParameters = @{
        Mailbox = $row.PrimarySmtpAddress
        Server = 'outlook.office365.com'
        Credentials = $credentials
        Mode = 'Full'
        MailboxOnly = $true
        Impersonation = $true
        #Type = 'Calendar'
        #Nosize = $true
        Force = $true
   }
   & .\Remove-DuplicateItemsUnblocked.ps1 @RemoveDuplicatesParameters -Type Calendar -NoSize ;
   & .\Remove-DuplicateItemsUnblocked.ps1 @RemoveDuplicatesParameters -Type Contacts -NoSize ;
   #& .\Remove-DuplicateItemsUnblocked.ps1 @RemoveDuplicatesParameters -Type Mail
}

foreach ( $row in $csv ) {
       
    $RemoveDuplicatesParameters = @{
        Mailbox = $row.PrimarySmtpAddress
        Server = 'outlook.office365.com'
        Credentials = $credentials
        Mode = 'Full'
        MailboxOnly = $true
        Impersonation = $true
        #Type = 'Calendar'
        #Nosize = $true
        Force = $true
   }
   #& .\Remove-DuplicateItemsUnblocked.ps1 @RemoveDuplicatesParameters -Type Calendar -NoSize ;
   #& .\Remove-DuplicateItemsUnblocked.ps1 @RemoveDuplicatesParameters -Type Contacts -NoSize ;
   & .\Remove-DuplicateItemsUnblocked.ps1 @RemoveDuplicatesParameters -Type Mail
}
