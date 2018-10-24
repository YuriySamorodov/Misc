param (

    [parameter(Mandatory=$false,Position=1)]
    [datetime]$startDate = ( Get-Date ).AddDays(-2).Date.AddMinutes(-15),

    [parameter(Mandatory=$false,Position=2)]
    [datetime]$endDate = ( Get-Date ).AddDays(-2).Date,
    
    [parameter(Mandatory=$false,Position=3)]
    $LogPath = 'C:\Users\yury.samorodov\Downloads\SPOLogs\',

    [parameter(Mandatory=$false,Position=4)]
    [int]$resultSize = 5000
 )

$results = @() ;

function SearchUnifiedAuditLog {
    $SearchUnifiedAuditLogParameters = @{
        SessionCommand = 'ReturnLargeSet'
        SessionId = $SessionId
        StartDate = $CurrentStart
        EndDate = $CurrentEnd
        #RecordType = [string]($recordType -join ',')
        ResultSize = $ResultSize
    }
    Search-UnifiedAuditLog @SearchUnifiedAuditLogParameters ;
}


#$auditData = SearchUnifiedAuditLog
#Start-Sleep -Milliseconds 500
#Write-Host "$($auditData[-1].ResultCount)"
do{
    $auditData = @()
    $SessionId = New-Guid
    do {

        if ( $currentStart -eq $null ) {
            $currentStart = $startDate
        }
        $CurrentEnd = $currentStart.AddMinutes($Interval)
        $auditData += SearchUnifiedAuditLog
        Write-Host "$($CurrentStart): $($auditData[-1].ResultIndex)"
        Start-Sleep -Milliseconds 500
        }
        while ( $auditData.Count % $resultSize -eq 0 ) 
    $results += $auditData
    
    #Export every hour worth of data
    if ( $CurrentEnd.TimeOfDay.TotalMinutes % 60 -eq 0 ) {
        $SPOLogs = $results | Where-Object { $_.recordType -match "OneDrive|SharePoint" }
        $SPOLogs = $SPOLogs | Select-Object -ExpandProperty AuditData
        $SPOLogs = $SPOLogs | ConvertFrom-Json
        $LogName = "$($LogPath)\$($CurrentEnd.ToString("yyyyMMddHHmm"))-SharepointOnlineLogs.log"
        $SPOLogs | export-csv -NoTypeInformation $LogName -Append
        $results = $null
        $SPOLogs = $null        
    }
    $currentStart = $currentEnd
    }
until ( $currentStart -eq $endDate )
