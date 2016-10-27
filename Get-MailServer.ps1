

for ( $i = 0 ; $i -lt $results.Count ; $i++ ) {

    $ProgressParameters = [psobject] @{
    
            Activity = 'Getting server responses'
            Status = $results[$i].Name 
            CurrentOperation = "$( ( $i / $results.Count * 100 ) -as [int] )%"
            PercentComplete = $i / $results.Count * 100
     
        }
    
            Write-Progress @ProgressParameters 


    $TelnetSessionParameters = [psobject] @{

        RemoteHost = $results[$i].NameExchange
        Port = '25'

    }

    New-TelnetSession @TelnetSessionParameters | Tee-Object -Variable 'Details'


    $DetailsParameters = [psobject] @{

        InputObject = $Details
        MemberType = 'ScriptProperty'
        Name = 'Domain'
        Value = { $results[$i].Name }
        
    }


    Add-Member @DetailsParameters
   
    $CsvParameters = [psobject] @{
    
        InputObject = $Details
        Path = 'DomainsDetails.csv'
        NoTypeInformation = $true
        Append = $true

    }
   
   Export-Csv @CsvParameters

}
