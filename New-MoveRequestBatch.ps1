#$Users =  Get-MsolUser | where { $_.isLicensed -eq $true }
#$Users =  Get-MsolUser | where { $_.UserprincipalName -match "hojlaw.com" }
$Users = import-csv 'D:\Users\ysamorodov\OneDrive\Intermedia\Downloads\59738+Hackleman+Users.csv'
$TargetDeliveryDomain = 'Hackleman.mail.onmicrosoft.com'
$EndPoint = Get-MigrationEndpoint
[byte[]]$headerBytes =  [System.Text.Encoding]::ASCII.GetBytes("EmailAddress")
[byte[]]$lineBreak = [System.Text.Encoding]::ASCII.GetBytes("`r`n")

for ( $i = 0 ; $i -lt $Users.Count ; $i++ ) {

    $MigrationBatchParameters = @{

        Name = $Users[$i].UserprincipalName
        SourceEndpoint = $EndPoint.Identity
        TargetDeliveryDomain = $TargetDeliveryDomain
        #Users = $Users[$i].UserprincipalName
        CSVData = $headerBytes + $lineBreak + [System.Text.Encoding]::ASCII.GetBytes($($Users[$i].UserprincipalName))
        BadItemLimit = 100
        LargeItemLimit = 100
        NotificationEmails = ''
        AutoStart = $false
        AutoComplete = $false
        AllowIncrementalSyncs = $true
        DisallowExistingUsers = $false
        ErrorAction = "Stop"
        WhatIf = $false
        Verbose = $true
    }

    New-MigrationBatch @MigrationBatchParameters 
}
