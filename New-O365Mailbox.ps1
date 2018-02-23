$csv = $csv

for ( $i = 2 ; $i -lt $csv.Count ; $i++ ) {
   #region WriteProgress
        $ProgressParameters = [psobject] @{
            Activity = 'Creating mailboxes...'
            Status = $csv[$i].UserPrincipalName 
            CurrentOperation = "$( ( $i / $csv.Count * 100 ) -as [int] )%"
            PercentComplete = $i / $csv.Count * 100
     }
       Write-Progress @ProgressParameters 
   #endregion

    $NewMailboxParams = @{
        DisplayName = $csv[$i].DisplayName
        FirstName = $csv[$i].FirstName
        LastName = $csv[$i].LastName
        Alias = $csv[$i].Alias
        Name = $csv[$i].Alias 
        MicrosoftOnlineServicesID = $csv[$i].UserPrincipalName
        PrimarySmtpAddress = $csv[$i].UserPrincipalName
        Password = $csv[$i].Password | ConvertTo-SecureString -AsPlainText -Force

    }
    
    $mailbox = New-Mailbox @NewMailboxParams
    Start-Sleep 5
    Set-Mailbox $mailbox.Identity -EmailAddresses @{ Add = $csv[$i].EmailAddresses -split ";" }
}
