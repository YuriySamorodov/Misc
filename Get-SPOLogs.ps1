$searchGuid = New-Guid
$resultSize = 5000
[datetime]$startDate = '10/09/2018'
[datetime]$endDate = '10/13/2018'
$recordType = @(
    'SharePoint',
    'SharepointFileOperation',
    'SharePointSharingOperation'
)
$auditData = @() ;
function SearchUnifiedAuditLog {

    $SearchUnifiedAuditLogParameters = @{
        SessionCommand = 'ReturnLargeSet'
        SessionId = $searchGuid
        StartDate = $startDate
        EndDate = $endDate
        RecordType = $recordType
        ResultSize = $resultSize
    }
    Search-UnifiedAuditLog @SearchUnifiedAuditLogParameters ;
}

$auditData = SearchUnifiedAuditLog
Start-Sleep -Milliseconds 500

do {
Write-Host "$($auditData[-1].ResultIndex)"
$auditData += SearchUnifiedAuditLog
Start-Sleep -Milliseconds 500
}
while ( $auditData.Count % $resultSize -eq 0 ) ;

