$start = Get-Date

$resultSize = 5000
[datetime]$startDate = '07/22/2018 00:00:00'
[datetime]$endDate = '10/20/2018 00:00:00'
$currentStart = $null
$CurrentEnd = $null
$Interval = 15
$recordType = @(
    'SharePoint',
    'SharepointFileOperation',
    'SharePointSharingOperation'
)
$results = @() ;

function SearchUnifiedAuditLog {
    $global:SearchUnifiedAuditLogParameters = @{
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
    $currentStart = $currentEnd
    }
until ( $currentStart -eq $endDate )

$end = Get-Date
