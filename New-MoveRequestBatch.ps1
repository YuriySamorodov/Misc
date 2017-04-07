$Users =  Get-MsolUser | where { $_.isLicensed -eq $true }
$TargetDeliveryDomain = 'YCG01.mail.onmicrosoft.com'
$EndPoint = Get-MigrationEndpoint
$csv = $Users | select @{ n = 'EmailAddress' ; e = { $_.UserprincipalName } } | ConvertTo-Csv -NoTypeInformation
[byte[]]$headerBytes =  [System.Text.Encoding]::ASCII.GetBytes($($csv[0]))
[byte[]]$lineBreak = [System.Text.Encoding]::ASCII.GetBytes("`r`n")

for ( $i = 0 ; $i -lt $Users.Count ; $i++ ) {

    $MigrationBatchParameters = @{

        Name = $Users[$i].UserprincipalName
        SourceEndpoint = $EndPoint.Identity
        TargetDeliveryDomain = $TargetDeliveryDomain
        #Users = $Users[$i].UserprincipalName
        CSVData = $headerBytes + $lineBreak + [System.Text.Encoding]::ASCII.GetBytes($($Users[$i].UserprincipalName))
        BadItemLimit = 100
        NotificationEmails = ''
        AutoStart = $true
        AutoComplete = $false
        AllowIncrementalSyncs = $true
        DisallowExistingUsers = $true
        ErrorAction = "Stop"
        WhatIf = $false
        Verbose = $true
    }

    New-MigrationBatch @MigrationBatchParameters 
}
