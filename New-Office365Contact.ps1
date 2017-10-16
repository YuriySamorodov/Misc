$csv = Import-Csv 'D:\Users\ysamorodov\Documents\My Received Files\Contacts.csv'
$csv = $csv | sort mail
$columnNames = $csv | Get-Member -MemberType NoteProperty | Select-Object Name
$ErrorActionPreference = 'SilentlyContinue'

for ( $i = 0 ; $i -lt $csv.Count ; $i++ ) {

#region Progress

    $progressParameters = @{
    
        Activity = 'Creating contacts...'
        Status = $csv[$i].displayName
        PercentComplete = $percent = ( $i / $csv.Count * 100 -as [int] )
        CurrentOperation = "$percent%"
    }

    Write-Progress @progressParameters

#endregion

#region Empty values check
    for ( $j = 0 ; $j -lt $columnNames.Count ; $j++ ) {
        if ( -not $csv[$i].$($columnNames[$j].Name) ) {
            $csv[$i].$($columnNames[$j].Name) = ' '
        }
    }
#endregion


    try {
        $ErrorActionPreference = 'Stop'
        $mailcontact = Get-Contact $csv[$i].mail
        #Write-Output "Exist"
    }   

    catch {
        #$ErrorActionPreference = 'SilentlyConinue'
        $NewMailContactParameters = [psobject] @{
            Name = if ( $csv[$i].mail.length -ge 64 ) { 
                        $csv[$i].mail.Substring( 0, 63 ) } 
                   else { $csv[$i].mail }
            DisplayName = $csv[$i].displayName
            FirstName = $csv[$i].givenName
            LastName = $csv[$i].sn
            ExternalEmailAddress = $csv[$i].mail               
        }
        New-MailContact @NewMailContactParameters | Tee-Object -Variable 'mailcontact'         
        #Write-Output "New"
    }

    finally {

        $SetContactParameters = [psobject] @{
            Identity = $mailcontact.Identity
            DisplayName = $csv[$i].displayName
            FirstName = $csv[$i].givenName
            LastName = $csv[$i].sn
            #WindowsEmailAddress = $csv[$i].mail
            Phone = $csv[$i].telephoneNumber
            MobilePhone = $csv[$i].mobile
            Fax = $csv[$i].facsimileTelephoneNumber
            Department = $csv[$i].department
            Title = $csv[$i].title
            Company = $csv[$i].company
            StreetAddress = $csv[$i].streetAddress
            City = $csv[$i].l
            StateOrProvince = $csv[$i].st 
            PostalCode = $csv[$i].postalCode
            #CountryOrRegion = $csv[$i].co
            Notes = $csv[$i].Info
     
        }
        Set-Contact @SetContactParameters
    
        if ( $csv[$i].c -notmatch " " ) {
            Set-Contact -Identity $mailcontact.Identity -CountryOrRegion $csv[$i].co
            Write-Output "Country code set"
        }
    }
}
